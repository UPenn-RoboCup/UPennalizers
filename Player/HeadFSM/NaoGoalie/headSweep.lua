module(..., package.seeall);

require('Body')

t0 = 0;
tscan = 2.0;
yawMag = Config.head.yawMax;
pitch = 0.0;

function entry()
  print(_NAME..' entry');

  t0 = Body.get_time();
  headAngles = Body.get_head_position();
  if (headAngles[1] > 0) then
    direction = 1;
  else
    direction = -1;
  end

   -- only use top camera
  vcm.set_camera_command(0);
end

function update()
  local t = Body.get_time();

  local ph = (t-t0)/tscan;
  local yaw = direction*yawMag*math.cos(math.pi*ph);
  Body.set_head_command({yaw, pitch});

  if (t - t0 > tscan) then
    return 'done';
  end
end

function exit()
end
