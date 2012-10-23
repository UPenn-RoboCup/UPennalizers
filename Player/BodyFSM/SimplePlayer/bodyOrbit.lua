module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')

t0 = 0;
timeout = Config.fsm.bodyOrbit.timeout;
maxStep = Config.fsm.bodyOrbit.maxStep;
rOrbit = Config.fsm.bodyOrbit.rOrbit;
rFar = Config.fsm.bodyOrbit.rFar;
thAlign = Config.fsm.bodyOrbit.thAlign;
tLost = Config.fsm.bodyOrbit.tLost;
direction = 1;
dribbleThres = 0.75;

kickAngle = 0;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
  kickAngle=  0;
  direction,angle=get_orbit_direction();
end

function get_orbit_direction()
  attackBearing = wcm.get_attack_bearing();
  angle = util.mod_angle(attackBearing-kickAngle);
  if angle>0 then dir = 1;
  else dir = -1;
  end
  return dir,angle;
end

function update()
  local t = Body.get_time();

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
  va = 0.75*ballA;

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
--  print(attackBearing*180/math.pi)

  dir,angle = get_orbit_direction();

  if (math.abs(angle) < thAlign) then
    return 'done';
  end

  --Overshoot escape
  if direction~=dir then
    return 'done'
  end  
  
end

function exit()
end

