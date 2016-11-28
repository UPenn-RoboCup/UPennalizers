--module(..., package.seeall);
local NaoWebotsCam = { } 

require('controller');
require('carray');
require('ImageProc');

controller.wb_robot_init();
timeStep = controller.wb_robot_get_basic_time_step()
timeStepCamera = Config.camera_tStep or timeStep

-- Get webots tags: 
tags = { } ;
tags.cameraTop = controller.wb_robot_get_device("CameraTop");
tags.cameraBottom = controller.wb_robot_get_device("CameraBottom");
tags.camera = tags.cameraTop
tags.camera_select = 0

controller.wb_camera_enable(tags.cameraTop, timeStepCamera);
controller.wb_camera_enable(tags.cameraBottom, timeStepCamera);

controller.wb_robot_step(timeStep);

height = controller.wb_camera_get_height(tags.cameraTop);
width = controller.wb_camera_get_width(tags.cameraTop);

mycount = 0;

local function set_param(self)
end

local function get_param(self)
	return 0;
end

local function get_height(self)
	return height;
end

local function get_width(self)
	return width;
end

local function get_image(self)
	self: select_camera(self.select_cam)
	--rgb2yuyv
	local image = controller.to_rgb( tags.camera )
	return ImageProc.rgb_to_yuyv( image, width, height);
end

local function get_labelA(self, lut)
	self: select_camera(self.select_cam)
	--rgb2label
	local image = controller.to_rgb( tags.camera )
	return ImageProc.rgb_to_label( image, lut, width, height );
end

function get_camera_status()
	status = { } ;
	status.select = get_select();
	status.count = mycount;
	status.time = unix.time();
	status.joint = vector.zeros(20);
	tmp = Body.get_head_position();
	status.joint[1],status.joint[2] = tmp[1], tmp[2];
	mycount = mycount +  1;
	return status;
end

local function select_camera(self, bottom)
	if (bottom ~= 0) then

		tags.camera = tags.cameraBottom
		tags.camera_select = 1
	else
		tags.camera = tags.cameraTop
		tags.camera_select = 0
	end
end

function get_select()
	return tags.camera_select
end

NaoWebotsCam.init = function(cam_idx)
local camera = { } 
-- 0:  top 1:  bottom
camera.select_cam = cam_idx-1
camera.height = height
camera.width = width
-- Methods
camera.get_height = get_height
camera.get_width = get_width
camera.get_param = get_param
camera.set_param = set_param
camera.get_image = get_image
camera.select_camera = select_camera
camera.get_labelA = get_labelA

return camera
end

return NaoWebotsCam
