module(... or "", package.seeall)

-- Add the required paths
--local cwd = unix.getcwd();
local cwd = os.getenv('PWD');
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
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path; 

require('unix')
require('vcm')
require('gcm')
require('wcm')
require('mcm')

require('Body')

require('GameControl')
require('Comm')

require('Vision')

require('World')
require('Team')

count = 0;
nProcessedImages = 0;
tUpdate = unix.time();

function entry()
  World.entry();
  Team.entry();

  Vision.entry();
  GameControl.entry();
end

function update()
  count = count + 1;
  tstart = unix.time();

  -- update game control
  if (count % 30 == 0) then
    GameControl.update();
  end

  -- update vision 
  imageProcessed = Vision.update();

  World.update_odometry();

  -- update localization
  if imageProcessed then
    nProcessedImages = nProcessedImages + 1;
    World.update_vision();
    Team.update();

    if (nProcessedImages % 50 == 0) then
      print('fps: '..(50 / (unix.time() - tUpdate)));
      tUpdate = unix.time();
    end
  end
end

-- exit 
function exit()
  GameControl.exit();
  Vision.exit();
  Team.exit();
  World.exit();
end

