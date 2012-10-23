module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('gcm')

t0 = 0;

maxStep = Config.fsm.bodyGotoCenter.maxStep;
rClose = Config.fsm.bodyGotoCenter.rClose;
timeout = Config.fsm.bodyGotoCenter.timeout;
--TODO: Goalie handling, velocity limit 

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

  id = gcm.get_team_player_id();
  role = gcm.get_team_role();
  if id == 1 then
    -- goalie
    centerPosition = vector.new(wcm.get_goal_defend());
    centerPosition[1] = centerPosition[1] - util.sign(centerPosition[1]) * .5;
    -- face center
    centerPosition[3] = math.atan2(centerPosition[2], 0 - centerPosition[1]);

    -- use stricter thresholds
    thAlign = 10*math.pi/180;
    rClose = .1;
  else
    if (role == 2) then
      -- defend
      centerPosition = vector.new(wcm.get_goal_defend())/2.0;
    elseif (role == 3) then
      -- support
      centerPosition = vector.zeros(3);
    else
      -- attack
      centerPosition = vector.new(wcm.get_goal_attack())/2.0;
    end
  end

  centerRelative = util.pose_relative(centerPosition, {pose.x, pose.y, pose.a});
  rCenterRelative = math.sqrt(centerRelative[1]^2 + centerRelative[2]^2);

  vx = maxStep * centerRelative[1]/rCenterRelative;
  vy = maxStep * centerRelative[2]/rCenterRelative;
  if id == 1 then
    va = .2 * centerRelative[3];
  else
    va = .2 * math.atan2(centerRelative[2], centerRelative[1]);
  end
  walk.set_velocity(vx, vy, va);

  ballR = math.sqrt(ball.x^2 + ball.y^2);
  if (tBall < 1.0) then
    return 'ballFound';
  end
  if ((t - t0 > 2.0) and (rCenterRelative < rClose)) then
    return 'done';
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end

