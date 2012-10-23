module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('postDist')

t0 = 0;
timeout = 30.0;

if Config.fsm.bodyOrbit.walkParam then
  tDelay = Config.fsm.bodyOrbit.tDelay or .6
else
  tDelay = 0;
end


maxStep = 0.06;

rOrbit = 0.15;--.27

rFar = 0.30;

thAlign = 10*math.pi/180;
thAlignWalkKick = 20*math.pi/180

tLost = 3.0;

direction = 1;

dribbleThres = 0.75;


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
  attackBearing = wcm.get_attack_bearing();
  if (attackBearing > 0) then
    direction = 1;
  else
    direction = -1;
  end

  --If walk parameters are defined for bodyOrbit, then load them
  if Config.fsm.bodyOrbit.walkParam then
    Config.loadconfig(Config.fsm.bodyOrbit.walkParam)
  end
  walk.set_velocity(0,0,0)

  toKick = postDist.kick()
end

function update()
  local t = Body.get_time();

  --Walk in place for tDelay time
  if t - t0 < tDelay then
    return
  end

  attackBearing, daPost = wcm.get_attack_bearing();
  --print('attackBearing: '..attackBearing);
  --print('daPost: '..daPost);
  --print('attackBearing', attackBearing)
  ball = wcm.get_ball();

  ballR = math.sqrt(ball.x^2 + ball.y^2);
  ballA = math.atan2(ball.y, ball.x+0.10);
  dr = ballR - rOrbit;
  aStep = ballA - direction*(90*math.pi/180 - dr/0.40);
  vx = maxStep*math.cos(aStep);
  
  --Does setting vx to 0 improve performance of orbit?--
  vx = 0;
  
  vy = maxStep*math.sin(aStep);
  va = 0.6*ballA;

  walk.set_velocity(vx, vy, va);

  if (t - ball.t > tLost) then
    return 'ballLost';
  end
  if (t - t0 > timeout) then
    return 'timeout';
  end
  if (ballR > rFar) then
    return 'ballFar';
  end
  if toKick then
    if (math.abs(attackBearing) < thAlign) then
      print(math.abs(attackBearing));
      return 'done';
    end
  else
    if (math.abs(attackBearing) < thAlignWalkKick) then
      print(math.abs(attackBearing));
      return 'done';
    end
  end
  
  -- check overshoot
  --[[
  if (attackBearing < direction * (2*thAlign)) then
    print('Orbit: overshoot thres meet. attackBearing: '..attackBearing..' direction: '..direction);
    return 'done'
  end
  --]]
end

function exit()
  --Load default walk parameters
  Config.loadconfig(Config.param.walk)
end

