module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('gcm')

t0 = 0;
timeout = 20.0;

maxStep = 0.04;

maxPosition = 0.55;

ballNear = 0.5;

rClose = 0.40;

tLost = 6.0;


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  -- get ball pose
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  tBall = Body.get_time() - ball.t;  

  -- get robot pose
  pose = wcm.get_pose();

  -- pose of the ball in the world frame
  ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a});

  -- define home goalie position (in front of goal and facing the ball)
  --homePosition = 1.0*vector.new(wcm.get_goal_defend());
  homePosition = 0.98*vector.new(wcm.get_goal_defend());

  vBallHome = math.exp(-math.max(tBall-3.0, 0)/4.0)*(ballGlobal - homePosition);
  rBallHome = math.sqrt(vBallHome[1]^2 + vBallHome[2]^2);

  if (rBallHome > maxPosition) then
    scale = maxPosition/rBallHome;
    vBallHome = scale*vBallHome;
  end
  homePosition = homePosition + vBallHome;

  if (tBall > 8) then
    va = .35*wcm.get_attack_bearing();
  else
    va = math.atan2(ball.y, ball.x);
  end
  
  homeRelative = util.pose_relative(homePosition, {pose.x, pose.y, pose.a});
  rhomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

  vx = maxStep*homeRelative[1]/(rhomeRelative+0.1);
  vy = maxStep*homeRelative[2]/(rhomeRelative+0.1);
  
  walk.set_velocity(vx, vy, va);

  --[[
  goalieRadius = 1.0;
  goal = wcm.get_goal_defend();
  goalToBall = ballGlobal - goal;
  theta = math.atan2(goalToBall[2], goalToBall[1]);
  posRelToGoal = vector.new({goalieRadius*math.cos(theta), goalieRadius*math.sin(theta),theta});
  finGlbPos = util.pose_global(posRelToGoal, goal);

  -- based on your relative pose and your desired pose, calculate the walk velocity
  vStep = vector.new({0,0,0});
  vStep[1] = .1*(finGlbPos[1]-pose.x);
  vStep[2] = .15*(finGlbPos[2]-pose.y);
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;
  vStep[3] = 0.15*(finGlbPos[3]-pose.a);
  
  walk.set_velocity(vStep[1],vStep[2],vStep[3])
  --walk.set_velocity(0,0,0,0)

  -- checks for transitions
  -- close to the ball?
  --]]

  -- If ball is close, abandon goal to chase it down --
  if ((tBall < 3.0) and (ballR < ballNear)) then
    return "ballClose";
  end
  -- lost ball
  if ((t - t0 > 1.0) and (t - ball.t > tLost)) then
    return "ballLost";
  end
  -- timeout
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end

