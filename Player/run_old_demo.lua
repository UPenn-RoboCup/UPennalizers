cwd = os.getenv('PWD')
require('init')

require('unix')
require('Config')
Config.fsm.playMode = 1; --Force demo
Config.fsm.forcePlayer = 1; --Force attacker
--Config.dev.team = 'TeamBox'; --For mimicing

require('shm')
require('vector')
require('vcm')
require('gcm')
require('wcm')
require('mcm')
require('Speak')
require('getch')
require('Body')
require('Motion')

--require('boxercm') --For mimicing

gcm.say_id();

Motion.entry();

darwin = false;
webots = false;

--Demo mode, 0 for soccer, 1 for push recovery, 2 for mimic
demo_mode = 0; 

--Cycle time for kick types
kick_cycle_time = 15;
kick_cycle_t0 = 0;

-- Enable OP specific 
if(Config.platform.name == 'OP') then
  darwin = true;
  --SJ: OP specific initialization posing (to prevent twisting)
  Body.set_body_hardness(0.3);
  Body.set_actuator_command(Config.stance.initangle)
  unix.usleep(1E6*0.5);
  Body.set_body_hardness(0);
  Body.set_lleg_hardness({0.2,0.6,0,0,0,0});
  Body.set_rleg_hardness({0.2,0.6,0,0,0,0});
end 


-- Enable Webots specific
if (string.find(Config.platform.name,'Webots')) then
  webots = true;
end

init = false;
calibrating = false;
ready = false;
if( webots or darwin) then
  ready = true;
end

smindex = 0;
initToggle = true;

--SJ: Now we use a SINGLE state machine for goalie and attacker
package.path = cwd..'/BodyFSM/'..Config.fsm.body[smindex+1]..'/?.lua;'..package.path;
package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
require('BodyFSM')
require('HeadFSM')
require('behavior')


BodyFSM.entry();
HeadFSM.entry();

-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();

--Start with PAUSED state
gcm.set_game_paused(1);
role = 1; --Attacker
waiting = 1;
goal = 5
team_role = 0

button_role,button_state = 0,0;
tButtonRole = 0;

qL_old = {0,0,0};
qR_old = {0,0,0};
rpy_old = {0,0,0};

qL_threshold = {10*math.pi/180, 10*math.pi/180, 10*math.pi/180};
qR_threshold = {10*math.pi/180, 10*math.pi/180, 10*math.pi/180};
rpy_threshold = {70*math.pi/180, 10*math.pi/180, 20*math.pi/180};

qL_alpha = {0.2,0.2,0.2};
qR_alpha = {0.2,0.2,0.};
rpy_alpha = {0.0,0.2,0.1};


function mov_filter(oldvel, newvel, threshold, filter_alpha)
  local filteredvel = {0,0,0};
  for i=1,3 do
    diff = newvel[i]-oldvel[i];
    if math.abs(diff) > threshold[i] then
      filteredvel[i] = newvel[i];
    else
      filteredvel[i] = newvel[i]*(1-filter_alpha[i]) + 
			oldvel[i]* filter_alpha[i];
    end
  end
  return filteredvel;
end


function do_mimic()
  walk.stop()
  -- Check if there is a punch activated
  local qL = boxercm.get_body_qLArm();
  local qR = boxercm.get_body_qRArm();
  local rpy = boxercm.get_body_rpy();
  -- Add the override
--  walk.upper_body_override(qL, qR, rpy);

  qL_old = mov_filter(qL_old,qL,qL_threshold, qL_alpha);
  qR_old = mov_filter(qR_old,qR,qR_threshold, qR_alpha);
  rpy_old = mov_filter(rpy_old,rpy,rpy_threshold, rpy_alpha);

  rpy_old[1] = 0; --Kill roll angle

  walk.upper_body_override(qL_old, qR_old, rpy_old);
end


function update()
  count = count + 1;
  t = Body.get_time();
  --Update battery info
  wcm.set_robot_battery_level(Body.get_battery_level());
  vcm.set_camera_teambroadcast(1); --Turn on wireless team broadcast

  if (vcm.get_ball_detect() == 1) then
    ball_led = {0,1,0}
  else
    ball_led = {0,0,0}
  end

--  if Config.led_on > 0 then
    Body.set_indicator_ball(ball_led);
