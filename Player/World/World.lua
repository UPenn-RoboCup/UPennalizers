module(..., package.seeall);

require('PoseFilter');
require('Filter2D');
require('Body');
require('vector');
require('util');

require('vcm');
require('gcm');
require 'mcm'


ballFilter = Filter2D.new();
ball = {};
ball.t = 0;  --Detection time
ball.x = 1.0;
ball.y = 0;
ball.vx = 0;
ball.vy = 0;

pose = {};
pose.x = 0;
pose.y = 0;
pose.a = 0;
pose.tGoal = 0; --Goal detection time

uOdometry0 = vector.new({0, 0, 0});
count = 0;
cResample = Config.world.cResample; 

playerID = Config.game.playerID;

odomScale = Config.world.odomScale;

enableVelocity = Config.vision.enable_velocity_detection;
if( enableVelocity == 1 ) then
  require('Velocity');	-- Add Velocity for Ball
end

function entry()
  count = 0;

  if( enableVelocity == 1 ) then
    Velocity.entry();
  end  
end

function update_odometry()
  count = count + 1;
  uOdometry, uOdometry0 = mcm.get_odometry(uOdometry0);

  uOdometry[1] = odomScale[1]*uOdometry[1];
  uOdometry[2] = odomScale[2]*uOdometry[2];
  uOdometry[3] = odomScale[3]*uOdometry[3];

  ballFilter:odometry(uOdometry[1], uOdometry[2], uOdometry[3]);
  PoseFilter.odometry(uOdometry[1], uOdometry[2], uOdometry[3]);
end

function update_vision()

  -- resample?
  if count % cResample == 0 then
    PoseFilter.resample();
    PoseFilter.add_noise();
  end

  -- ball
  if (vcm.get_ball_detect() == 1) then
    ball.t = Body.get_time();
    local v = vcm.get_ball_v();
    local dr = vcm.get_ball_dr();
    local da = vcm.get_ball_da();
    ballFilter:observation_xy(v[1], v[2], dr, da);
    Body.set_indicator_ball({1,0,0});

    -- Update the velocity
    if( enableVelocity==1 ) then
      Velocity.update();
      ball.vx, ball.vy, dodge = Velocity.getVelocity();
      local speed = math.sqrt(ball.vx^2 + ball.vy^2);
      local stillTime = mcm.get_walk_stillTime();
      if( stillTime > 1.5 ) then 
        print('Speed: '..speed..', Vel: ('..ball.vx..', '..ball.vy..') Still Time: '..stillTime);
      end
    end
    
  else
    Body.set_indicator_ball({0,0,0});
  end

  -- TODO: handle goal detections more generically
  
  if vcm.get_goal_detect() == 1 then
    pose.tGoal = Body.get_time();
    local color = vcm.get_goal_color();
    local goalType = vcm.get_goal_type();
    local v1 = vcm.get_goal_v1();
    local v2 = vcm.get_goal_v2();
    local v = {v1, v2};

    if color == Config.color.yellow then
      if (goalType == 0) then
        PoseFilter.post_yellow_unknown(v);
      elseif(goalType == 1) then
        PoseFilter.post_yellow_left(v);
      elseif(goalType == 2) then
        PoseFilter.post_yellow_right(v);
      elseif(goalType == 3) then
        PoseFilter.goal_yellow(v);
      end

      -- indicator
      Body.set_indicator_goal({1,1,0});

    elseif color == Config.color.cyan then
      if (goalType == 0) then
        PoseFilter.post_cyan_unknown(v);
      elseif(goalType == 1) then
        PoseFilter.post_cyan_left(v);
      elseif(goalType == 2) then
        PoseFilter.post_cyan_right(v);
      elseif(goalType == 3) then
        PoseFilter.goal_cyan(v);
      end

      -- indicator
      Body.set_indicator_goal({0,0,1});
    end
  else
    -- indicator
    Body.set_indicator_goal({0,0,0});
  end

  -- line update
  if vcm.get_line_detect() == 1 then
    local v = vcm.get_line_v();
    local a = vcm.get_line_angle();
    PoseFilter.line(v, a);
  end

  ball.x, ball.y = ballFilter:get_xy();
  pose.x,pose.y,pose.a = PoseFilter.get_pose();

  update_shm();
