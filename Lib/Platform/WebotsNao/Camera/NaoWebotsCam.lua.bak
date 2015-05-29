module(..., package.seeall);
require('controller');
require('carray');
require('ImageProc');

controller.wb_robot_init();
timeStep = controller.wb_robot_get_basic_time_step();

-- Get webots tags:
tags = {};
tags.cameraTop = controller.wb_robot_get_device("CameraTop");
tags.cameraBottom = controller.wb_robot_get_device("CameraBottom");
tags.camera = tags.cameraTop
tags.camera_select = 0


controller.wb_camera_enable(tags.cameraTop, timeStep);
controller.wb_camera_enable(tags.cameraBottom, timeStep);

controller.wb_robot_step(timeStep);

height = controller.wb_camera_get_height(tags.cameraTop);
width = controller.wb_camera_get_width(tags.cameraTop);

mycount = 0;

function set_param()
end

function get_param()
  return 0;
end

function get_height()
  return height;
end

function get_width()
  return width;
end

function get_image()
  --rgb2yuyv
  local image = controller.to_rgb( tags.camera )
  return ImageProc.rgb_to_yuyv( image, width, height);
end

function get_labelA(lut)
  --rgb2label
	local image = controller.to_rgb( tags.camera )
	return ImageProc.rgb_to_label( image, lut, width, height );
end

function get_camera_status()
  status = {};
  status.select = get_select();
  status.count = mycount;
  status.time = unix.time();
  status.joint = vector.zeros(20);
  tmp = Body.get_head_position();
  status.joint[1],status.joint[2] = tmp[1], tmp[2];
  mycount = mycount + 1;
  return status;
end

function select_camera(bottom)
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
