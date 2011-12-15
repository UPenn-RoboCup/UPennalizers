--SJ: New headSweep using camera inverse kinematics

module(..., package.seeall);

require('Body')

t0 = 0;
tScan = 1.0;
tScan = tScan * Config.speedFactor;

yawMag = Config.head.yawMax;

dist = 3.0;
height = 0.5;

function entry()
  print(_NAME..' entry');

  t0 = Body.get_time();
  headAngles = Body.get_head_position();
  if (headAngles[1] > 0) then
    direction = 1;
  else
    direction = -1;
  end
end

function update()
  local t = Body.get_time();

  local ph = (t-t0)/tScan;
  local yaw0 = direction*(ph-0.5)*2*yawMag;
  local yaw, pitch =HeadTransform.ikineCam(
	dist*math.cos(yaw0),dist*math.sin(yaw0), height);

  Body.set_head_command({yaw, pitch});

  if (t - t0 > tScan) then
    return 'done';
  end
end

function exit()
end