end

function update_shm()
  -- update shm values
  wcm.set_robot_pose({pose.x, pose.y, pose.a});

  wcm.set_ball_xy({ball.x, ball.y});
  wcm.set_ball_t(ball.t);
  wcm.set_ball_velocity( {ball.vx, ball.vy} );

  wcm.set_goal_t(pose.tGoal);
  wcm.set_goal_attack(get_goal_attack());
  wcm.set_goal_defend(get_goal_defend());
  wcm.set_goal_attack_bearing(get_attack_bearing());
  wcm.set_goal_attack_angle(get_attack_angle());
  wcm.set_goal_defend_angle(get_defend_angle());
end

function exit()
end


function get_ball()
  return ball;
end

function get_pose()
  return pose;
end

function zero_pose()
  PoseFilter.zero_pose();
end

function get_attack_bearing()
  if gcm.get_team_color() == 1 then
    -- red attacks cyan goal
    postAttack = PoseFilter.postCyan;
  else
    -- blue attack yellow goal
    postAttack = PoseFilter.postYellow;
  end
  -- make sure not to shoot back towards defensive goal:
  local xPose = math.min(math.max(pose.x, -0.99*PoseFilter.xLineBoundary),
                          0.99*PoseFilter.xLineBoundary);
  local yPose = pose.y;
  local aPost = {}
  aPost[1] = math.atan2(postAttack[1][2]-yPose, postAttack[1][1]-xPose);
  aPost[2] = math.atan2(postAttack[2][2]-yPose, postAttack[2][1]-xPose);
  local daPost = math.abs(PoseFilter.mod_angle(aPost[1]-aPost[2]));
  attackHeading = aPost[2] + .5*daPost;
  attackBearing = PoseFilter.mod_angle(attackHeading - pose.a);

  return attackBearing, daPost;
end

function get_goal_attack()
  if gcm.get_team_color() == 1 then
    -- red attacks cyan goal
    return {PoseFilter.postCyan[1][1], 0, 0};
  else
    -- blue attack yellow goal
    return {PoseFilter.postYellow[1][1], 0, 0};
  end
end

function get_goal_defend()
  if gcm.get_team_color() == 1 then
    -- red defends yellow goal
    return {PoseFilter.postYellow[1][1], 0, 0};
  else
    -- blue defends cyan goal
    return {PoseFilter.postCyan[1][1], 0, 0};
  end
end

function get_attack_angle()
  goalAttack = get_goal_attack();

  dx = goalAttack[1] - pose.x;
  dy = goalAttack[2] - pose.y;
  return mod_angle(math.atan2(dy, dx) - pose.a);
end

function get_defend_angle()
  goalDefend = get_goal_defend();

  dx = goalDefend[1] - pose.x;
  dy = goalDefend[2] - pose.y;
  return mod_angle(math.atan2(dy, dx) - pose.a);
end

function get_team_color()
  return gcm.get_team_color();
end

function pose_global(pRelative, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  return vector.new{pose[1] + ca*pRelative[1] - sa*pRelative[2],
                    pose[2] + sa*pRelative[1] + ca*pRelative[2],
                    pose[3] + pRelative[3]};
end

function pose_relative(pGlobal, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  local px = pGlobal[1]-pose[1];
  local py = pGlobal[2]-pose[2];
  local pa = pGlobal[3]-pose[3];
  return vector.new{ca*px + sa*py, -sa*px + ca*py, mod_angle(pa)};
end

function mod_angle(a)
  -- Reduce angle to [-pi, pi)
  a = a % (2*math.pi);
  if (a >= math.pi) then
    a = a - 2*math.pi;
  end
  return a;
end

