module(... or "",package.seeall)
--TODO: what about coroutine instead running to files?
cwd = os.getenv('PWD')
require('init')

require('unix')
require('vcm')

local Vision = require 'Vision_thread'

comm_inited = false;
vcm.set_camera_teambroadcast(0);
--Now vcm.get_camera_teambroadcast() determines 
--Whether we use wired monitoring comm or wireless team comm

count = 0;
nProcessedImages = 0;
tUpdate = unix.time();

enable_online_colortable_learning = Config.vision.enable_online_colortable_learning or 0;
enable_freespace_detection = Config.vision.enable_freespace_detection or 0;

if (string.find(Config.platform.name,'Webots')) then
  webots = true;
end

local Vision_thread = {}
function entry(nc)
  Vision_thread[nc] = Vision.entry(nc)
end

function update(nc)
  count = count + 1;
  tstart = unix.time();

  -- update vision 
  local imageProcessed = false
  imageProcessed = Vision_thread[nc]:update();
  --World.update_odometry();
  
  -- update localization
  if imageProcessed then
    nProcessedImages = nProcessedImages + 1;
    if (nProcessedImages % 50 == 0) then
      if not webots then
        print('fps: '..(50 / (unix.time() - tUpdate)));
        tUpdate = unix.time();
      end
    end
  end
end

-- exit 
function exit()
  Vision.exit();
end

