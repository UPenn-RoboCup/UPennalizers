module(..., package.seeall);
require('controller');
require('carray');
require('ImageProc');

height = 240;
width = 320;
image = carray.new('c', 3*2*height*width);

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
  return carray.pointer(image);
end

function get_camera_status()
  status = {};
  status.select = 0;
  status.count = mycount;
  status.time = unix.time();
  status.joint = vector.zeros(22);
  status.joint[1],status.joint[2] = tmp[1], tmp[2];
  mycount = mycount + 1;
  return status;
end

function get_camera_position()
  return 0;
end

function select_camera(bottom)
end

function get_select()
  return 0;
end
