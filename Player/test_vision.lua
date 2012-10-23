module(... or '', package.seeall)

-- Get Platform for package path
cwd = '.';
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
package.path = cwd .. '/Motion/Walk/?.lua;' .. package.path;
package.path = cwd .. '/Vision/?.lua;' .. package.path;
package.path = cwd .. '/World/?.lua;' .. package.path;

require('Config')
require('unix')
require('getch')
require('Broadcast')
require('shm')
require('vector')
require('mcm')
require('vcm')
require('wcm')
require('Speak')
require('Body')
require('Motion')
require('gcm')
require('ocm')

gcm.say_id()

smindex = 0;

Motion.entry();
darwin = false;
webots = false;

-- Enable OP specific 
if(Config.platform.name == 'OP') then
  darwin = true;
end

--enable new nao specific
--TODO: auto-detect using hostname
newnao = true;

getch.enableblock(1);
unix.usleep(1E6*1.0);
Body.set_body_hardness(0);

--This is robot specific 
webots = false;
init = false;
calibrating = false;
ready = false;
if( webots or darwin) then
  ready = true;
end

--State variables
initToggle = true;
targetvel=vector.zeros(3);
headangle=vector.new({0,10*math.pi/180});
headsm_running=0;
bodysm_running=0;

local count = 0;
local ncount = 100;
local imagecount = 0;
local t0 = unix.time();
local tUpdate = t0;

-- Broadcast the images at a lower rate than other data
local broadcast_enable=0;
local imageCount=0;

-- set game state to ready to stop init particle filter during debugging
gcm.set_game_state(1);


-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();
Config.fsm.playMode=1; --Always demo mode
fsm.enable_walkkick = 0;
fsm.enable_sidekick = 0;
broadcast_enable=0;
button_pressed = {0,0};

