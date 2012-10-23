module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
require('postDist')
require('wcm')
require('UltraSound')

t0 = 0;
timeout = 10.0;

-- maximum walk velocity
maxStep = 0.04;

-- ball detection timeout
tLost = 3.0;

-- kick target threshold
xKick = 0.18;
xTarget = 0.15;
	
print('xKick')
print(xKick)

yKickMin = 0.02;
yKickMax = 0.06;

-- maximum ball distance threshold
rFar = 0.45;

-- alignment
thAlign = Config.fsm.bodyApproach.thAlign or 15.0*math.pi/180.0;
thAlignWalkKick = Config.fsm.bodyApproach.thAlignWalkKick or 30*math.pi/180.0;


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  -- get ball position
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  --print('ball: '..ball.x..', '..ball.y);
  --print('ballR '..ballR);

  -- calculate walk velocity based on ball position
  vStep = vector.new({0,0,0});
  vStep[1] = .5*(ball.x - xTarget);
  vStep[2] = .75*(ball.y - util.sign(ball.y)*0.05); --.75
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

  ballA = math.atan2(ball.y - math.max(math.min(ball.y, 0.05), -0.05), math.max(ball.x+0.10, 0.10));
  vStep[3] = 0.5*ballA;
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);

  attackBearing, daPost = wcm.get_attack_bearing();
  --print(vStep[1]..','..vStep[2]..','..vStep[3]);

  --Kick or not? True = yes, false = no, walk kick
  toKick = postDist.kick();

  --Check for obstacles
  if Config.fsm.enable_obstacle_detection > 0 then
    us = UltraSound.check_obstacle();
  else
    us = vector.zeros(2) 
  end

  if (t - ball.t > tLost) then
    print('ballLost');
    return "ballLost";
  end
  if (t - t0 > timeout) then
    print('timeout');
    return "timeout";
  end
  if (ballR > rFar) then
    print('ballFar');
    return "ballFar";
  end
  if toKick then
    if (math.abs(attackBearing) > thAlign) then
      print('ballAlign');
      return 'ballAlign';
    end
  else
    if (math.abs(attackBearing) > thAlignWalkKick) then
      print('ballAlignWalkKick');
      return 'ballAlign';
    end
  end
  if ((ball.x < xKick) and (math.abs(ball.y) < yKickMax) and
      (math.abs(ball.y) > yKickMin)) then
    if(postDist.kick()) then
      if ((us[1] > 8 or us[2] > 8)) then
        return "walkKick";
      else
        return "kick"
      end
    else
      return "walkKick"
    end  
  end
end

function exit()
end

