module(..., package.seeall);

require('vcm');
require('vector');

function set_param()
end

function get_param()
  return 0;
end

function get_height()
  return vcm.get_image_height();
end

function get_width()
  return vcm.get_image_width();
end

function get_image()
  return vcm.get_image_yuyv();
end

function get_camera_status()
  status = {};
  status.select = get_select();
  status.count = vcm.get_image_count();
  status.time = vcm.get_image_time();
  status.joint = vector.zeros(20);
	headAngles = vcm.get_image_headAngles();
  status.joint[1] = headAngles[1];
  status.joint[2] = headAngles[2];

  return status;
end

function select_camera(bottom)
  -- do nothing
end

function get_select()
  return vcm.get_image_select();
end
