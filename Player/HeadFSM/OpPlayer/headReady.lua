module(..., package.seeall);
--SJ: camera IK based constant sweeping

require('Body')

t0 = 0;
tscan = 5.0*Config.speedFactor;
dist = 3.0;
height = 0.5;
yawMag = Config.head.yawMax;


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

--IK based horizon following
   local yaw0 = direction*(ph-0.5)*2*yawMag;
   local yaw, pitch =HeadTransform.ikineCam(
	dist*math.cos(yaw0),dist*math.sin(yaw0), height);

   Body.set_head_command({yaw, pitch});

   if (t - t0 > tscan) then
    return 'done'
   end
end

function exit()
end