function process_keyinput()
  --Robot specific head pitch bias
  headPitchBiasComp = 
	mcm.get_walk_headPitchBiasComp();
  headPitchBias = mcm.get_headPitchBias()

  --Toggle body SM when button is pressed and then released
  if (Body.get_change_state() == 1) then
    button_pressed[1]=1;
  else
    if button_pressed[1]==1 then
      if bodysm_running==0 then 
        Body.set_head_hardness(0.5);
        headsm_running=1;
        bodysm_running=1;
        BodyFSM.sm:set_state('bodySearch');   
        HeadFSM.sm:set_state('headScan');
        walk.start();
      else
        if walk.active then walk.stop();end
        bodysm_running=0;
        Motion.event("standup");
      end
    end
    button_pressed[1]=0;
  end

  local str=getch.get();
  if #str>0 then

    local byte=string.byte(str,1);
    -- Walk velocity setting
    if byte==string.byte("i") then	targetvel[1]=targetvel[1]+0.02;
    elseif byte==string.byte("j") then	targetvel[3]=targetvel[3]+0.1;
    elseif byte==string.byte("k") then	targetvel[1],targetvel[2],targetvel[3]=0,0,0;
    elseif byte==string.byte("l") then	targetvel[3]=targetvel[3]-0.1;
    elseif byte==string.byte(",") then	targetvel[1]=targetvel[1]-0.02;
    elseif byte==string.byte("h") then	targetvel[2]=targetvel[2]+0.02;
    elseif byte==string.byte(";") then	targetvel[2]=targetvel[2]-0.02;

    -- reset OccMap
    elseif byte==string.byte("/") then 
      print("reset occomap");
      ocm.set_occ_reset(1);
    elseif byte==string.byte(".") then
      print("get obstacles");
      nob = ocm.get_ob_num();
      print(nob,' obstacle found');
      if (nob > 0) then 
        obx = ocm.get_ob_x();
        print('obstacle x')
        util.ptable(obx);
        oby = ocm.get_ob_y();
        print('obstacle y')
        util.ptable(oby);
        obdist = ocm.get_ob_dist();
        print('obstacle dist')
        util.ptable(obdist);
      end

    --switch camera 
    elseif byte==string.byte("-") then
      vcm.set_camera_command(1);
    elseif byte==string.byte("=") then
      vcm.set_camera_command(0);

    -- Move the head around
    elseif byte==string.byte("w") then
      headsm_running=0;headangle[2]=headangle[2]-5*math.pi/180;
    elseif byte==string.byte("a") then
      headsm_running=0;headangle[1]=headangle[1]+5*math.pi/180;
    elseif byte==string.byte("d") then
      headsm_running=0;headangle[1]=headangle[1]-5*math.pi/180;
    elseif byte==string.byte("x") then
      headsm_running=0;headangle[2]=headangle[2]+5*math.pi/180;
    elseif byte==string.byte("s") then
      headsm_running=0;headangle[1],headangle[2]=0,0;

    -- Head pitch fine tuning (for camera angle calibration)
    elseif byte==string.byte("e") then	
      headsm_running=0;headangle[2]=headangle[2]-1*math.pi/180;
    elseif byte==string.byte("c") then	
      headsm_running=0;headangle[2]=headangle[2]+1*math.pi/180;

    -- Camera angle bias fine tuning 
    elseif byte==string.byte("q") then	
      headsm_running=0;
      headPitchBiasComp = headPitchBiasComp+math.pi/180;
      mcm.set_walk_headPitchBiasComp(headPitchBiasComp);
      print("\nCamera pitch bias:",headPitchBiasComp*180/math.pi);
    elseif byte==string.byte("z") then	
      headsm_running=0;
      headPitchBiasComp = headPitchBiasComp-math.pi/180;
      mcm.set_walk_headPitchBiasComp(headPitchBiasComp);
      print("\nCamera pitch bias:",headPitchBiasComp*180/math.pi);
    -- Head FSM testing
    elseif byte==string.byte("1") then	
      headsm_running = 1-headsm_running;
      if (headsm_running == 1) then
        Body.set_head_hardness(0.5);
        HeadFSM.sm:set_state('headScan');
      end

    elseif byte==string.byte("2") then	
    -- Camera transform testing
      headsm_running = 0;
      local ball = wcm.get_ball();
      local trackZ = Config.vision.ball.diameter/2; 
      -- TODO: Nao needs to add the camera select
      headangle = vector.zeros(2);
      headangle[1],headangle[2] = 
 	HeadTransform.ikineCam(ball.x,	ball.y, trackZ);
      headangle[2]=headangle[2]+headPitchBias; 
	--this is substracted below
      print("Head Angles for looking directly at the ball:", 
	unpack(headangle*180/math.pi));

    elseif byte==string.byte("f") then
      behavior.cycle_behavior();

    --Logging mode

    elseif byte==string.byte("3") then
      Body.set_head_hardness(0.4);
      HeadFSM.sm:set_state('headLog');
      headsm_running=1;

    elseif byte==string.byte("4") then
      Body.set_head_hardness(0.4);
      HeadFSM.sm:set_state('headLog');
--      HeadFSM.sm:set_state('headObs');
      headsm_running=1;

    elseif byte==string.byte("5") then
    --Turn on body SM
      headsm_running=1;
      bodysm_running=1;
      Body.set_head_hardness(0.5);
      BodyFSM.sm:set_state('bodySearch');   
      HeadFSM.sm:set_state('headScan');
       ocm.set_occ_reset(1);

      walk.start();

    elseif byte==string.byte("6") then
      headsm_running=0;
      headangle[1]=0;
      headangle[2]= Config.fsm.headKick.pitch0;

      local ball = wcm.get_ball();
      footX = Config.walk.footX or 0;
      print("foot center to ball pos: ",ball.x,ball.y);      

    elseif byte==string.byte("g") then	
      --Broadcast selection
      local mymod = 4;
      broadcast_enable = (broadcast_enable+1)%mymod;

      print("\nBroadcast:", broadcast_enable);
    --Left kicks (for camera angle calibration)
--    elseif byte==string.byte("3") then	
--      kick.set_kick("kickForwardLeft");
--      Motion.event("kick");
    elseif byte==string.byte("t") then
      walk.doWalkKickLeft();
    elseif byte==string.byte("y") then
      walk.doSideKickLeft();
    elseif byte==string.byte("7") then	
      headsm_running,bodysm_running=0,0;
      Motion.event("sit");
    elseif byte==string.byte("8") then	
      if walk.active then walk.stop();end
      bodysm_running=0;
      Motion.event("standup");
    elseif byte==string.byte("9") then	
