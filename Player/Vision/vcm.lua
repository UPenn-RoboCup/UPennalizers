module(..., package.seeall);

require("shm");
require("util");
require("vector");
require('Config');
-- Enable Webots specific
if (string.find(Config.platform.name,'Webots')) then
  webots = true;
end

enable_robot_detection = Config.vision.enable_robot_detection or 0;
enable_freespace_detection = Config.vision.enable_freespace_detection or 0;

-- shared properties
shared = {};
shsize = {};

local cw, ch = Config.camera.width, Config.camera.height


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

shared.camera.reload_LUT = vector.zeros(1);
shared.camera.learned_new_lut = vector.zeros(1);
shared.camera.lut_filename = '';

local images = {}
local image = {}
image.select = vector.zeros(1);
image.count = vector.zeros(1);
image.time = vector.zeros(1);
image.headAngles = vector.zeros(2);
image.fps = vector.zeros(1);
image.horizonA = vector.zeros(1);
image.horizonB = vector.zeros(1);
image.horizonDir = vector.zeros(4); -- Angle of horizon line rotation

-- 2 bytes per pixel (32 bits describes 2 pixels)
local img_width, img_height
if type(cw)=='number' then
  image.yuyv = 2*cw*ch; 
  image.yuyv2 = 2*cw*ch/2/2;
  img_width = cw
  img_height = ch
else
  -- assume table with each element for the camera
  image.yuyv = 2*cw[1]*ch[1];
  image.yuyv2 = 2*cw[1]*ch[1]/2/2;
  img_width = cw[1]
  img_height = ch[1]
end
--print('im1',img_width,img_height)

local sA, sB = Config.vision.scaleA, Config.vision.scaleB
if type(sA)=='number' then
  image.labelA = (img_width/sA)*(img_height/sA);
  image.labelB = image.labelA / (sB*sB)
else
  -- assume table with each element for the camera
  image.labelA = (img_width/sA[1])*(img_height/sA[1]);
  image.labelB = image.labelA / (sB[1]*sB[1])
end


image.width = vector.zeros(1);
image.height = vector.zeros(1);
image.scaleB = vector.zeros(1);

--Image field-of-view information
image.fovTL=vector.zeros(2);
image.fovTR=vector.zeros(2);
image.fovBL=vector.zeros(2);
image.fovBR=vector.zeros(2);
image.fovC=vector.zeros(2);

images[1] = image


if webots then --Webots uses double the resolution for labelA!
  print("orig image1 size:",img_width,img_height)
end

-- Next cam
local image2 = {}
image2.select = vector.zeros(1);
image2.count = vector.zeros(1);
image2.time = vector.zeros(1);
image2.headAngles = vector.zeros(2);
image2.fps = vector.zeros(1);
image2.horizonA = vector.zeros(1);
image2.horizonB = vector.zeros(1);
image2.horizonDir = vector.zeros(4); -- Angle of horizon line rotation

-- 2 bytes per pixel (32 bits describes 2 pixels)
local cw, ch = Config.camera.width, Config.camera.height
if type(cw)=='number' then
  image2.yuyv = 2*cw*ch; 
  image2.yuyv2 = 2*cw*ch/2/2;
  img_width = cw
  img_height = ch
else
  -- assume table with each element for the camera
  image2.yuyv = 2*cw[2]*ch[2];
  image2.yuyv2 = 2*cw[2]*ch[2]/2/2;
  img_width = cw[2]
  img_height = ch[2]
end
print('im2',img_width,img_height)

local sA, sB = Config.vision.scaleA, Config.vision.scaleB
if type(sA)=='number' then
  image2.labelA = (img_width/sA)*(img_height/sA);
  image2.labelB = image.labelA / (sB*sB)
else
  -- assume table with each element for the camera
  image2.labelA = (img_width/sA[2])*(img_height/sA[2]);
  image2.labelB = image.labelA / (sB[2]*sB[2])
end

image2.width = vector.zeros(1);
image2.height = vector.zeros(1);
image2.scaleB = vector.zeros(1);

--image2 field-of-view information
image2.fovTL=vector.zeros(2);
image2.fovTR=vector.zeros(2);
image2.fovBL=vector.zeros(2);
image2.fovBR=vector.zeros(2);
image2.fovC=vector.zeros(2);

images[2] = image2



if webots then --Webots uses double the resolution for labelA!
  print("orig image2 size:",img_width,img_height)
end





local ball = {};
ball.detect = vector.zeros(1);
ball.color_count = vector.zeros(1);
ball.centroid = vector.zeros(2); --in pixels, (x,y), of camera image
ball.v = vector.zeros(4); --3D position of ball wrt body
ball.r = vector.zeros(1); --distance to ball (planar)
ball.dr = vector.zeros(1);
ball.da = vector.zeros(1);
ball.axisMajor = vector.zeros(1);
ball.axisMinor = vector.zeros(1);

