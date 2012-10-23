module(..., package.seeall);

require("shm");
require("util");
require("vector");
require('Config');
-- Enable Webots specific
if (string.find(Config.platform.name,'Webots')) then
  webots = true;
end

-- shared properties
shared = {};
shsize = {};

processed_img_width = Config.camera.width;
processed_img_height = Config.camera.height;
if( webots ) then
  processed_img_width = processed_img_width;
  processed_img_height = processed_img_height;
else
  processed_img_width = processed_img_width / 2;
  processed_img_height = processed_img_height / 2;
end

shared.camera = {};
shared.camera.select = vector.zeros(1);
shared.camera.command = vector.zeros(1);
shared.camera.ncamera = vector.zeros(1);

--bodyTilt and height can be changed by sit/stand 
shared.camera.height = vector.zeros(1);
shared.camera.bodyTilt = vector.zeros(1);
shared.camera.bodyHeight = vector.zeros(1);
shared.camera.rollAngle = vector.zeros(1);--how much image is tilted

--Used for monitor to auto-switch yuyv mode
shared.camera.yuyvType = vector.zeros(1);
--Now we use shm to enable broadcasting from test_vision
shared.camera.broadcast = vector.zeros(1);
shared.camera.teambroadcast = vector.zeros(1);

shared.image = {};
shared.image.select = vector.zeros(1);
shared.image.count = vector.zeros(1);
shared.image.time = vector.zeros(1);
shared.image.headAngles = vector.zeros(2);
shared.image.fps = vector.zeros(1);
shared.image.horizonA = vector.zeros(1);
shared.image.horizonB = vector.zeros(1);
shared.image.horizonDir = vector.zeros(4); -- Angle of horizon line rotation

-- 2 bytes per pixel (32 bits describes 2 pixels)
shared.image.yuyv = 2*Config.camera.width*Config.camera.height; 
--Downsampled yuyv
shared.image.yuyv2 = 2*Config.camera.width*Config.camera.height/2/2; 
--Downsampled yuyv 2
shared.image.yuyv3 = 2*Config.camera.width*Config.camera.height/4/4; 

shared.image.width = vector.zeros(1);
shared.image.height = vector.zeros(1);
shared.image.scaleB = vector.zeros(1);

shared.image.labelA = (processed_img_width)*(processed_img_height);
shared.image.labelB = ((processed_img_width)/Config.vision.scaleB)*((processed_img_height)/Config.vision.scaleB);
--shared.image.labelA_obs = (processed_img_width)*(processed_img_height);
--shared.image.labelB_obs = ((processed_img_width)/Config.vision.scaleB)*((processed_img_height)/Config.vision.scaleB);

-- calculate image shm size
shsize.image = (shared.image.yuyv + shared.image.yuyv2+ 
	shared.image.yuyv3+shared.image.labelA + shared.image.labelB 
--  +shared.image.labelA_obs + shared.image.labelB_obs
  ) + 2^16;

--Image field-of-view information
shared.image.fovTL=vector.zeros(2);
shared.image.fovTR=vector.zeros(2);
shared.image.fovBL=vector.zeros(2);
shared.image.fovBR=vector.zeros(2);
shared.image.fovC=vector.zeros(2);

shared.image.learn_lut = vector.zeros(1);

shared.ball = {};
shared.ball.detect = vector.zeros(1);
shared.ball.centroid = vector.zeros(2); --in pixels, (x,y), of camera image
shared.ball.v = vector.zeros(4); --3D position of ball wrt body
shared.ball.r = vector.zeros(1); --distance to ball (planar)
shared.ball.dr = vector.zeros(1);
shared.ball.da = vector.zeros(1);
shared.ball.axisMajor = vector.zeros(1);
shared.ball.axisMinor = vector.zeros(1);

shared.goal = {};
shared.goal.detect = vector.zeros(1);
shared.goal.color = vector.zeros(1);
shared.goal.type = vector.zeros(1);
shared.goal.v1 = vector.zeros(4);
shared.goal.v2 = vector.zeros(4);
shared.goal.postBoundingBox1 = vector.zeros(4);
shared.goal.postBoundingBox2 = vector.zeros(4);
--added for monitor
shared.goal.postCentroid1 = vector.zeros(2);
shared.goal.postAxis1 = vector.zeros(2);
shared.goal.postOrientation1 = vector.zeros(1);
shared.goal.postCentroid2 = vector.zeros(2);
shared.goal.postAxis2 = vector.zeros(2);
shared.goal.postOrientation2 = vector.zeros(1);

