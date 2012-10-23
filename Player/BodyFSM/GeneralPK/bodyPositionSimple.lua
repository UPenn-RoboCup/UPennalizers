module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
require('wcm')
require('gcm')

t0 = 0;

maxStep = Config.fsm.bodyChase.maxStep;
tLost = Config.fsm.bodyChase.tLost;
timeout = Config.fsm.bodyChase.timeout;
rClose = Config.fsm.bodyChase.rClose;

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  wcm.set_kick_dir(1);
  wcm.set_kick_type(1);
  wcm.set_kick_angle(math.pi/12);
  wcm.set_kick_angle(0);
end

function update()
  if not walk.active then walk.start(); end

  local t = Body.get_time();

  ball = wcm.get_ball();
  pose = wcm.get_pose();
  ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a});
  tBall = Body.get_time() - ball.t;
  homePosition = ballGlobal;
  homeRelative = util.pose_relative(homePosition, {pose.x, pose.y, pose.a});
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

  vx = maxStep*homeRelative[1]/rHomeRelative;
  vy = maxStep*homeRelative[2]/rHomeRelative;
  va = .5*math.atan2(ball.y, ball.x + 0.05);

  walk.set_velocity(vx, vy, va);
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  if ((tBall < 1.0) and (ballR < rClose)) then
    return "ballClose";
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

