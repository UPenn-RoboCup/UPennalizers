cwd = cwd or os.getenv('PWD')
package.path = cwd.."/?.lua;"..package.path;
require('init')

require('unix')
require('Config')
require('Speak')
require('shm')
require('vector')
require('gcm')
require('wcm')
require('mcm')
require('getch')

io.stdout:flush();

require('Body')
require('Motion')
require('Team')
require('GameControl')

use_gps_only = Config.use_gps_only or 0;
if use_gps_only>0 then
  cognition = require('cognition_webots_gpsonly')
else
  cognition = require('cognition_webots')
end


Motion.entry();
Team.entry();
GameControl.entry();

darwin = false;
webots = true
if(Config.platform.name == 'OP') then darwin = true end


init = false;
calibrating = false;
ready = true;


smindex = 0;
initToggle = true;

-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();

--Webots specific key input
controller.wb_robot_keyboard_enable(500);

penalized_state={0,0,0,0,0};

print("=====================================================")
print("WEBOTS MAIN LOADED")
print("1,2,3,4,5: Initial / Ready / Set/ Playing / Finished")
print("8,9: Blue / Red kickoff")
print("q,w,e,r,t: Penalize player 1/2/3/4/5")
print("=====================================================")



function process_keyinput()
  local str = controller.wb_robot_keyboard_get_key();
  if str>0 then
    byte = str;
    -- Webots only return captal letter number
    if byte>=65 and byte<=90 then
      byte = byte + 32;
    end

    penalize_player=0;

    if byte==string.byte("1") then
      Speak.talk('Initial');
      gcm.set_game_state(0);
    elseif byte==string.byte("2") then
      Speak.talk('Ready');
      gcm.set_game_state(1);
    elseif byte==string.byte("3") then
      Speak.talk('Set');
      gcm.set_game_state(2);
    elseif byte==string.byte("4") then
      Speak.talk('Playing');
      gcm.set_game_state(3);
    elseif byte==string.byte("5") then
      Speak.talk('Finished');
      gcm.set_game_state(4);
    elseif byte==string.byte("8") then   
      --Blue team kickoff
      if gcm.get_team_color()==0 then
        gcm.set_game_kickoff(1);
      else
        gcm.set_game_kickoff(0);
      end
      Speak.talk('Blue kickoff');
    elseif byte==string.byte("9") then   
      if gcm.get_team_color()==0 then
        gcm.set_game_kickoff(0);
      else
        gcm.set_game_kickoff(1);
      end
      Speak.talk('Red kickoff');

    elseif byte==string.byte("q") then 
      penalize_player=1;
      penalize_team = 0;
    elseif byte==string.byte("w") then 
      penalize_player=2;
      penalize_team = 0;
    elseif byte==string.byte("e") then 
      penalize_player=3;
      penalize_team = 0;
    elseif byte==string.byte("r") then 
      penalize_player=4;
      penalize_team = 0;
    elseif byte==string.byte("t") then 
      penalize_player=5;
      penalize_team = 0;


    elseif byte==string.byte("z") then 
      penalize_player=1;
      penalize_team = 1;
    elseif byte==string.byte("x") then 
      penalize_player=2;
      penalize_team = 1;
    elseif byte==string.byte("c") then 
      penalize_player=3;
      penalize_team = 1;
    elseif byte==string.byte("v") then 
      penalize_player=4;
      penalize_team = 1;
    elseif byte==string.byte("b") then 
      penalize_player=5;
      penalize_team = 1;
    end

    if penalize_player>0 and penalize_team == gcm.get_team_color() then
      penalized_state[penalize_player]=1-penalized_state[penalize_player];
      gcm.set_game_penalty(penalized_state) ;
      if penalized_state[penalize_player]>0 then
        if penalize_team==0 then
          Speak.talk(string.format("Red Player %d penalized",penalize_player));
        else
          Speak.talk(string.format("Blue Player %d penalized",penalize_player));
        end
      else
        if penalize_team==0 then
          Speak.talk(string.format("Red Player %d unpenalized",penalize_player));
        else
          Speak.talk(string.format("Blue Player %d unpenalized",penalize_player));
        end
      end
    end

  end
end

function update()
  count = count + 1;
  --Update battery info
  wcm.set_robot_battery_level(Body.get_battery_level());

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
      package.path = cwd..'/GameFSM/'..Config.fsm.game..'/?.lua;'..package.path;
      require('BodyFSM')
      require('HeadFSM')
      require('GameFSM')

      BodyFSM.entry();
      HeadFSM.entry();
      GameFSM.entry();
--[[      
      if( webots ) then
        --BodyFSM.sm:add_event('button');
        GameFSM.sm:set_state('gamePlaying');
      end
--]]

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
    -- update state machines 
    GameFSM.update();
    BodyFSM.update();
    HeadFSM.update();
    Motion.update();
    Body.update();
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



gcm.set_game_state(0);
cognition.entry()

t_cog =Body.get_time()

while true do    
  process_keyinput();
  t= Body.get_time()
  if t-t_cog>1/30 then 
    cognition.update();      
    t_cog = t
  end
  update();
  io.stdout:flush();
end