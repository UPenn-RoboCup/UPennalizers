module(..., package.seeall);

require('Body')

t0 = 0;
tscan = 5.0;

yawMax = Config.head.yawMax;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
  headAngles = Body.get_head_position();
  if (headAngles[1] > 0) then
    direction = 1;
  else
    direction = -1;
  end

  -- continuously switch cameras
  vcm.set_camera_command(-1);
end

function update()
   local t = Body.get_time();

   local ph = (t-t0)/tscan;
   local yaw = direction*yawMax*math.cos(math.pi*ph);
   local pitch = 0;
   Body.set_head_command({yaw, pitch});

   if (t - t0 > tscan) then
    return 'done'
   end
end

function exit()
end