--  else
--    Body.set_indicator_ball({0,0,0});
--  end

  --Check pause button Releases
  if (Body.get_change_state() == 1) then
    button_role=1;
    if (t-tButtonRole>1.0) then --Button pressed for 1 sec
      waiting = 1-waiting;
      if waiting==0 then --Start up and start demo

      	if demo_mode == 0 then --Soccer demo 
      	  walk.enable_ankle_pr = true;
      	  walk.enable_hip_pr = false; --Disable hip strategy
      	  Motion.fallAngle = Config.fallAngle; --Enable falldown check
          Speak.talk('Soccer Demo');
          BodyFSM.sm:set_state('bodySearch');   
          HeadFSM.sm:set_state('headScan');
          Motion.event("standup");
          kick_cycle_t0 = unix.time();
      	elseif demo_mode == 1 then -- Push demo
      	  walk.enable_ankle_pr = true;
      	  walk.enable_hip_pr = true; --Enable hip strategy
      --	  Motion.fallAngle = 240*math.pi/180;--Disable falldown check
      	  Motion.fallAngle = Config.fallAngle; --Enable falldown check
          Speak.talk('Push Demo');
          if walk.active then walk.stop(); end
      	  Motion.event("standup");
      	elseif demo_mode == 2 then -- Mimic demo
      	  walk.enable_ankle_pr = true;
      	  walk.enable_hip_pr = false; --Enable hip strategy
      	  Motion.fallAngle = 240*math.pi/180;--Disable falldown check
          Speak.talk('Mimic Demo');
          if walk.active then walk.stop(); end
	        Motion.event("standup");
          walk.upper_body_override_on();
        else 
      	  walk.enable_ankle_pr = true;
      	  walk.enable_hip_pr = false; -- disable hip strategy
          if walk.active then walk.stop(); end
      	  Motion.fallAngle = Config.fallAngle; --Enable falldown check
          Speak.talk('Pose Demo');
          BodyFSM.sm:set_state('bodyReady');
      	  Motion.event("standup");
        end

      else
      	--Sit down and rest
      	batlevel = string.format("Battery Level %.1f",
      	Body.get_battery_level());
      	Speak.talk(batlevel)
        Motion.event("sit");
        walk.upper_body_override_off()
      end
      tButtonRole = t;
    end
  else
    button_role= 0;
    tButtonRole = t;
  end

  --Check center button press
  if (Body.get_change_role() == 1) then
    button_state=1;
  else
    if button_state==1 then --Button released
      behavior.cycle_behavior();
      button_state=0;
      if waiting > 0 then --Cycle demo mode while in waiting
        demo_mode = (demo_mode + 1 )%4; --Cycle demo mode
        if demo_mode == 0 then
          Speak.talk('Soccer');
        elseif demo_mode ==1 then
          Speak.talk('Push Recovery');
        elseif demo_mode == 2 then
          Speak.talk('Mimic');
        else
          Speak.talk('Pose');
        end
      end
    end
  end

  if waiting>0 then --Waiting mode, check role change
    if demo_mode == 0 then --Soccer demo 
      Body.set_indicator_ball({0,1,0}); --Green eye LED for soccer demo
    elseif demo_mode == 1 then --Push demo 
      Body.set_indicator_ball({0,0,1}); --Blue eye LED for push demo
    elseif demo_mode == 2 then -- Mimic mode
      Body.set_indicator_ball({1,1,0}); --Yellow eye LED for mimic demo
    else
      Body.set_indicator_ball({1,0,1}); --Yellow eye LED for mimic demo
    end
    Motion.update();
    Body.update();
  else --Playing mode, update state machines  

    if demo_mode == 0 then -- Soccer mode requires FSM to run
      gcm.set_game_paused(0);
      BodyFSM.update();
      HeadFSM.update();

      --Cycle kick types when in soccer mode
      if t-kick_cycle_t0>kick_cycle_time then 
   --     behavior.cycle_behavior();
        kick_cycle_t0 = t;
      end
    elseif demo_mode == 2 then -- Mimic mode
      do_mimic();
    elseif demo_mode == 3 then
      if walk.active then walk.stop(); end
      goal = goal + 1
      team_role = (gcm.get_team_role() + 1)%3
      gcm.set_team_role(team_role)
      gcm.set_game_opponent_score(0)
      gcm.set_game_our_score(goal)
      gcm.set_game_paused(0);
      BodyFSM.update();
    end

    Motion.update(); -- Other modes just requires motion
    Body.update();

  end

  local dcount = 50;
  if (count % 50 == 0) then
--    print('fps: '..(50 / (unix.time() - tUpdate)));
    tUpdate = unix.time();
    -- update battery indicator
    Body.set_indicator_batteryLevel(Body.get_battery_level());
  end
  
end

-- if using Webots simulator just run update
if (webots) then
  require('cognition');
  cognition.entry();

  -- set game state to Playing
  gcm.set_game_state(3);

  while (true) do
    -- update cognitive process
    cognition.update();
    -- update motion process
    update();

    io.stdout:flush();
  end

end

if( darwin ) then
  local tDelay = 0.005 * 1E6; -- Loop every 5ms
  while 1 do
    update();
    unix.usleep(tDelay);
  end
end
