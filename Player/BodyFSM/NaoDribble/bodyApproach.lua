module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')

require('wcm')

t0 = 0;
timeout = 10.0;

-- maximum walk velocity
maxStep = 0.04;

-- ball detection timeout
tLost = 3.0;

-- kick target threshold
xKick = 0.22;
xTarget = 0.16;

yKickMin = 0.02;
yKickMax = 0.05;

-- maximum ball distance threshold
rFar = 0.45;

-- alignment
thAlign = 10.0*math.pi/180.0;

-- dribble threshold
dribbleThres = 1.0;


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  -- get ball position
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  tBall = ball.t;
  --print('ball: '..ball.x..', '..ball.y);
  --print('ballR '..ballR);

  -- calculate walk velocity based on ball position
  vStep = vector.new({0,0,0});
  vStep[1] = .5*(ball.x - xTarget);
  vStep[2] = .75*(ball.y - util.sign(ball.y)*0.05);
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

  ballA = math.atan2(ball.y - math.max(math.min(ball.y, 0.05), -0.05), ball.x+0.10);
  vStep[3] = 0.5*ballA;
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);

  attackBearing, daPost = wcm.get_attack_bearing();

  if (t - ball.t > tLost) then
    return "ballLost";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
  if (ballR > rFar) then
    return "ballFar";
  end
  if (math.abs(attackBearing) > thAlign) then
    return 'ballAlign';
  end


  -- kick?
  if (math.abs(ball.y) < yKickMax and math.abs(ball.y) > yKickMin) then
    
    p = wcm.get_pose();

    rCenter = math.sqrt(p.x^2 + p.y^2);
    if (rCenter < dribbleThres) then 
      -- dribble
      return 'dribble';
    else
      if ((ball.x < xKick) and (math.abs(ball.y) < yKickMax) and
          (math.abs(ball.y) > yKickMin)) then
        -- keyframe kick
        return "kick";
      end
    end
  end
end

function exit()
end

