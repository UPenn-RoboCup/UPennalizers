module(..., package.seeall);

require('Body')
require('Config')
require('vcm')

t0 = 0;
timeout = 1.5;

pitch = 0.0;

yawMin = Config.head.yawMin;
yawMax = Config.head.yawMax;


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();

  attackAngle = wcm.get_attack_angle();
  defendAngle = wcm.get_defend_angle();
  attackClosest = math.abs(attackAngle) < math.abs(defendAngle);
 
  -- only use top camera
  vcm.set_camera_command(-1);
end

function update()
  local t = Body.get_time();

  if attackClosest then
    yaw = wcm.get_attack_angle();
  else
    yaw = wcm.get_defend_angle();
  end

  yaw = math.min(math.max(yaw, yawMin), yawMax);
  
  Body.set_head_command({yaw, pitch});

  if (t - t0 > timeout) then
    tGoal = wcm.get_goal_t();
    if (tGoal - t0 > 0) then
      return 'timeout';
    else
      return 'lost';
    end
  end
end

function exit()
end

