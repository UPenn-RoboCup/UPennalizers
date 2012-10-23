require('unix');
require('shm');

local cwd = unix.getcwd();
package.path = cwd.."/../Util/?.lua;"..package.path; --For Transform
package.path = cwd.."/../Vision/?.lua;"..package.path; --For vcm

dcm = require('OPCommManager');
print('Starting device comm manager...');
dcm.entry()

-- I don't think this should be here for shm management?
-- Shouldn't these just be dcm.something acces funcitons?
sensorShm = shm.open('dcmSensor');
actuatorShm = shm.open('dcmActuator');

require('vcm') --Shared memory is created here, and ready for access

print('Running controller');
loop = true;
count = 0;
t0 = unix.time();

--for testing
dcm.actuator.readType[1]=0;--Read Head only
dcm.actuator.battTest[1]=0; --Battery test disable

fpsdesired=100; --100 HZ cap on refresh rate
ncount=200;

t_timing=unix.time();
while (loop) do
   count = count + 1;
   local t1 = unix.time();
   local tPassed=math.max(math.min(t1-t_timing,0.010),0); --Check for timer overflow
   readtype= actuatorShm:get('readType') ;
   if readtype==0 then ncount=200;
     else ncount = 40;
   end 

   if 1/fpsdesired > tPassed then
--      unix.usleep(1E6*(1/fpsdesired - tPassed));
   end
   t_timing=t1;
   dcm.update()

--   pos=vector.new(sensorShm:get('position'))*180/math.pi;
--   print(string.format("Position:\n Head: %f %f",pos[1],pos[2]));


   if (count % ncount == 0) then
      os.execute("clear")
      local iangle=vector.new(sensorShm:get('imuAngle'))*180/math.pi;
      print(
	string.format("IMU Acc: %.2f %.2f %.2f ",unpack(sensorShm:get('imuAcc')))..
	string.format("Gyr: %.1f %.1f %.1f ",unpack(sensorShm:get('imuGyr')))..
	string.format("Angle: %.1f %.1f %.1f ",unpack(iangle))..
	string.format("/ %d FPS [%d]", ncount/(t1-t0), actuatorShm:get('readType')  )
	)
      t0 = t1;

      print(string.format("Button: %d %d",  unpack(sensorShm:get('button'))));      

      print(string.format("Position:\n Head: %.1f %.1f\n Larm: %.1f %.1f %.1f\n Lleg: %.1f %.1f %.1f %.1f %.1f %.1f\n Rleg: %.1f %.1f %.1f %.1f %.1f %.1f\n Rarm: %.1f %.1f %.1f\n",
			  unpack(vector.new(sensorShm:get('position'))*180/math.pi)
		    ));

      print(string.format("Battery: %.1f V\n", sensorShm:get('battery')/10));

--[[
      print(string.format("Command:\n %f %f\n %f %f %f\n %f %f %f %f %f %f\n %f %f %f %f %f %f\n %f %f %f\n",
			  unpack(vector.new(actuatorShm:get('command'))*180/math.pi)
		    ));
      print(string.format("Hardness:\n %f %f\n %f %f %f\n %f %f %f %f %f %f\n %f %f %f %f %f %f\n %f %f %f\n",
			  unpack(actuatorShm:get('hardness'))
		    ));
--]]
   end
end

dcm.exit()
