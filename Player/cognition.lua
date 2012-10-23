module(... or "", package.seeall)

-- Add the required paths
cwd = '.';
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
require('Vision')
require('World')
require('Detection') 
comm_inited = false;
vcm.set_camera_teambroadcast(0);
vcm.set_camera_broadcast(0);
--Now vcm.get_camera_teambroadcast() determines 
--Whether we use wired monitoring comm or wireless team comm

count = 0;
nProcessedImages = 0;
tUpdate = unix.time();

if (string.find(Config.platform.name,'Webots')) then
  webots = true;
end

function broadcast()
  broadcast_enable = vcm.get_camera_broadcast();
  if broadcast_enable>0 then
    if broadcast_enable==1 then 
      --Mode 1, send 1/4 resolution, labeB, all info
      imgRate = 1; --30fps
    elseif broadcast_enable==2 then 
      --Mode 2, send 1/2 resolution, labeA, labelB, all info
      imgRate = 2; --15fps
    else
      --Mode 3, send 1/2 resolution, info for logging
      imgRate = 1; --30fps
    end
    -- Always send non-image data
    Broadcast.update(broadcast_enable);
    -- Send image data every so often
    if nProcessedImages % imgRate ==0 then
      Broadcast.update_img(broadcast_enable);    
    end
    --Reset this flag at every broadcast
    --To prevent monitor running during actual game
    vcm.set_camera_broadcast(0);
  end
end

function entry()
  World.entry();
  Vision.entry();
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

    if (nProcessedImages % 200 == 0) then
      if not webots then
        print('fps: '..(200 / (unix.time() - tUpdate)));
        Detection.print_time(); 
        tUpdate = unix.time();
      end
    end
  end
 
  if not comm_inited and 
    (vcm.get_camera_broadcast()>0 or
     vcm.get_camera_teambroadcast()>0) then
    if vcm.get_camera_teambroadcast()>0 then 
      require('Team');
      require('GameControl');
      Team.entry();
      GameControl.entry();
      print("Starting to send wireless team message..");
    else
      require('Broadcast');
      print("Starting to send wired monitor message..");
    end
    comm_inited = true;
  end

  if comm_inited and imageProcessed then
    if vcm.get_camera_teambroadcast()>0 then 
      GameControl.update();
      if nProcessedImages % 3 ==0 then
	--10 fps team update
        Team.update();
      end
    else
      broadcast();
    end
  end
end

-- exit 
function exit()
  if vcm.get_camera_teambroadcast()>0 then 
    Team.exit();
    GameControl.exit();
  end
  Vision.exit();
  World.exit();
end

