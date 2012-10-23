module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('UltraSound')
require('Config')
require('wcm')
require('gcm')

t0 = 0;
timeout = 20.0;

maxStep = 0.06;

rClose = 0.35;

tLost = 5.0;


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);

  vStep = vector.new({0,0,0});
  vStep[1] = .6*ball.x;
  vStep[2] = .75*ball.y;
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

  ballA = math.atan2(ball.y, ball.x+0.10);
  vStep[3] = 0.75*ballA;
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);

  if (t - ball.t > tLost) then
    return "ballLost";
  end
  if (t - t0 > 2.0) and gcm.get_team_role() == 2 then
    return 'pause';
  end
  
  if (t - t0 > 2.0) then
    -- check obstacle
    lobs, robs = UltraSound.obstacle();
    if (lobs > 0) then
      -- obs left
      return 'leftObstacle';
    elseif (robs > 0) then
      -- obs right
      return 'rightObstacle';
    end
  end

  if (t - t0 > timeout) then
    return "timeout";
  end
  if (ballR < rClose) then
    return "ballClose";
  end
end

function exit()
end
