cwd = os.getenv('PWD')
require('init')

require('unix')
require('Config')
Config.fsm.playMode = 1; --Force demo
Config.fsm.forcePlayer = 1; --Force attacker
Config.fsm.enable_walkkick = 1; 
Config.fsm.enable_sidekick = 1;

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

gcm.say_id();

Motion.entry();

darwin = false;
webots = false;
newnao = false;

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
if (string.find(Config.platform.name,'Webots')) then
  webots = true;
end

if(Config.platform.name == 'NaoV4') then
  newnao = true;
  init = false;
else
  init = true;
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



function update()
  count = count + 1;
  t = Body.get_time();
  --Update battery info
  wcm.set_robot_battery_level(Body.get_battery_level());
  vcm.set_camera_teambroadcast(1); --Turn on wireless team broadcast

  if (not init) then
    if not calibrating then 
      Speak.talk('Calibrating');
      calibrating = true;
    else    
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        init = true;
      end
    end
    return;
  end

  if (vcm.get_ball_detect() == 1) then  ball_led = {0,1,0}
  else    ball_led = {0,0,0}
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
        Speak.talk('Soccer Demo');
        BodyFSM.sm:set_state('bodySearch');   
        HeadFSM.sm:set_state('headScan');
        Motion.event("standup");
        kick_cycle_t0 = unix.time();
      else
      	--Sit down and rest
      	batlevel = string.format("Battery Level %.1f",
      	Body.get_battery_level());
      	Speak.talk(batlevel)
        Motion.event("sit");
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
    if newnao then
      if waiting>0 and button_state==1 then
        behavior.cycle_behavior();
      end
    elseif button_state==1 then --Button released
      behavior.cycle_behavior();
    end

    button_state = 0;
  end

  if waiting>0 then --Waiting mode, check role change
    Body.set_indicator_ball({0,1,0}); --Green eye LED for soccer demo
    Motion.update();
    Body.update();
  else --Playing mode, update state machines  
    gcm.set_game_paused(0);
    BodyFSM.update();
    HeadFSM.update();
    Motion.update(); -- Other modes just requires motion
    Body.update();
  end
  local dcount = 50;
  if (count % 50 == 0) then
    tUpdate = unix.time();
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
    cognition.update();    -- update cognitive process
    update();    -- update motion process
    io.stdout:flush();
  end
end

if( darwin ) or (newnao) then
  local tDelay = 0.005 * 1E6; -- Loop every 5ms
  while 1 do
    update();
    unix.usleep(tDelay);
  end
end
