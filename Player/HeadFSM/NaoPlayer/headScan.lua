module(..., package.seeall);

require('Body')

t0 = 0;

-- scan period
tscan = Config.fsm.headScan.tScan;
timeout = 2*tscan;

pitch0 = 0.24;
pitchMag = 0.21;
yawMag = Config.head.yawMax;

direction = 1;

function entry()
  print(_NAME.." entry");

  -- start scan in ball's last known direction
  t0 = Body.get_time();
  ball = wcm.get_ball();
  if (ball.y > 0) then
    direction = 1;
  else
    direction = -1;
  end

  -- continuously switch cameras
  vcm.set_camera_command(-1);
end

function update()
  local t = Body.get_time();

  -- update head position
  -- continuously scanning left-right and up-down
  local ph = 2*math.pi*(t-t0)/tscan;

  local yaw = yawMag*direction*math.sin(ph);
  local pitch = pitch0 + pitchMag*math.cos(ph);
  Body.set_head_command({yaw, pitch});


  local ball = wcm.get_ball();
  if (t - ball.t < 0.5) then
    return "ball";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end
