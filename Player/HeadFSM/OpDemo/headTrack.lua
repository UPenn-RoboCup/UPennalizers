module(..., package.seeall);

require('Body')
require('HeadTransform')
require('Config')
require('wcm')

t0 = 0;
timeout = 6.0* Config.speedFactor;

-- ball detection timeout
tLost = 1.5* Config.speedFactor;

-- z-axis tracking position
trackZ = Config.vision.ball_diameter; 

--If ball is closer than this, never look up 
minDist = 0.30; 




function entry()
  print("Head SM:".._NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  -- update head position based on ball location
  ball = wcm.get_ball();
  ballR = math.sqrt (ball.x^2 + ball.y^2);

  local yaw, pitch =
	HeadTransform.ikineCam(ball.x, ball.y, trackZ, bottom);

  -- Fix head yaw while approaching (to reduce position error)
  if math.abs(ball.y) < 0.08 and ball.x < 0.20 then
     yaw=0.0; 
  end

  Body.set_head_command({yaw, pitch});

  if (t - ball.t > tLost) then
    print('Ball lost!');
    return "lost";
  end
  if (t - t0 > timeout) and
     ballR > minDist   then
    print('Head Track timeout')
    return "timeout";
  end
end

function exit()
end
