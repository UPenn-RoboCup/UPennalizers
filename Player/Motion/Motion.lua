module(..., package.seeall);

require('Body')
require('UltraSound')
require('fsm')
require('vector')
require('mcm')
require('gcm')
require('wcm')
require('relax')
require('stance')
require('nullstate')
require('walk')
require('sit')
require('standstill') -- This makes torso straight (for webots robostadium)
require('falling')
require('standup')
require('kick')
require('align') -- slow, non-dynamic stepping for fine alignment before kick

--For diving
require('divewait')
require('dive')

-- Aux
require 'grip'

if Config.largestep_enable then
  require ('stepkick')
end

sit_disable = Config.sit_disable or 0;

if sit_disable==0 then --For smaller robots
  fallAngle = Config.fallAngle or 40*math.pi/180; --30*math.pi/180;

  sm = fsm.new(relax);
  sm:add_state(stance);
  sm:add_state(nullstate);
  sm:add_state(walk);
  sm:add_state(sit);
  sm:add_state(standup);
  sm:add_state(falling);
  sm:add_state(kick);
  sm:add_state(standstill);
  sm:add_state(grip);
  sm:add_state(divewait);
  sm:add_state(dive);
  sm:add_state(align);


  sm:set_transition(sit, 'done', relax);
  sm:set_transition(sit, 'standup', stance);
  sm:set_transition(relax, 'standup', stance);
  sm:set_transition(relax, 'diveready', divewait);

  sm:set_transition(stance, 'done', walk);
  sm:set_transition(stance, 'sit', sit);
  sm:set_transition(stance, 'diveready', divewait);

  sm:set_transition(walk, 'sit', sit);
  sm:set_transition(walk, 'stance', stance);
  sm:set_transition(walk, 'standstill', standstill);
  sm:set_transition(walk, 'pickup', grip);
  sm:set_transition(walk, 'throw', grip);
  sm:set_transition(walk, 'align', align);

  --align transitions
  sm:set_transition(align, 'done', walk);

  --dive transitions
  sm:set_transition(walk, 'diveready', divewait);
  sm:set_transition(walk, 'dive', dive);

  --ZMP preview motion transitions
  if Config.largestep_enable then
    sm:add_state(stepkick);
    sm:set_transition(walk, 'step', stepkick);
    sm:set_transition(stepkick, 'done', walk);
  end

  sm:set_transition(divewait, 'dive', dive);
  sm:set_transition(divewait, 'walk', stance);
  sm:set_transition(divewait, 'standup', stance);
  sm:set_transition(divewait, 'sit', sit);

  sm:set_transition(dive, 'done', stance);
  sm:set_transition(dive, 'divedone', falling);

  --standstill makes the robot stand still with 0 bodytilt (for webots)
  sm:set_transition(standstill, 'stance', stance);
  sm:set_transition(standstill, 'walk', stance);
  sm:set_transition(standstill, 'sit', sit);
  sm:set_transition(standstill, 'diveready', divewait);

  -- Grip
  sm:set_transition(grip, 'timeout', grip);
  sm:set_transition(grip, 'done', stance);

  -- falling behaviours

  sm:set_transition(walk, 'fall', falling);
  sm:set_transition(align, 'fall', falling);
  sm:set_transition(divewait, 'fall', falling);
  sm:set_transition(falling, 'done', standup);
  sm:set_transition(falling, 'restand', stance);

  sm:set_transition(standup, 'done', stance);
  sm:set_transition(standup, 'fail', standup);

  -- kick behaviours
  sm:set_transition(walk, 'kick', kick);
  sm:set_transition(kick, 'done', walk);
else --For large robots that cannot sit down or getup

  fallAngle = 1E6; --NEVER check falldown

  sm = fsm.new(standstill);
  sm:add_state(stance);
  sm:add_state(walk);
  sm:add_state(kick);

  sm:set_transition(stance, 'done', walk);

  sm:set_transition(walk, 'stance', stance);
  sm:set_transition(walk, 'standstill', standstill);

  --standstill makes the robot stand still with 0 bodytilt (for webots)
  sm:set_transition(standstill, 'stance', stance);
  sm:set_transition(standstill, 'walk', stance);

  -- kick behaviours
  sm:set_transition(walk, 'kick', kick);
  sm:set_transition(kick, 'done', walk);

end

-- set state debug handle to shared memory settor
sm:set_state_debug_handle(gcm.set_fsm_motion_state);

-- TODO: fix kick->fall transition
--sm:set_transition(kick, 'fall', falling);

bodyTilt = Config.walk.bodyTilt or 0;

-- For still time measurement (dodgeball)
stillTime = 0;
stillTime0 = 0;
wasStill = false;

-- Ultra Sound Processor
UltraSound.entry();
require'wcm'

function entry()
  sm:entry()
  mcm.set_walk_isFallDown(0);
  wcm.set_robot_is_emergency_stop(0);
  mcm.set_motion_fall_check(1); --check fall by default
end

function update()

  local t0 = unix.time()


  -- update us
  UltraSound.update();
  Left, Right = UltraSound.check_obstacle()
  role = gcm.get_team_role() 

  if (role == 0) then
    -- goalie never stops
    frontobs = 0
  else
    if (vcm.get_ball_detect() == 1 or wcm.get_ball_t() > 5) and role == 1 then
      -- attacker will not stop if it sees a ball
      frontobs = 0
    else
      if (Left or Right) then
        frontobs = 1
      else
        frontobs = 0
      end
    end
  end

  local imuAngle = Body.get_sensor_imuAngle();
  local maxImuAngle = math.max(math.abs(imuAngle[1]), math.abs(imuAngle[2]-bodyTilt));
  fall = mcm.get_motion_fall_check() --Should we check for fall? 1 = yes

  --SJ: sometimes this becomes nil....
  fallAngle = fallAngle or 1E6;


  if (maxImuAngle > fallAngle and fall==1) then
    sm:add_event("fall");
    mcm.set_walk_isFallDown(1); --Notify world to reset heading
    mcm.set_walk_isGetupDone(0); 
  else
    mcm.set_walk_isFallDown(0); 
  end

  -- Keep track of how long we've been still for
  -- Update our last still measurement
  if( walk.still and not wasStill ) then
    stillTime0 = Body.get_time();
    stillTime = 0;
  elseif( walk.still and wasStill) then
    stillTime = Body.get_time() - stillTime0;
  else
    stillTime = 0;
  end
  wasStill = walk.still;


  if walk.active or align.active then
    mcm.set_walk_isMoving(1);
  else
    mcm.set_walk_isMoving(0);
  end

  --Particle information
--  if mcm.get_walk_isFallDown()==0 and mcm.get_walk_isMoving()==0 then
  if walk.is_stopped then
  --Dickens: if not moving and not fallen, 
    --then it is emergency stop (or standing up) 
    wcm.set_robot_is_emergency_stop(1)
 else
    wcm.set_robot_is_emergency_stop(0)
  end


  sm:update();

  -- update shm
  update_shm();

  local t_loop = unix.time()-t0
  local v = wcm.get_process_fsm()
  wcm.set_process_fsm({v[1],v[2]+t_loop,v[3]+1})

end

function exit()
  wcm.set_robot_is_emergency_stop(0)
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
  mcm.set_us_frontobs(frontobs)
  mcm.set_walk_stillTime( stillTime );
end

