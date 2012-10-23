--SJ: New headSweep using camera inverse kinematics

module(..., package.seeall);

require('Body')

t0 = 0; 
tScan = Config.fsm.headSweep.tScan; 
yawMag = Config.head.yawMax;
dist = Config.fsm.headReady.dist;

function entry()
print("headSweep entry")
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
  local height=vcm.get_camera_height();
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
