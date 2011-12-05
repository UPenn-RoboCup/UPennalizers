module(..., package.seeall);

require('Body')
require('wcm')

t0 = 0;

-- scan period
tscan = 3.0;
timeout = 4*tscan;
direction = 1;

function entry()
  print("Head SM:".._NAME.." entry");

  -- start scan in ball's last known direction
  t0 = Body.get_time();
  ball = wcm.get_ball();
  if (ball.y > 0) then
    direction = 1;
  else
    direction = -1;
  end
end

function update()
  local t = Body.get_time();
  -- update head position
  -- continuously scanning left-right and up-down
  local ph = 2*math.pi*(t-t0)/tscan;
  local yaw = 60*math.pi/180*direction*math.asin(math.sin(ph));
  local pitch = 30*math.pi/180 + 20*math.pi/180*math.cos(ph);  
  local pitch_actual = pitch - Config.head.cameraAngle[1][2];
  Body.set_head_command({yaw, pitch_actual});

  local ball = wcm.get_ball();
  if (t - ball.t < 0.1) then
    return "ball";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end
