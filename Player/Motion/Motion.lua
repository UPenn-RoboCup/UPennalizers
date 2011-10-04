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
bodyTilt = walk.bodyTilt or 0;

-- For still time measurement (dodgeball)
stillTime = 0;
stillTime0 = 0;
wasStill = false;

-- Ultra Sound Processor
UltraSound.entry();

function entry()
  sm:entry()
end

function update()
  -- update us
  UltraSound.update();

  -- check if the robot is falling
  local imuAngle = Body.get_sensor_imuAngle();
  local maxImuAngle = math.max(math.abs(imuAngle[1]), math.abs(imuAngle[2]-bodyTilt));
  if (maxImuAngle > 40*math.pi/180) then
    sm:add_event("fall");
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

