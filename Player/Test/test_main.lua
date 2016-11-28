-- cwd = cwd or os.getenv('PWD')
-- package.path = cwd.."/?.lua;"..package.path;
cwd = os.getenv('PWD')
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

gcm.say_id()

Motion.entry();

darwin = false;
naov4 = true

-- Enable OP specific 
if(Config.platform.name == 'OP') then
  darwin = true;
  naov4 = false
end

getch.enableblock(1);
unix.usleep(1E6*1.0);
Body.set_body_hardness(0);

initialize = false;
calibrating = false;
ready = false;
if darwin then
  ready = true;
end


smindex = 0;
local initToggle = true;

-- main loop
local count = 0;
local lcount = 0;
local t0 = unix.time()
local tUpdate = t0
local broadcast_enable=0;


penalized_state={0,0,0,0,0};

print("=====================================================")
print("TEST GRASP LOADED")
print("1,2,3,4,5: Initial / Ready / Set/ Playing / Finished")
print("8,9: Blue / Red kickoff")
print("q,w,e,r,t: Penalize player 1/2/3/4/5")
print("=====================================================")



function process_keyinput()
  local str=getch.get();
  if #str>0 then
    local byte = string.byte(str,1);

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
    elseif byte==string.byte("g") then	
      --Broadcast selection
      local mymod = 4;
      broadcast_enable = (broadcast_enable+1)%mymod;
      print("\nBroadcast:", broadcast_enable);
    
      
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

  if not initialize then
    if (calibrating) then
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        calibrating = false;
        ready = true;
      end
      
    elseif ready then
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

      initialize = true;
      print("====Initialize done====")
    else
      -- Start calibrating w/o waiting
      if (count % 20 == 0) then
          Speak.talk('Calibrating');
          calibrating = true;
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
    process_keyinput()
    -- update state machines 
    GameFSM.update();
    BodyFSM.update();
    HeadFSM.update();
    Motion.update();
    Body.update();
    -- Keep setting monitor flag
    vcm.set_camera_broadcast(broadcast_enable);
  end

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

--[[ if using Webots simulator just run update
if (webots) then
  require('cognition');
  cognition.entry();

  -- set game state to Initial
  gcm.set_game_state(0);

  while (true) do

    process_keyinput();

    -- update cognitive process
    cognition.update();
    GameControl.update();
    Team.update();
    -- update motion process
    update();
    io.stdout:flush();
  end

end
--]]

if( naov4 or darwin ) then
  local tDelay = 0.005 * 1E6; -- Loop every 5ms
  
  -- Make sure start with init
  gcm.set_game_state(0);
  
  while true do
    process_keyinput()
    unix.usleep(tDelay);
    -- Update motion process
    update();
  end
end
