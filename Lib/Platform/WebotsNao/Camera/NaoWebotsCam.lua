module(..., package.seeall);
require('controller');
require('carray');
require('ImageProc');

controller.wb_robot_init();
timeStep = controller.wb_robot_get_basic_time_step();

-- Get webots tags:
tags = {};
tags.camera = controller.wb_robot_get_device("camera");
controller.wb_camera_enable(tags.camera, timeStep);

positionTop = 0;
positionBottom = 0.70;
tags.cameraSelect = controller.wb_robot_get_device("CameraSelect");
controller.wb_servo_set_position(tags.cameraSelect, positionBottom);
controller.wb_servo_enable_position(tags.cameraSelect, timeStep);

controller.wb_robot_step(timeStep);

height = controller.wb_camera_get_height(tags.camera);
width = controller.wb_camera_get_width(tags.camera);
image = carray.cast(controller.wb_camera_get_image(tags.camera),
		    'c', 3*height*width);

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
  return ImageProc.rgb_to_yuyv(carray.pointer(image), width, height);
end

function get_labelA(lut)
  --rgb2label
  return ImageProc.rgb_to_label(carray.pointer(image), lut, width, height);

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

function get_camera_position()
  return controller.wb_servo_get_position(tags.cameraSelect);
end

function select_camera(bottom)
  if (bottom ~= 0) then
    controller.wb_servo_set_position(tags.cameraSelect, positionBottom);
  else
    controller.wb_servo_set_position(tags.cameraSelect, positionTop);
  end
end

function get_select()
  if (controller.wb_servo_get_position(tags.cameraSelect) < .5*positionBottom) then
    --top camera
    return 0;
  else
    return 1;
  end
end
