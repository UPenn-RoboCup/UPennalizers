module(... or "",package.seeall)
cwd = os.getenv('PWD')
require('init')

require('unix')
require('vcm')
require('gcm')
require('wcm')
require('mcm')

require('World')
require('Team');
require('GameControl');

use_gps_only = Config.use_gps_only or 0;
local Vision
local vision_thread = {}

count = 0;
nProcessedImages = 0;
tUpdate = unix.time();

function ball_decision(cidx, detect)
--  print(cidx)
  if detect == 0 then return vcm.set_ball_detect(0);end
  vcm.set_ball_detect(detect)
  vcm.set_ball_color_count(vcm['get_ball'..cidx..'_color_count']())
  vcm.set_ball_centroid(vcm['get_ball'..cidx..'_centroid']())
  vcm.set_ball_axisMajor(vcm['get_ball'..cidx..'_axisMajor']())
  vcm.set_ball_axisMinor(vcm['get_ball'..cidx..'_axisMinor']())
  vcm.set_ball_v( vcm['get_ball'..cidx..'_v']())
  vcm.set_ball_r( vcm['get_ball'..cidx..'_r']())
  vcm.set_ball_dr(vcm['get_ball'..cidx..'_dr']())
  vcm.set_ball_da(vcm['get_ball'..cidx..'_da']())
end


function entry()
  if use_gps_only==0 then  
    Vision = require('Vision_webots')  
    vision_thread[1] = Vision.entry(1)
    vision_thread[2] = Vision.entry(2)
  else
    require('Camera')--turn on camera feed 
    Vision = require('Vision_webots_gps')
    Vision.entry()
  end
  World.entry();
  Team.entry();
  GameControl.entry();  
end

function update()
  count = count + 1;
  tstart = unix.time();
    
  if use_gps_only==0 then  
    --We just run two image processing in serial
    vision_thread[1]:update()
    vision_thread[2]:update()
    
    --And we arbitrate the detection here
    local detect1 = vcm.get_ball1_detect();
    local detect2 = vcm.get_ball2_detect();
    if detect2 == 1 then  ball_decision(2, detect2) --Bottom camera
    elseif detect1 == 1 then ball_decision(1, detect1) --Top camera
    else ball_decision(0, 0) end --No balls
  else
    Vision.update()
  end
  nProcessed = nProcessed + 1  
  World.update_odometry();
  World.update_vision()

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