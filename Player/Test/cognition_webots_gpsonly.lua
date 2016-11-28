module(... or "",package.seeall)
cwd = os.getenv('PWD')
require('init')

require('unix')
require('vcm')
require('gcm')
require('wcm')
require('mcm')
require('Body')
Vision = require('Vision_webots_gps')
require('World')

require('Team');
require('GameControl');



comm_inited = false;
enable_team = Config.vision.enable_team_broadcast or 0;
vcm.set_camera_teambroadcast(enable_team);
vcm.set_camera_broadcast(0);
--Now vcm.get_camera_teambroadcast() determines 
--Whether we use wired monitoring comm or wireless team comm

count = 0;
nProcessedImages = 0;
tUpdate = unix.time();

if (string.find(Config.platform.name,'Webots')) then
  webots = true;
end

function entry()
  World.entry();
  Vision.entry();
  Team.entry();
  GameControl.entry();
end

function update()
  count = count + 1;
  tstart = unix.time();
  -- update vision 
  imageProcessed = Vision.update();

  World.update_odometry();

  -- update localization
  if imageProcessed then
    nProcessedImages = nProcessedImages + 1;
    World.update_vision();
  end

  GameControl.update();
  if nProcessedImages % 3 ==0 then
    --10 fps team update
    Team.update();
  end
end

-- exit 
function exit()
  Team.exit();
  GameControl.exit();
  Vision.exit();
  World.exit();
end