--Midfield landmark for non-nao robots
shared.landmark = {};
shared.landmark.detect = vector.zeros(1);
shared.landmark.color = vector.zeros(1);
shared.landmark.v = vector.zeros(4);
shared.landmark.centroid1 = vector.zeros(2);
shared.landmark.centroid2 = vector.zeros(2);
shared.landmark.centroid3 = vector.zeros(2);

--Multiple line detection
max_line_num = 12;

shared.line = {};
shared.line.detect = vector.zeros(1);
shared.line.nLines = vector.zeros(1);
shared.line.v1x = vector.zeros(max_line_num);
shared.line.v1y = vector.zeros(max_line_num);
shared.line.v2x = vector.zeros(max_line_num);
shared.line.v2y = vector.zeros(max_line_num);
shared.line.endpoint11 = vector.zeros(max_line_num);
shared.line.endpoint12 = vector.zeros(max_line_num);
shared.line.endpoint21 = vector.zeros(max_line_num);
shared.line.endpoint22 = vector.zeros(max_line_num);

--for best line
shared.line.v=vector.zeros(4);
shared.line.angle=vector.zeros(a);

--Corner detection
shared.corner = {};
shared.corner.detect = vector.zeros(1);
shared.corner.type = vector.zeros(1);
shared.corner.vc0 = vector.zeros(4);
shared.corner.v10 = vector.zeros(4);
shared.corner.v20 = vector.zeros(4);
shared.corner.v = vector.zeros(4);
shared.corner.v1 = vector.zeros(4);
shared.corner.v2 = vector.zeros(4);

  --[[
  shared.spot = {};
  shared.spot.detect = vector.zeros(1);
  --]]


enable_robot_detection = Config.vision.enable_robot_detection or 0;

shared.robot={};
shared.robot.detect=vector.zeros(1);

if enable_robot_detection>0 then
  --SJ: Don't define the arrays if they are not used 
  --As they will occupy monitor bandwidth
  map_div = Config.vision.robot.map_div;
  --Global map
  shared.robot.lowpoint = vector.zeros(Config.camera.width/Config.vision.scaleB);
  shared.robot.map=vector.zeros(6*4*Config.vision.robot.map_div*Config.vision.robot.map_div); --60 by 40 map
end

enable_freespace_detection = Config.vision.enable_freespace_detection or 0;

shared.freespace = {};
shared.freespace.detect = vector.zeros(1);

shared.boundary = {};
shared.boundary.detect = vector.zeros(1);

if enable_freespace_detection>0 then
  shared.freespace.block = vector.zeros(1);
  shared.freespace.nCol = vector.zeros(1);
  shared.freespace.nRow = vector.zeros(1);
  --shared.freespace.vboundA = vector.zeros(2*Config.camera.width);
  --shared.freespace.pboundA = vector.zeros(2*Config.camera.width);
  --shared.freespace.tboundA = vector.zeros(Config.camera.width);
  shared.freespace.vboundB = vector.zeros(2*Config.camera.width/(Config.vision.scaleB));
  shared.freespace.pboundB = vector.zeros(2*Config.camera.width/(Config.vision.scaleB));
  shared.freespace.tboundB = vector.zeros(Config.camera.width/(Config.vision.scaleB));

  shared.boundary.top = vector.zeros(2*Config.camera.width/Config.vision.scaleB);
  shared.boundary.bottom = vector.zeros(2*Config.camera.width/Config.vision.scaleB);
end

shared.debug = {};
shared.debug.enable_shm_copy = vector.zeros(1);
shared.debug.store_goal_detections = vector.zeros(1);
shared.debug.store_ball_detections = vector.zeros(1);
shared.debug.store_all_images = vector.zeros(1);
shared.debug.message='';

util.init_shm_segment(getfenv(), _NAME, shared, shsize);

debug_message='';

--For vision debugging
function refresh_debug_message()
  if string.len(debug_message)==0 then
    --it is not updated for whatever reason
    --just keep the latest message
  else
    --Update SHM
    set_debug_message(debug_message);
    debug_message='';
  end
end
function add_debug_message(message)
  if string.len(debug_message)>1000 then
    --something is wrong, just reset it 
    debug_message='';
  end
  debug_message=debug_message..message;
end
