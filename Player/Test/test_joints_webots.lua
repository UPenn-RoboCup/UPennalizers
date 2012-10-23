module(... or "", package.seeall)

-- Get Platform for package path
cwd = os.getenv('PWD');
local platform = os.getenv('PLATFORM') or '';
if (string.find(platform,'webots')) then cwd = cwd .. '/Player';
end

-- Get Computer for Lib suffix
local computer = os.getenv('COMPUTER') or '';
if (string.find(computer, 'Darwin')) then
  -- MacOS X uses .dylib:
  package.cpath = cwd .. '/Lib/?.dylib;' .. package.cpath;
else
  package.cpath = cwd .. '/Lib/?.so;' .. package.cpath;
end

package.path = cwd .. '/?.lua;' .. package.path;
package.path = cwd .. '/Util/?.lua;' .. package.path;
package.path = cwd .. '/Config/?.lua;' .. package.path;
package.path = cwd .. '/Lib/?.lua;' .. package.path;
package.path = cwd .. '/Dev/?.lua;' .. package.path;
package.path = cwd .. '/Motion/?.lua;' .. package.path;
package.path = cwd .. '/Motion/keyframes/?.lua;' .. package.path;
package.path = cwd .. '/Vision/?.lua;' .. package.path;
package.path = cwd .. '/World/?.lua;' .. package.path;

require('Config');
smindex = 0;

package.path = cwd..'/BodyFSM/'..Config.fsm.body[smindex+1]..'/?.lua;'..package.path;
package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
package.path = cwd..'/GameFSM/'..Config.fsm.game..'/?.lua;'..package.path;

require('shm')
require('Body')
require('vector')
require('Kinematics')

BodyFSM=require('BodyFSM');
HeadFSM=require('HeadFSM');
require('getch')
require('Motion');
require('walk');
require('Speak')
require('util')
darwin = false;
webots = false;

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
Body.set_head_hardness({0.4,0.4});

tx=0;ty=0;tz=0.8;ta=0;
local l_foot_pos = {0,0.10,0,0,0,0}
local r_foot_pos = {0,-0.10,0,0,0,0}
torso_pos = {tx,ty,tz,0,0,ta};
local q_legs = Kinematics.inverse_legs(l_foot_pos, r_foot_pos, torso_pos)
Body.set_lleg_command(q_legs)
Body.set_body_hardness(1);

llegpos=Body.get_lleg_position();


--[[
dpLLeg = Kinematics.lleg_torso(Body.get_lleg_position());
dpRLeg = Kinematics.rleg_torso(Body.get_rleg_position());
print("Left leg kinematics:",unpack(dpLLeg));
--]]


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

--Motion.fall_check=0;
--Motion.fall_check=1;
broadcast_enable=0;
ballcount,visioncount,imagecount=0,0,0;
hires_broadcast=0;

cameraparamcount=1;
broadcast_count=0;
buttontime=0;



langle=vector.new({0,0,0,0,0,0, 0,0,0,0,0,0});
jointToCheck =1;
jointNames={"HipYaw","HipRoll","HipPitch","KneePitch","AnklePitch","AnkleRoll"};


function process_keyinput()

  local str = controller.wb_robot_keyboard_get_key();
  if str>0 then
    byte = str;
	-- Webots only return captal letter number
	if byte>=65 and byte<=90 then
		byte = byte + 32;
	end
--[[
	if byte==string.byte("i") then	
		langle[jointToCheck]=langle[jointToCheck]+5;
	elseif byte==string.byte("j") then
		langle[jointToCheck+6]=langle[jointToCheck+6]-5;
	elseif byte==string.byte("k") then	
		langle[jointToCheck]=0;
		langle[jointToCheck+6]=0;
	elseif byte==string.byte("l") then	
		langle[jointToCheck+6]=langle[jointToCheck+6]+5;
	elseif byte==string.byte(",") then	
		langle[jointToCheck]=langle[jointToCheck]-5;
	elseif byte==string.byte("1") then	
		jointToCheck=jointToCheck-1;	
		if jointToCheck==0 then jointToCheck=6;end	
	elseif byte==string.byte("2") then	
		jointToCheck=jointToCheck%6+1;	
	end
	Body.set_actuator_command(math.pi/180*langle);
	print(string.format("%s : L %d R %d",jointNames[jointToCheck],
		langle[jointToCheck],langle[jointToCheck+6]));
--]]

	if byte==string.byte("i") then	
	    tx=tx+0.01;
	elseif byte==string.byte("j") then
	    ty=ty+0.01;
	elseif byte==string.byte("k") then	
	    tx=0;ty=0;
	elseif byte==string.byte("h") then
	    ta=ta+0.03;
	elseif byte==string.byte(";") then	
	    ta=ta-0.03;
	elseif byte==string.byte("l") then	
	    ty=ty-0.01;
	elseif byte==string.byte(",") then	
	    tx=tx-0.01;
	elseif byte==string.byte("u") then	
	    tz=tz+0.005;
	elseif byte==string.byte("m") then	
	    tz=tz-0.005;
	end
	torso_pos = {tx,ty,tz,0,0,ta};
	local q_legs = Kinematics.inverse_legs(l_foot_pos, r_foot_pos, torso_pos)
	Body.set_lleg_command(q_legs)

  end







end

function update()
  Body.set_syncread_enable(0); --read from only head servos
   
  -- Update the relevant engines
  Body.update();
  
  -- Get a keypress
  process_keyinput();
end

local tDelay=0.002*1E6;
local ncount = 100;
local tUpdate = Body.get_time();
while 1 do
  count = count + 1;
  
  update();

  -- Show FPS
  local t = Body.get_time();
  if(count==ncount) then
    local fps = ncount/(t-tUpdate);
    tUpdate = t;
    count = 1;
--    print(fps.." FPS")
  end

  --Wait until dcm has done reading/writing
--  unix.usleep(tDelay);

end

