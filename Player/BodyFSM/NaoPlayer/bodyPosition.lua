module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
require('wcm')
require('gcm')
require('UltraSound')

t0 = 0;
timeout = 20.0;

maxStep = 0.05;

rClose = 0.35;

tLost = 3.0;


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  ball = wcm.get_ball();
  pose = wcm.get_pose();
  ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a});
  tBall = Body.get_time() - ball.t;

  role = gcm.get_team_role();
  if (role == 2) then
    -- defend
    homePosition = .6 * ballGlobal;
    homePosition[1] = homePosition[1] - 0.50*util.sign(homePosition[1]);
    homePosition[2] = homePosition[2] - 0.80*util.sign(homePosition[2]);

  elseif (role == 3) then
    -- support
    attackGoalPosition = vector.new(wcm.get_goal_attack());

    --[[
    homePosition = ballGlobal;
    homePosition[1] = homePosition[1] + 0.75*util.sign(homePosition[1]);
    homePosition[1] = util.sign(homePosition[1])*math.min(2.0, math.abs(homePosition[1]));
    homePosition[2] = 
    --]]

    -- move near attacking goal
    homePosition = attackGoalPosition;
    -- stay in the field (.75 m from end line)
    homePosition[1] = homePosition[1] - util.sign(homePosition[1]) * 1.0;
    -- go to far post (.75 m from center)
    homePosition[2] = -1*util.sign(ballGlobal[2]) * .75;

    -- face ball 
    homePosition[3] = ballGlobal[3];
  else
    -- attack
    homePosition = ballGlobal;
  end
  print(homePosition[1]..','..homePosition[2]..','..homePosition[3]);

  -- do not go into own penalty box
  if (gcm.get_team_color() == 1) then
    -- red
    homePosition[1] = math.min(homePosition[1], 2.2);
  else
    -- blue
    homePosition[1] = math.max(homePosition[1], -2.2);
  end

  homeRelative = util.pose_relative(homePosition, {pose.x, pose.y, pose.a});
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

  vx = maxStep*homeRelative[1]/(rHomeRelative + 0.1);
  vy = maxStep*homeRelative[2]/(rHomeRelative + 0.1);
  va = .5*math.atan2(ball.y, math.max(ball.x + 0.05,0.05));

  walk.set_velocity(vx, vy, va);
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  if ((tBall < 1.0) and (ballR < rClose)) then
    return "ballClose";
  end

  -- TODO: add obstacle detection
  --us = UltraSound.checkObstacle();
  us = UltraSound.check_obstacle();
  if ((t - t0 > 3.0) and (us[1] > 8 or us[2] > 8)) then
    return 'obstacle'; 
  end

  if ((t - t0 > 5.0) and (t - ball.t > tLost)) then
    return "ballLost";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end

