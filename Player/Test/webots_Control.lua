module(... or '', package.seeall)

webots = false;
darwin = false;

-- Get Platform for package path
cwd = os.getenv('PWD');
local platform = os.getenv('PLATFORM') or ''; 
if (string.find(platform,'webots')) then cwd = cwd .. '/Player';
end

computer = os.getenv('COMPUTER') or '';
if (string.find(computer, 'Darwin')) then
  -- MacOS X uses .dylib:
  package.cpath = cwd..'/Lib/?.dylib;'..package.cpath;
else
  package.cpath = cwd..'/Lib/?.so;'..package.cpath;
end

package.path = cwd..'/?.lua;'..package.path;
package.path = cwd..'/Util/?.lua;'..package.path;
package.path = cwd..'/Config/?.lua;'..package.path;
package.path = cwd..'/Lib/?.lua;'..package.path;
package.path = cwd..'/Dev/?.lua;'..package.path;
package.path = cwd..'/Motion/?.lua;'..package.path;
package.path = cwd..'/Motion/keyframes/?.lua;'..package.path;
package.path = cwd..'/Vision/?.lua;'..package.path;
package.path = cwd..'/World/?.lua;'..package.path;

require('Config')
require('shm')
require('vector')
require('controller');
require('Speak')
require('Body')
require('Motion')
require('unix')
require('cognition')
Motion.entry();

--{x,y,z}
targetvel=vector.new({0,0,0});
--{yaw,pitch}
headangle=vector.new({0,0});

if( Config.platform.name=='OP' ) then
  darwin = true;
end

if(string.find(Config.platform.name,"Webots")) then
	webots = true;
end

--Adding head movement && vision...--
Body.set_head_hardness({0.4,0.4});

init = false;
calibrating = false;
ready = false;
if( webots or darwin) then
  ready = true;
end

smindex = 0;
initToggle = true;

--Check keyboard for input 42 ms
controller.wb_robot_keyboard_enable(200);

-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();

print("Welcome to the webots controller! To use this, please click on the robot and then press the keys listed below to control.");
print(" Key commands \n 7:sit down 8:stand up 9:walk\n i/j/l/,/h/; :control walk velocity\n k : walk in place\n [, ', / :Reverse x, y, / directions\n 1/2/ :kick\n v :Turn on vision");

function update()
  count = count + 1;
  str = controller.wb_robot_keyboard_get_key();  --Gets keyboard input
  str = string.char(str);  --Converts keyboard input into a character
  if (not init)  then
    if (calibrating) then
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        calibrating = false;
        ready = true;
      end
      
    elseif (ready) then
      init = true;
    else
      if (count % 20 == 0) then
        if (Body.get_change_state() == 1) then
          Speak.talk('Calibrating');
          calibrating = true;
        elseif (Body.get_change_role() == 1) then
          smindex = (smindex + 1) % #Config.fsm.body;
        end
      end

      -- toggle state indicator
      if (count % 100 == 0) then
        initToggle = not initToggle;
        if (initToggle) then
          Body.set_indicator_state({1,1,1}); 
        else
          Body.set_indicator_state({0,0,0});
        end
      end
    end

  else
     --is str not empty (thanks Ashleigh)?
     if #str>0 then
	local byte=string.byte(str,1);
		if byte==string.byte("I") then		
			targetvel[1]=targetvel[1]+0.01;
		elseif byte==string.byte("J") then	
			targetvel[3]=targetvel[3]+0.1;
		elseif byte==string.byte("K") then	
			targetvel[1],targetvel[2],targetvel[3]=0,0,0;
		elseif byte==string.byte("L") then	
			targetvel[3]=targetvel[3]-0.1;
		elseif byte==string.byte(",") then	
			targetvel[1]=targetvel[1]-0.01;
		elseif byte==string.byte("H") then	
			targetvel[2]=targetvel[2]+0.01;
		elseif byte==string.byte(";") then	
			targetvel[2]=targetvel[2]-0.01;
		elseif byte==string.byte("[") then
			targetvel[1]=-targetvel[1];
		elseif byte==string.byte("'") then
			targetvel[2]=-targetvel[2];
		elseif byte==string.byte("/") then
			targetvel[3]=-targetvel[3];

                elseif byte==string.byte("1") then	
			kick.set_kick("kickForwardLeft");
			Motion.event("kick");
		elseif byte==string.byte("2") then	
			kick.set_kick("kickForwardRight");
			Motion.event("kick");

		--Move the head around--
		elseif byte==string.byte("W") then
			headangle[2]=headangle[2]-5*math.pi/180;
		elseif byte==string.byte("A") then	
			headangle[1]=headangle[1]+5*math.pi/180;
		elseif byte==string.byte("S") then	
			headangle[1],headangle[2]=0,0;
		elseif byte==string.byte("D") then	
			headangle[1]=headangle[1]-5*math.pi/180;
		elseif byte==string.byte("X") then	
			headangle[2]=headangle[2]+5*math.pi/180;


    elseif byte==string.byte("6") then Motion.event("dive");
    elseif byte==string.byte("7") then	Motion.event("sit");
		elseif byte==string.byte("8") then	
			walk.stop();
			Motion.event("standup");
		elseif byte==string.byte("9") then	
			Motion.event("walk");
			walk.start();

		elseif byte==string.byte("v") then
			vision=true;
                end
	      end
    if count%30==0 then
    	print(string.format("\n Walk Velocity: (%.2f, %.2f, %.2f)",
        	unpack(targetvel)));
	print(string.format("Head angle: %d, %d",
			headangle[1]*180/math.pi,
			headangle[2]*180/math.pi));

    end 
    
    --update the velocity
    walk.set_velocity(unpack(targetvel));
    
    
    Body.set_head_hardness(0.2);
    Body.set_head_command(headangle);
    Motion.update();
    Body.update();

  end

  local dcount = 50;
  -- check if the last update completed without errors
  lcount = lcount + 1;
  if (count ~= lcount) then
     Speak.talk('missed cycle');
    lcount = count;
  end
end

-- if using Webots simulator just run update
if (webots)then
  cognition.entry();

  -- set game state to Playing

  while (true) do
    -- update cognitive process
    cognition.update();
    -- update motion process
    update();
    io.stdout:flush();
  end

end

print('Running: '..Config.platform.name)
if( darwin ) then
  local tDelay = 0.005 * 1E6; -- Loop every 5ms
  while 1 do
    update();
    unix.usleep(tDelay);
  end
end