ocm.set_occ_reset(1);

      Motion.event("walk");
      walk.start();
    elseif byte==string.byte("0") then	
      Motion.event("diveready");
    elseif byte==string.byte('o') then
      print("reset occ map")
      ocm.set_occ_reset(1);
      headangle[2]=50*math.pi/180;
    elseif byte==string.byte('p') then
      print(Config.obs_challenge);
      vcm.set_image_learn_lut(1);
    end


    if headsm_running == 0 then
      Body.set_head_command({headangle[1],headangle[2]-headPitchBias});
      print("\nHead Yaw Pitch:", unpack(headangle*180/math.pi))


    end
  end
end


function update()
  count = count + 1;
  --Update battery info
  wcm.set_robot_battery_level(Body.get_battery_level());
  --Set game state to SET to prevent particle resetting
  gcm.set_game_state(1);

  if (not init)  then
    if (calibrating) then
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        calibrating = false;
        ready = true;
      end
    elseif (ready) then
      -- initialize state machines
      package.path = cwd..'/BodyFSM/'..Config.fsm.body[smindex+1]..'/?.lua;'..package.path;
      package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
      require('BodyFSM')
      require('HeadFSM')

      BodyFSM.entry();
      HeadFSM.entry();

      init = true;
    else
      if (count % 20 == 0) then
--start calibrating without waiting 
--        if (Body.get_change_state() == 1) then
          Speak.talk('Calibrating');
          calibrating = true;
--        end
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
    -- update state machines 
    process_keyinput();
    
--[[
    if wcm.get_attack_bearing() ~= nil then
    ob_num = ocm.get_obstacle_num();
    ob_angle = ocm.get_obstacle_angle_range();
    ob_nearest = ocm.get_obstacle_nearest();
    dir = 1; -- left : 2 -- right
    obstacle = 0;
    close = 0
--    print(ob_angle);

    for i = 1, ob_num * 2, 2 do
      if ob_angle[i] > 1.4 and ob_angle[i+1] < 1.9 and ob_nearest[i+1] < 0.3 then
        print("obstacle");
        obstacle = 1;
      end
      if ob_angle[i] < 1.3 then dir = 2; print("turn right") end
      if ob_angle[i] > 2 then dir = 1; print("turn left") end
    end

    if obstacle == 1 then
      if dir == 1 then 
        attackBearing = wcm.get_attack_bearing() - 25 * math.pi/180;
      elseif dir == 2 then
        attackBearing = wcm.get_attack_bearing() + 25 * math.pi/180;
      end
    else
      attackBearing = wcm.get_attack_bearing();
    end
    obstacle = 0;
    vx = 0.02;
    vy = 0;
    va = 0.2*attackBearing;
  end
--]]

--    walk.set_velocity(vx,vy,va);
    walk.set_velocity(unpack(targetvel));


    Motion.update();
    Body.update();
    -- Keep setting monitor flag
    vcm.set_camera_broadcast(broadcast_enable);

    if headsm_running>0 then
      HeadFSM.update();
    end
    if bodysm_running>0 then
      BodyFSM.update();
    end
  end
  local dcount = 50;
  if (count % 50 == 0) then
--    print('fps: '..(50 / (unix.time() - tUpdate)));
    tUpdate = unix.time();
    -- update battery indicator
    Body.set_indicator_batteryLevel(Body.get_battery_level());
  end
  
  -- check if the last update completed without errors
  lcount = lcount + 1;
  if (count ~= lcount) then
    print('count: '..count)
    print('lcount: '..lcount)
    Speak.talk('missed cycle');
    lcount = count;
  end
end

-- if using Webots simulator just run update
if (webots) then
  while (true) do
    -- update motion process
    update();
    io.stdout:flush();
  end
end

--Now nao are running main process separately too

if( darwin or newnao) then
  local tDelay = 0.005 * 1E6; -- Loop every 5ms
  while 1 do
    process_keyinput();
    unix.usleep(tDelay);
    update();
  end
end
