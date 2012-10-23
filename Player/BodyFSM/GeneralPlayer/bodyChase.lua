module(..., package.seeall);

require('Body')
require('wcm')
require('walk')
require('vector')
require('behavior')

t0 = 0;
timeout = Config.fsm.bodyChase.timeout;
maxStep = Config.fsm.bodyChase.maxStep;
rClose = Config.fsm.bodyChase.rClose;
tLost = Config.fsm.bodyChase.tLost;
rFar = Config.fsm.bodyChase.rFar;
rFarX = Config.fsm.bodyChase.rFarX;

function entry()
  print("Body FSM:".._NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  -- get ball position
  ball = wcm.get_ball();
  pose = wcm.get_pose();
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  goal_defend=wcm.get_goal_defend();

  ballxy=vector.new( {ball.x,ball.y,0} );
  posexya=vector.new( {pose.x, pose.y, pose.a} );
  ballGlobal=util.pose_global(ballxy,posexya);

  ballR_defend = math.sqrt(
	(ballGlobal[1]-goal_defend[1])^2+
	(ballGlobal[2]-goal_defend[2])^2);
  ballX_defend = math.abs(ballGlobal[1]-goal_defend[1]);

  -- calculate walk velocity based on ball position
  vStep = vector.new({0,0,0});
  vStep[1] = .6*ball.x;
  vStep[2] = .75*ball.y;
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

  ballA = math.atan2(ball.y, ball.x+0.10);
  vStep[3] = 0.75*ballA;
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);
  
  if ballR_defend>rFar and ballX_defend>rFarX and gcm.get_team_role()==0 then

print("Chase:ballRX", ballR_defend, ballX_defend);

    --ballFar check - Only for goalie
    return "ballFar";
  end

  if (t - ball.t > tLost) then
    return "ballLost";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
  if (ballR < rClose) then
    behavior.update();
    return "ballClose";
  end
  if (t - t0 > 1.0 and Body.get_sensor_button()[1] > 0) then
    return "button";
  end
end

function exit()
end
