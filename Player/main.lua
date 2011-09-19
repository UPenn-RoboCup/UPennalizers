module(... or '', package.seeall)

require('unix')

webots = false;
darwin = false;

local cwd = unix.getcwd();

-- the webots sim is run from the WebotsController dir (not Player)
if string.find(cwd, 'WebotsController') then webots = true;
  cwd = cwd..'/Player'
  package.path = cwd..'/?.lua;'..package.path;
end

computer = os.getenv('COMPUTER') or '';
if (string.find(computer, 'Darwin')) then
  -- MacOS X uses .dylib:
  package.cpath = cwd..'/Lib/?.dylib;'..package.cpath;
else
  package.cpath = cwd..'/Lib/?.so;'..package.cpath;
end

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
require('vcm')
require('gcm')
require('wcm')
require('mcm')

require('Speak')

require('getch')

require('Body')
require('Motion')

Motion.entry();

if( Config.platform.name=='darwinop' ) then
  darwin = true;
end

init = false;
calibrating = false;
ready = false;
if( webots or darwin) then
  ready = true;
end

smindex = 0;
initToggle = true;


-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();

function update()
  count = count + 1;

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
      
      if( webots ) then
        --BodyFSM.sm:add_event('button');
        GameFSM.sm:set_state('gamePlaying');
      end

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
    print('fps: '..(50 / (unix.time() - tUpdate)));
    tUpdate = unix.time();

    -- update battery indicator
    Body.set_indicator_batteryLevel(Body.get_battery_level());

    -- Debug info
    local ball = wcm.get_ball();
    print('Ball Velocity: ('..ball.vx..', '..ball.vy..')');
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
  print('webots');
  require 'Vision'
  require 'World'

  Vision.entry();
  World.entry();
  -- set game state to playing
  gcm.set_game_state(3);
  while 1 do
    Vision.update();
    World.update_odometry();
    World.update_vision();
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