local goal = {};
goal.detect = vector.zeros(1);
goal.color = vector.zeros(1);
goal.type = vector.zeros(1);
goal.v1 = vector.zeros(4);
goal.v2 = vector.zeros(4);
goal.postBoundingBox1 = vector.zeros(4);
goal.postBoundingBox2 = vector.zeros(4);
 --added for monitor
goal.postCentroid1 = vector.zeros(2);
goal.postAxis1 = vector.zeros(2);
goal.postOrientation1 = vector.zeros(1);
goal.postCentroid2 = vector.zeros(2);
goal.postAxis2 = vector.zeros(2);
goal.postOrientation2 = vector.zeros(1);

---Midfield landmark for non-nao robots
local landmark = {};
landmark.detect = vector.zeros(1);
landmark.color = vector.zeros(1);
landmark.v = vector.zeros(4);
landmark.centroid1 = vector.zeros(2);
landmark.centroid2 = vector.zeros(2);
landmark.centroid3 = vector.zeros(2);

--Multiple line detection
max_line_num = 12;

local line = {};
line.detect = vector.zeros(1);
line.nLines = vector.zeros(1);
line.v1x = vector.zeros(max_line_num);
line.v1y = vector.zeros(max_line_num);
line.v2x = vector.zeros(max_line_num);
line.v2y = vector.zeros(max_line_num);
line.endpoint11 = vector.zeros(max_line_num);
line.endpoint12 = vector.zeros(max_line_num);
line.endpoint21 = vector.zeros(max_line_num);
line.endpoint22 = vector.zeros(max_line_num);
line.xMean = vector.zeros(max_line_num);
line.yMean = vector.zeros(max_line_num);
--for best line
line.v=vector.zeros(4);
line.angle=vector.zeros(a);

--Corner detection
local corner = {};
corner.detect = vector.zeros(1);
corner.type = vector.zeros(1);
corner.vc0 = vector.zeros(4);
corner.v10 = vector.zeros(4);
corner.v20 = vector.zeros(4);
corner.v = vector.zeros(4);
corner.v1 = vector.zeros(4);
corner.v2 = vector.zeros(4);

local robot={};
robot.detect=vector.zeros(1);
if enable_robot_detection>0 then
  --SJ: Don't define the arrays if they are not used 
  --As they will occupy monitor bandwidth
  map_div = Config.vision.robot.map_div;
  --Global map
  robot.lowpoint = vector.zeros(Config.camera.width/Config.vision.scaleB);
  robot.map=vector.zeros(6*4*Config.vision.robot.map_div*Config.vision.robot.map_div); --60 by 40 map
end

local debug = {};
debug.enable_shm_copy = vector.zeros(1);
debug.store_goal_detections = vector.zeros(1);
debug.store_ball_detections = vector.zeros(1);
debug.store_all_images = vector.zeros(1);
debug.message='';

-- for arbitrator
shared.ball = ball
shared.goal = goal
shared.line = line
shared.landmark = landmark
shared.corner = corner
shared.robot = robot 
shared.debug = debug


for nc = 1, Config.camera.ncamera do
  shared['image'..nc] = images[nc]
  -- calculate image shm size
  local im = images[nc]
  shsize['image'..nc] = (im.yuyv + im.yuyv2 + im.labelA + im.labelB) + 2^16;

  shared['debug'..nc] = debug
  shared['ball'..nc] = ball
  --shared['goal'..nc] = goal
  --shared['landmark'..nc] = landmark
  --shared['line'..nc] = line
  --shared['corner'..nc] = corner
  --shared['robot'..nc] = robot
end


util.init_shm_segment(getfenv(), _NAME, shared, shsize);

debug_message='';
--
----For vision debugging
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

function bboxStats(color, bboxB, rollAngle, scale)
  scale = scale or scaleB[1];
  local bboxA = {};
  bboxA[1] = scale*bboxB[1];
  bboxA[2] = scale*bboxB[2] + scale - 1;
  bboxA[3] = scale*bboxB[3];
  bboxA[4] = scale*bboxB[4] + scale - 1;
  if rollAngle then
 --hack: shift boundingbox 1 pix helps goal detection
 --not sure why this thing is happening...

--    bboxA[1]=bboxA[1]+1;
      bboxA[2]=bboxA[2]+1;

--    return ImageProc.tilted_color_stats(labelA.data, labelA.m, labelA.n, color, bboxA,rollAngle);
--  else
--    return ImageProc.color_stats(labelA.data, labelA.m, labelA.n, color, bboxA);
  end
  return bboxA
end

function bboxB2A(bboxB, scaleB)
  bboxA = {};
  bboxA[1] = scaleB*bboxB[1];
  bboxA[2] = scaleB*bboxB[2] + scaleB - 1;
  bboxA[3] = scaleB*bboxB[3];
  bboxA[4] = scaleB*bboxB[4] + scaleB - 1;
  return bboxA;
end

function bboxArea(bbox)
  return (bbox[2] - bbox[1] + 1) * (bbox[4] - bbox[3] + 1);
end



