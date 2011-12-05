module(..., package.seeall);

require('Body')
require('HeadTransform')
require('Config')
require('wcm')

t0 = 0;
timeout = 3.0;

-- ball detection timeout
tLost = 1.5;

-- z-axis tracking position
trackZ = Config.vision.ball_diameter; 

function entry()
  print("Head SM:".._NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  -- update head position based on ball location
  ball = wcm.get_ball();
  local yaw, pitch =
	HeadTransform.ikineCam(ball.x, ball.y, trackZ, bottom);

  if math.abs(ball.y) < 0.12 and ball.x < 0.30 then
     yaw=0.0; 
  end

  Body.set_head_command({yaw, pitch});

  if (t - ball.t > tLost) then
    print('Ball lost!');
    return "lost";
  end
  if (t - t0 > timeout) then
    print('Head Track timeout')
    return "timeout";
  end
end

function exit()
end
