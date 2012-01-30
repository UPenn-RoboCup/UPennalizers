module(..., package.seeall);

require('Body')
require('UltraSound')
require('fsm')
require('vector')
require('mcm')
require('gcm')

require('relax')
require('stance')
require('nullstate')
require('walk')
require('sit')
require('standstill') -- This makes torso straight (for webots robostadium)

require('falling')
require('standup')
require('kick')

sm = fsm.new(relax);
sm:add_state(stance);
sm:add_state(nullstate);
sm:add_state(walk);
sm:add_state(sit);
sm:add_state(standup);
sm:add_state(falling);
sm:add_state(kick);
sm:add_state(standstill);


sm:set_transition(sit, 'done', relax);
sm:set_transition(sit, 'standup', stance);

sm:set_transition(relax, 'standup', stance);
sm:set_transition(relax, 'sit', sit);

sm:set_transition(stance, 'done', walk);
sm:set_transition(stance, 'sit', sit);

-- nullstate goes to walk
--sm:set_transition(nullstate, 'button', walk); 
--sm:set_transition(nullstate, 'walk', walk); 
--sm:set_transition(nullstate, 'sit', sit);

sm:set_transition(walk, 'sit', sit);
sm:set_transition(walk, 'stance', stance);
sm:set_transition(walk, 'standstill', standstill);

--standstill makes the robot stand still with 0 bodytilt (for webots)
sm:set_transition(standstill, 'stance', stance);
sm:set_transition(standstill, 'walk', stance);

-- falling behaviours
sm:set_transition(walk, 'fall', falling);
sm:set_transition(falling, 'done', standup);
sm:set_transition(standup, 'done', stance);
sm:set_transition(standup, 'fail', standup);

-- kick behaviours
sm:set_transition(walk, 'kick', kick);
sm:set_transition(kick, 'done', walk);

-- set state debug handle to shared memory settor
sm:set_state_debug_handle(gcm.set_fsm_motion_state);

-- TODO: fix kick->fall transition
--sm:set_transition(kick, 'fall', falling);

--added for OP... bodyTilt consideration for detecting falldown
bodyTilt = Config.walk.bodyTilt or 0;

--OP requires large fall angel detection threshold
--Default value is 30 degree
fallAngle = Config.walk.fallAngle or 30*math.pi/180;

-- For still time measurement (dodgeball)
stillTime = 0;
stillTime0 = 0;
wasStill = false;

-- Ultra Sound Processor
UltraSound.entry();

function entry()
  sm:entry()
  mcm.set_walk_isFallDown(0);
end

function update()
  -- update us
  UltraSound.update();

  -- check if the robot is falling
  --TODO: Imu angle should be in RPY
  --Counter-clockwise rotation in X,Y,Z axis
  --Current imuAngle is inverted

  local imuAngle = Body.get_sensor_imuAngle();

  --[[
  local imuGyrRPY = Body.get_sensor_imuGyrRPY();
  print("Imu RPY:",unpack(vector.new(imuAngle)*180/math.pi))
  print("Imu Gyr RPY:",unpack(vector.new(imuGyrRPY)*180/math.pi))
  --]]

  local maxImuAngle = math.max(math.abs(imuAngle[1]), math.abs(imuAngle[2]-bodyTilt));
  if (maxImuAngle > fallAngle) then
    sm:add_event("fall");
    mcm.set_walk_isFallDown(1); --Notify world to reset heading 
  else
    mcm.set_walk_isFallDown(0); 
  end

  -- Keep track of how long we've been still for
  if( walk.still and not wasStill ) then
    stillTime0 = Body.get_time();
    stillTime = 0;
  elseif( walk.still and wasStill) then
    stillTime = Body.get_time() - stillTime0;
  else
    stillTime = 0;
  end
  -- Update our last still measurement
  wasStill = walk.still;

  sm:update();

  -- update shm
  update_shm();
end

function exit()
  sm:exit();
end

function event(e)
  sm:add_event(e);
end

function update_shm()
  -- Update the shared memory
  mcm.set_walk_bodyOffset(walk.get_body_offset());
  mcm.set_walk_uLeft(walk.uLeft);
  mcm.set_walk_uRight(walk.uRight);

  mcm.set_us_left(UltraSound.left);
  mcm.set_us_right(UltraSound.right);

  mcm.set_walk_stillTime( stillTime );
end

