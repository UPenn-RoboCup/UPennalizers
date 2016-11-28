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
package.path = cwd.."/BodyFSM/?.lua;"..package.path;
package.path = cwd.."/HeadFSM/?.lua;"..package.path;

require('Config');
--Config.dev.comm='NaoCommWired'

require('shm')

--[[
if Config.platform.name=='Nao' then
	print("Waiting for VCM initializing....")
	shm.destroy('shmVcm')
	dcmShm=shm.new('shmVcm')
	dcmShm.ready=vector.zeros(1);
	while dcmShm:get('ready')==0 do
	end
end
	dcmShm:set('ready',{1});
--]]

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

--[[
-- initialize state machines
HeadFSM.entry();
Motion.entry();
--]]
--[['
Body.set_head_hardness({0.4,0.4});
HeadFSM.sm:set_state('headScan');
--BodyFSM.sm:set_state('bodySearch');
--Motion.sm:set_state('stance');
--walk.entry();
Motion.sm:set_state('sit');
--]]
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

function update()
  Body.set_syncread_enable(0); --read from only head servos
  count = count + 1;
  local t= Body.get_time();
  --Body.update();
  --Motion.update();

  -- Get a keypress
  local head_moved=0;
  local str=getch.get();
  if #str>0 then
	  local byte=string.byte(str,1);
	  -- Move the head around

	  bodysm_running=0;
	  --[[
	  if byte==string.byte("w") then
		  headsm_running=0;
		  headangle[2]=headangle[2]-5*math.pi/180;
		  head_moved=1;
	  elseif byte==string.byte("a") then	
		  headangle[1]=headangle[1]+5*math.pi/180;
		  headsm_running=0;
		  head_moved=1;
	  elseif byte==string.byte("s") then	
		  headangle[1],headangle[2]=0,0;
		  headsm_running=0;
		  head_moved=1;
	  elseif byte==string.byte("d") then	
		  headangle[1]=headangle[1]-5*math.pi/180;
		  headsm_running=0;
		  head_moved=1;
	  elseif byte==string.byte("x") then	
		  headangle[2]=headangle[2]+5*math.pi/180;
		  headsm_running=0;
		  head_moved=1;
	  elseif byte==string.byte("e") then	
		  headangle[2]=headangle[2]-1*math.pi/180;
		  headsm_running=0;
		  head_moved=1;
	  elseif byte==string.byte("c") then	
		  headangle[2]=headangle[2]+1*math.pi/180;
		  headsm_running=0;
		  head_moved=1;
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


	  elseif byte==string.byte("t") then	--Reset localization
		  vcm.world.penalized[1]=1-vcm.world.penalized[1];
	  else--]]if byte==string.byte("g") then	--Broadcast selection
                  local mymod = 2;
  --                if( Config.dev.comm == "NaoCommWired" ) then
                    mymod = 4;
  --                end
                  broadcast_enable=(broadcast_enable+1)%mymod;
		  hires_broadcast=0;
		  print("Broadcast:", broadcast_enable);
  --[[	elseif byte==string.byte("r") then	--High res streaming
		  broadcast_enable=1;
		  hires_broadcast=1-hires_broadcast;
		  print("High res broadcast",hires_broadcast);

	  elseif byte==string.byte("i") then	targetvel[1]=targetvel[1]+0.02;
	  elseif byte==string.byte("j") then	targetvel[3]=targetvel[3]+0.1;
	  elseif byte==string.byte("k") then	targetvel[1],targetvel[2],targetvel[3]=0,0,0;
	  elseif byte==string.byte("l") then	targetvel[3]=targetvel[3]-0.1;
	  elseif byte==string.byte(",") then	targetvel[1]=targetvel[1]-0.02;
	  elseif byte==string.byte("h") then	targetvel[2]=targetvel[2]+0.02;
	  elseif byte==string.byte(";") then	targetvel[2]=targetvel[2]-0.02;

	  elseif byte==string.byte("1") then	
		  headsm_running=1;
  --		HeadFSM.sm:set_state('headScan');
		  HeadFSM.sm:set_state('headLookLandmarks');

	  elseif byte==string.byte("2") then	headsm_running=2;

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
		  vcm.world.reset[1]=0;

	  elseif byte==string.byte("6") then	--Kick head SM
		  headsm_running=1;
		  HeadFSM.sm:set_state('headKick');
	  elseif byte==string.byte("7") then	Motion.event("sit");
	  elseif byte==string.byte("8") then	
		  if walk.active then 
			  walk.stopAlign();
  --			vcm.world.reset[1]=1;
		  else
  --			vcm.world.reset[1]=0;
		  end
		  Motion.event("standup");
		
	  elseif byte==string.byte("9") then	
		  Motion.event("walk");
		  walk.start();--]]
	  end


	--walk.set_velocity(unpack(targetvel));
  end

  if hires_broadcast==1 then
    imagecount=imagecount+1;
    Broadcast.update_img2(imagecount,4)
  end
  Broadcast.update_img(broadcast_enable,0);
  Broadcast.update_img(broadcast_enable,1);

  Broadcast.update(broadcast_enable);

--[[
  if broadcast_enable>0 and count%25==12 then
 	Broadcast.update_particle();
  end
--]]
--[[
  if vcm.etc.updated[1]==1 then
	vcm.etc.updated[1]=0;
	vcmcount=vcmcount+1;

	local ball = vcm.ball;
	if( ball.detect[1]==1 ) then 
    ballcount=ballcount+1; 
  end
	visioncount=visioncount+1;

--	poseSV=vcm.world.poseSV;
--	print(poseSV[1],poseSV[2],poseSV[3]*180/math.pi)
	if broadcast_count==0 then broadcast_count=1;end
  end

  if t-last_update_time>t_update then
        local ballworld=vcm.world.ball;
        print(string.format("Ball: %d%% XY:%.1f,%.1f seen %.1f sec ago Walk %d fps Vision %d fps", 
		ballcount/visioncount*100, ballworld[1],ballworld[2],t-ballworld[3], 
		count/t_update,vcmcount/t_update
	));
	ballcount,visioncount=0,0;
	last_update_time=t;
	count,vcmcount=0,0;
  end
--]]
end


--if (darwin) then

     local tDelay=0.010*1E6;
     local tDelay=0.002*1E6;


     while 1 do
	--Wait until dcm has done reading/writing
          unix.usleep(tDelay);
          update()
     end
--[[
else
     dcmShm=shm.open('shmDcm')
     while(1) do
	    local tDelay = 0.005 * 1E6; -- Loop every 5ms
	    local tDelay2 = 0.001 * 1E6; -- Loop every 5ms
	    updated=dcmShm:get('updated');
	    if updated==1 then
		dcmShm:set('updated',{0});
	        update();
		unix.usleep(tDelay);
	    else
		unix.usleep(tDelay2);
	    end
    end
end
--]]
