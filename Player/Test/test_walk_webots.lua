cwd = cwd or os.getenv('PWD')
package.path = cwd.."/?.lua;"..package.path;
require('init')

require('Config');
smindex = 0;
package.path = cwd..'/BodyFSM/'..Config.fsm.body[smindex+1]..'/?.lua;'..package.path;
package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;

require('shm')
require('Body')
require('vector')
require('getch')
require('Motion');
require('walk');
require('dive');
require('Speak')
require('util')
darwin = false;
webots = false;

require('grip')

-- Enable OP specific 
if(Config.platform.name == 'OP') then
  darwin = true;
end

-- Enable Webots specific
if (string.find(Config.platform.name,'Webots')) then
  webots = true;
end

getch.enableblock(1);
--unix.usleep(1E6*1.0);


-- initialize state machines
Motion.entry();
--Motion.event("standup");

Body.set_head_hardness({0.4,0.4});

controller.wb_robot_keyboard_enable(100);
-- main loop
count = 0;
vcmcount=0;
local t0=Body.get_time();
local last_update_time=t0;
local headangle=vector.new({0,10*math.pi/180});
local headsm_running=0;
local bodysm_running=0;
local last_vision_upfasfdsaasfgate_time=t0;
targetvel=vector.zeros(3);
t_update=2;

Motion.fall_check=0;
--Motion.fall_check=1;
broadcast_enable=0;
ballcount,visioncount,imagecount=0,0,0;
hires_broadcast=0;

cameraparamcount=1;
broadcast_count=0;
buttontime=0;

paramsets={
--Name default div min
	{"bodyHeight",Config.walk.bodyHeight,0.005, 0.25},
	{"footY",Config.walk.footY,0.005, 			0.04},
	{"supportX",Config.walk.supportX,0.005, 	0},
	{"tStep",Config.walk.tStep,0.005,			0.24},
	{"supportY",Config.walk.supportY,0.005,		0},
	{"tZmp",Config.walk.tZmp,0.0025,			0.15},
	{"stepHeight",Config.walk.stepHeight,0.00125,	0.01},
	{"phSingleRatio",Config.walk.phSingleRatio,0.01,	0.01},
	{"hardnessSupport",Config.walk.hardnessSupport,0.05, 0.3},
	{"hardnessSwing",Config.walk.hardnessSwing,0.05, 	0.3},
	{"hipRollCompensation",Config.walk.hipRollCompensation,0.005, 0},
	{"zmp_type",Config.walk.zmp_type,1, 0},
}

currentparam = 1

--Hack for saffire
Body.set_lleg_command({0,0,0,0,0,0,0,0,0,0,0,0})


function process_keyinput()
  local str = controller.wb_robot_keyboard_get_key();
  if str>0 then
    byte = str;
	-- Webots only return captal letter number
	if byte>=65 and byte<=90 then
		byte = byte + 32;
	end

  -- Walk velocity setting
	if byte==string.byte("i") then	targetvel[1]=targetvel[1]+0.02;
	elseif byte==string.byte("j") then	targetvel[3]=targetvel[3]+0.1;
	elseif byte==string.byte("k") then	targetvel[1],targetvel[2],targetvel[3]=0,0,0;
	elseif byte==string.byte("l") then	targetvel[3]=targetvel[3]-0.1;
	elseif byte==string.byte(",") then	targetvel[1]=targetvel[1]-0.02;
	elseif byte==string.byte("h") then	targetvel[2]=targetvel[2]+0.02;
	elseif byte==string.byte(";") then	targetvel[2]=targetvel[2]-0.02;

	elseif byte==string.byte("q") then	
	  currentparam = (currentparam+(#paramsets-2)) %(#paramsets)+1
	print(currentparam)
	  print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))
	elseif byte==string.byte("w") then			
		print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))
	elseif byte==string.byte("e") then			
		currentparam = currentparam %(#paramsets)+1
	  print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))
	elseif byte==string.byte("[") then	
		Config.walk[paramsets[currentparam][1]]=
		math.max(paramsets[currentparam][4],
			Config.walk[paramsets[currentparam][1]]-
					paramsets[currentparam][3]
			)	
		print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))

	elseif byte==string.byte("]") then	
		Config.walk[paramsets[currentparam][1]]=
		math.max(paramsets[currentparam][4],
			Config.walk[paramsets[currentparam][1]]+
					paramsets[currentparam][3]
			)	
		print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))

	elseif byte==string.byte("1") then	
		kick.set_kick("kickForwardLeft");
		Motion.event("kick");

	elseif byte==string.byte("2") then	
		kick.set_kick("kickForwardRight");
		Motion.event("kick");

	elseif byte==string.byte("3") then
           walk.doStepKickLeft();
	elseif byte==string.byte("4") then
           walk.doStepKickRight();

    elseif byte==string.byte("5") then
            walk.doWalkKickLeft();
    elseif byte==string.byte("6") then
            walk.doWalkKickRight();

	elseif byte==string.byte("7") then	Motion.event("sit");
	elseif byte==string.byte("8") then	
		if walk.active then walk.stop() end
		Motion.event("standup")
	elseif byte==string.byte("9") then	
		Motion.event("walk")
		walk.start()
	end
	walk.set_velocity(unpack(targetvel));
--print(unpack(targetvel))
    print("Command velocity:",walk.velCommand[1],walk.velCommand[2],walk.velCommand[3]*180/math.pi)

  end

end

function update()
  Body.set_syncread_enable(0); --read from only head servos
   
  -- Update the relevant engines
  Body.update();

  Motion.update();
  
  -- Get a keypress
  process_keyinput();



--  mcm.set_motion_fall_check(0)--disable fall check

end

local tDelay=0.002*1E6;
local ncount = 100;
local tUpdate = Body.get_time();
while 1 do
  count = count + 1;
  
  update();
  io.stdout:flush();

  -- Show FPS
--[[
  local t = Body.get_time();
  if(count==ncount) then
    local fps = ncount/(t-tUpdate);
    tUpdate = t;
    count = 1;
--    print(fps.." FPS")
  end
--]]
  --Wait until dcm has done reading/writing
--  unix.usleep(tDelay);

end

