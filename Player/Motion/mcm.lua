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
shared.walk.vel = vector.zeros(3);

--Robot specific calibration values
shared.walk.footXComp = vector.zeros(1);
shared.walk.kickXComp = vector.zeros(1);
shared.walk.headPitchBiasComp = vector.zeros(1);


-- How long have we been still for?
shared.walk.stillTime = vector.zeros(1);

-- Is the robot moving?
shared.walk.isMoving = vector.zeros(1);

--If the robot carries a ball, don't move arms
shared.walk.isCarrying = vector.zeros(1);
shared.walk.bodyCarryOffset = vector.zeros(3);

--To notify world to reset heading
shared.walk.isFallDown = vector.zeros(1);
shared.walk.isGetupDone = vector.zeros(1);

--Is the robot spinning in bodySearch?
shared.walk.isSearching = vector.zeros(1);

--Is the robot doing the ZMP step kick?
shared.walk.isStepping = vector.zeros(1);



--Motion status feedback variables (for motion monitor)
shared.feedback={}
shared.feedback.t = vector.zeros(1)
shared.feedback.support = vector.zeros(2) --pitch roll
shared.feedback.imuAngle = vector.zeros(2) --pitch roll
shared.feedback.imuGyro = vector.zeros(2) --pitch roll
shared.feedback.errorLeftJE = vector.zeros(4) --xy pitch roll
shared.feedback.errorRightJE = vector.zeros(4) --xy pitch roll
shared.feedback.errorJE = vector.zeros(4) --xy pitch roll
shared.feedback.torsoTarget = vector.zeros(2) --pitch roll
shared.feedback.torsoTargetFiltered = vector.zeros(2) --pitch roll



shared.us = {};
shared.us.left = vector.zeros(10);
shared.us.right = vector.zeros(10);
shared.us.obstacles = vector.zeros(2);
shared.us.free = vector.zeros(2);
shared.us.dSum = vector.zeros(2);
shared.us.distance = vector.zeros(2);
shared.us.frontobs = vector.zeros(1);

shared.motion = {};
--Should we perform fall check
shared.motion.fall_check = vector.zeros(1);


util.init_shm_segment(getfenv(), _NAME, shared, shsize);


-- helper functions

---
--Get the distance moved in one step
--@param u0 The previous position
--@return The Distance moved with the current walk plan
--@return The global position of the planned step
function get_odometry(u0)
  if (not u0) then
    u0 = vector.new({0, 0, 0});
  end
  local uFoot = util.se2_interpolate(.5, get_walk_uLeft(), get_walk_uRight());
  return util.pose_relative(uFoot, u0), uFoot;
end

--Now those parameters are dynamically adjustable
footX = Config.walk.footX or 0;
kickX = Config.walk.kickX or 0;
footXComp = Config.walk.footXComp or 0;
kickXComp = Config.walk.kickXComp or 0;
headPitchBias= Config.walk.headPitchBias or 0;
headPitchBiasComp= Config.walk.headPitchBiasComp or 0;

set_walk_footXComp(footXComp);
set_walk_kickXComp(kickXComp);
set_walk_headPitchBiasComp(headPitchBiasComp);

function get_footX()
  return get_walk_footXComp() + footX;
end

function get_kickX()
  return get_walk_kickXComp();
end

function get_headPitchBias()
  return get_walk_headPitchBiasComp()+headPitchBias;
end
