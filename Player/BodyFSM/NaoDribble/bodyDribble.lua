module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
require('wcm')
require('Speak')

t0 = 0;

-- state timeout
timeout = 20;

-- maximum walk velocity
maxStep = 0.06;

-- ball detection timeout
tLost = 5.0;

-- maximum ball distance threshold
rFar = 0.45;

function entry()
  print(_NAME.." entry");

  Speak.talk('Dribble');

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  -- get ball position
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  attackBearing = wcm.get_attack_bearing();
 
  ca = math.cos(attackBearing);
  sa = math.sin(attackBearing);
  xAttack = .5 * ((ca * ball.x - sa * ball.y) - 0.05);
  yAttack = .8 * (sa * ball.x + ca * ball.y);

  vx = ca * xAttack + sa * yAttack;
  vy = -sa * xAttack + ca * yAttack;

  scale = math.min(maxStep/math.sqrt(vx^2 + vy^2), 1); 
  vx = scale * vx;
  vy = scale * vy;

  aBall = math.atan2(ball.y, ball.x + 0.10);
  va = .5 * aBall;

  walk.set_velocity(vx, vy, va);


  if (t - ball.t > tLost) then
    return "ballLost";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
  if (ballR > rFar) then
    return "ballFar";
  end
  if (aBall > 25*math.pi/180) then
    ret = 'ballFar';
  end
  if (math.abs(attackBearing) > 20*math.pi/180) then
    ret = 'ballFar';
  end
end

function exit()
end

