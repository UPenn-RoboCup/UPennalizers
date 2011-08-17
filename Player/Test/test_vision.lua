module(... or "", package.seeall)

require('unix')
webots = false;
darwin = false;

-- mv up to Player directory
unix.chdir('..');

local cwd = unix.getcwd();
-- the webots sim is run from the WebotsController dir (not Player)
if string.find(cwd, "WebotsController") then
  webots = true;
  cwd = cwd.."/Player"
  package.path = cwd.."/?.lua;"..package.path;
end

computer = os.getenv('COMPUTER') or "";
if (string.find(computer, "Darwin")) then
   -- MacOS X uses .dylib:
   package.cpath = cwd.."/Lib/?.dylib;"..package.cpath;
else
   package.cpath = cwd.."/Lib/?.so;"..package.cpath;
end

package.path = cwd.."/Util/?.lua;"..package.path;
package.path = cwd.."/Config/?.lua;"..package.path;
package.path = cwd.."/Lib/?.lua;"..package.path;
package.path = cwd.."/Dev/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path;
package.path = cwd.."/Motion/keyframes/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;

require('Config');
smindex = 0;

package.path = cwd..'/BodyFSM/'..Config.fsm.body[smindex+1]..'/?.lua;'..package.path;
package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
package.path = cwd..'/GameFSM/'..Config.fsm.game..'/?.lua;'..package.path;

require('shm')
require('Body')
require('vector')

BodyFSM=require('BodyFSM');
HeadFSM=require('HeadFSM');
require('getch')
require('vcm'); 
require('Motion');
require('walk');
--require('HeadTransform')
require('Broadcast')
require('Comm')
require('Speak')



getch.enableblock(1);
unix.usleep(1E6*1.0);


-- initialize state machines
HeadFSM.entry();
Motion.entry();

Body.set_head_hardness({0.4,0.4});
HeadFSM.sm:set_state('headScan');
--BodyFSM.sm:set_state('bodySearch');
--Motion.sm:set_state('stance');
--walk.entry();
Motion.sm:set_state('sit');

-- main loop
count = 0;
vcmcount=0;
local t0=Body.get_time();
local last_update_time=t0;
local headangle=vector.new({0,10*math.pi/180});
local headsm_running=0;
local last_vision_update_time=t0;
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

function print_debug()
  local t = Body.get_time();
  local ball = wcm.get_ball();
  print(string.format("Ball: (%f, %f) seen %.1f sec ago", ball.x, ball.y, t-ball.t));
end

function process_keyinput()

local str=getch.get();
  if #str>0 then
	local byte=string.byte(str,1);
	-- Move the head around

	bodysm_running=0;
	
	if byte==string.byte("w") then
		headsm_running=0;
		headangle[2]=headangle[2]-5*math.pi/180;
	elseif byte==string.byte("a") then	
		headangle[1]=headangle[1]+5*math.pi/180;
		headsm_running=0;
	elseif byte==string.byte("s") then	
		headangle[1],headangle[2]=0,0;
		headsm_running=0;
	elseif byte==string.byte("d") then	
		headangle[1]=headangle[1]-5*math.pi/180;
		headsm_running=0;
	elseif byte==string.byte("x") then	
		headangle[2]=headangle[2]+5*math.pi/180;
		headsm_running=0;
	elseif byte==string.byte("e") then	
		headangle[2]=headangle[2]-1*math.pi/180;
		headsm_running=0;
	elseif byte==string.byte("c") then	
		headangle[2]=headangle[2]+1*math.pi/180;
		headsm_running=0;
  elseif byte==string.byte("v") then
    HeadFSM.sm:set_state('headFigure8');

	--Camera angle tuning 
	elseif byte==string.byte("q") then
		cameraangle=cameraangle-1*math.pi/180;
			print("Head camera angle:",cameraangle*180/math.pi);
		vcm.motion.cameraAngle[1]=cameraangle;
	elseif byte==string.byte("z") then
		cameraangle=cameraangle+1*math.pi/180;
		print("Head camera angle:",cameraangle*180/math.pi);
		vcm.motion.cameraAngle[1]=cameraangle;


  --Broadcast selection
  elseif byte==string.byte("g") then
    local mymod = 2;
    mymod = 4;
    broadcast_enable=(broadcast_enable+1)%mymod;
		print("Broadcast:", broadcast_enable);

  -- Walk velocity setting
	elseif byte==string.byte("i") then	targetvel[1]=targetvel[1]+0.02;
	elseif byte==string.byte("j") then	targetvel[3]=targetvel[3]+0.1;
	elseif byte==string.byte("k") then	targetvel[1],targetvel[2],targetvel[3]=0,0,0;
	elseif byte==string.byte("l") then	targetvel[3]=targetvel[3]-0.1;
	elseif byte==string.byte(",") then	targetvel[1]=targetvel[1]-0.02;
	elseif byte==string.byte("h") then	targetvel[2]=targetvel[2]+0.02;
	elseif byte==string.byte(";") then	targetvel[2]=targetvel[2]-0.02;

  -- HeadFSM setting
	elseif byte==string.byte("1") then	
		headsm_running = 1-headsm_running;
    if( headsm_running==1 ) then
  		HeadFSM.sm:set_state('headScan');
    end
	elseif byte==string.byte("2") then
    headsm_running = 0; -- Turn off the head state machine
    -- HeadTransform
    local ball = wcm.get_ball();
    local trackZ = Config.vision.ball_diameter; -- Look a little above the ground
    -- TODO: Nao needs to add the camera select
    headangle = vector.zeros(2);
    headangle[1],headangle[2] = HeadTransform.ikineCam(ball.x, ball.y, trackZ);
    print("Head Angles for looking directly at the ball", unpack(headangle*180/math.pi));
    Body.set_head_command(headangle);


	elseif byte==string.byte("3") then	
		if Config.game.robotID==9 then
			local ball = vcm.ball;
			pickup.throw=0;
			Motion.event("pickup");
		else
			kick.set_kick("kickForwardLeft");
			Motion.event("kick");
		end
	elseif byte==string.byte("4") then	
		if Config.game.robotID==9 then
			pickup.throw=1;
			Motion.event("pickup");
		else
			kick.set_kick("kickForwardRight");
			Motion.event("kick");
		end


	elseif byte==string.byte("5") then	--Turn on body SM
		headsm_running=1;
		bodysm_running=1;
   	        BodyFSM.sm:set_state('bodySearch');   
		HeadFSM.sm:set_state('headScan');
	elseif byte==string.byte("6") then	--Kick head SM
		headsm_running=1;
		HeadFSM.sm:set_state('headKick');
	elseif byte==string.byte("7") then	Motion.event("sit");
	elseif byte==string.byte("8") then	
		if walk.active then 
			walk.stopAlign();
		end
		Motion.event("standup");
		
	elseif byte==string.byte("9") then	
		Motion.event("walk");
		walk.start();
	end

	walk.set_velocity(unpack(targetvel));
  end

end

function update()
  Body.set_syncread_enable(0); --read from only head servos
  
  -- Update the relevant engines
  Body.update();
  Motion.update();

  -- Update the HeadFSM if it is running
  if( headsm_running==1 ) then
    HeadFSM.update();
  end

  -- Update the BodyFSM if it is running
  if( headsm_running==1 ) then
    HeadFSM.update();
  end

  -- Get a keypress
  process_keyinput();

  -- Send updates over the network
  Broadcast.update(broadcast_enable);

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
    print(fps.." FPS")
    -- Print the debug information
    print_debug();
  end

  --Wait until dcm has done reading/writing
  unix.usleep(tDelay);

end

