module(..., package.seeall);

require('vcm');
require('vector');

function init()
end

function set_param()
end

function get_param()
  return 0;
end

function get_height()
  return 480;
end

function get_width()
  return 640;
end

function get_image(cidx)
  return vcm["get_image"..cidx.."_yuyv"]();
end

