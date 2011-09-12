module(..., package.seeall);

require("shm");
require("util");
require("vector");
require('Config');

-- shared properties
shared = {};
shsize = {};

-- Subsambling means half width, and process every other line in the ImageProc
--TODO:
processed_img_width = Config.camera.width;
processed_img_height = Config.camera.height;
--if( Config.vision.subsampling==1 ) then
processed_img_width = processed_img_width / 2;
processed_img_height = processed_img_height / 2;
--end

shared.camera = {};
shared.camera.select = vector.zeros(1);
shared.camera.command = vector.zeros(1);

shared.image = {};
shared.image.select = vector.zeros(1);
shared.image.count = vector.zeros(1);
shared.image.time = vector.zeros(1);
shared.image.headAngles = vector.zeros(2);
shared.image.fps = vector.zeros(1);
shared.image.horizonA = vector.zeros(1);
shared.image.horizonB = vector.zeros(1);
--shared.image.yuyv = 2*Config.camera.width*Config.camera.height; -- 2 bytes per pixel (32 bits describes 2 pixels)
shared.image.width = vector.zeros(1);
shared.image.height = vector.zeros(1);
--shared.image.labelA = (processed_img_width)*(processed_img_height);
--shared.image.labelB = ((processed_img_width)/Config.vision.scaleB)*((processed_img_height)/Config.vision.scaleB);
-- calculate image shm size
shsize.image = (shared.image.yuyv + shared.image.labelA + shared.image.labelB) + 2^16;

shared.ball = {};
shared.ball.detect = vector.zeros(1);
shared.ball.centroid = vector.zeros(2); --in pixels, (x,y), of camera image
shared.ball.v = vector.zeros(4); --3D position of ball wrt body
shared.ball.r = vector.zeros(1); --distance to ball (planar)
shared.ball.dr = vector.zeros(1);
shared.ball.da = vector.zeros(1);
shared.ball.axisMajor = vector.zeros(1);
shared.ball.axisMinor = vector.zeros(1);
shsize.image = (shared.image.yuyv + shared.image.labelA + shared.image.labelB) + 2^16;


shared.goal = {};
shared.goal.detect = vector.zeros(1);
shared.goal.color = vector.zeros(1);
shared.goal.type = vector.zeros(1);
shared.goal.v1 = vector.zeros(4);
shared.goal.v2 = vector.zeros(4);
shared.goal.postBoundingBox1 = vector.zeros(4);
shared.goal.postBoundingBox2 = vector.zeros(4);

shared.line = {};
shared.line.detect = vector.zeros(1);
shared.line.v = vector.zeros(4);
shared.line.angle = vector.zeros(1);
shared.line.vcentroid = vector.zeros(4);
shared.line.vendpoint = vector.zeros(4);
--[[
shared.spot = {};
shared.spot.detect = vector.zeros(1);
--]]
shared.debug = {};
shared.debug.enable_shm_copy = vector.zeros(1);
shared.debug.store_goal_detections = vector.zeros(1);
shared.debug.store_ball_detections = vector.zeros(1);
shared.debug.store_all_images = vector.zeros(1);

util.init_shm_segment(getfenv(), _NAME, shared, shsize);

