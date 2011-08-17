module(..., package.seeall);

require('shm');
require('util');
require('vector');
require('Config');

-- shared properties
shared = {};
shsize = {};

shared.walk = {};
shared.walk.bodyOffset = vector.zeros(3);
shared.walk.tStep = vector.zeros(1);
shared.walk.bodyHeight = vector.zeros(1);
shared.walk.stepHeight = vector.zeros(1);
shared.walk.footY = vector.zeros(1);
shared.walk.supportX = vector.zeros(1);
shared.walk.supportY = vector.zeros(1);
shared.walk.uLeft = vector.zeros(3);
shared.walk.uRight = vector.zeros(3);
-- How long have we been still for?
shared.walk.stillTime = vector.zeros(1);

shared.us = {};
shared.us.left = vector.zeros(10);
shared.us.right = vector.zeros(10);
shared.us.obstacles = vector.zeros(2);
shared.us.free = vector.zeros(2);
shared.us.dSum = vector.zeros(2);
shared.us.distance = vector.zeros(2);

util.init_shm_segment(getfenv(), _NAME, shared, shsize);


-- helper functions

function get_odometry(u0)
  if (not u0) then
    u0 = vector.new({0, 0, 0});
  end
  local uFoot = util.se2_interpolate(.5, get_walk_uLeft(), get_walk_uRight());
  return util.pose_relative(uFoot, u0), uFoot;
end

