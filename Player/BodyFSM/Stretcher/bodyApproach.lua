module(..., package.seeall);

require('Body')
require('wcm')
require('walk')
require('vector')

t0 = 0;
timeout = 10.0;

-- maximum walk velocity
maxStep = 0.025;

-- ball detection timeout
tLost = 3.0;

-- kick threshold
xKick = 0.16;
xTarget = 0.14;
yKickMin = 0.01;
yKickMax = 0.05;
yTarget0 = 0.04;

-- maximum ball distance threshold
rFar = 0.45;

function entry()
  print("Body FSM:".._NAME.." entry");
  t0 = Body.get_time();
  ball = wcm.get_ball();
  yTarget= sign(ball.y) * yTarget0;
end

function update()
  local t = Body.get_time();

  -- get ball position
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);

  -- calculate walk velocity based on ball position
  vStep = vector.new({0,0,0});
  vStep[1] = .6*(ball.x - xTarget);
  vStep[2] = .75*(ball.y - yTarget);
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

  ballA = math.atan2(ball.y - math.max(math.min(ball.y, 0.05), -0.05),
            ball.x+0.10);
  vStep[3] = 0.5*ballA;
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);


  if (t - ball.t > tLost) then
    return "ballLost";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
  if (ballR > rFar) then
    return "ballFar";
  end

  if ((ball.x < xKick) and (math.abs(ball.y) < yKickMax) and
      (math.abs(ball.y) > yKickMin)) then
    return "kick";
  end
  if (t - t0 > 1.0 and Body.get_sensor_button()[1] > 0) then
    return "button";
  end
end

function exit()
end

function sign(x)
  if (x > 0) then return 1;
  elseif (x < 0) then return -1;
  else return 0;
  end
end
