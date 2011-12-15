module(..., package.seeall);

require('Body')
require('Config')
require('vcm')

t0 = 0;
timeout = 1.5*Config.speedFactor;

yawMax = Config.head.yawMax;

dist = 3.0;
height = 0.5;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();

  attackAngle = wcm.get_attack_angle();
  defendAngle = wcm.get_defend_angle();
  attackClosest = math.abs(attackAngle) < math.abs(defendAngle);
 
  -- only use top camera
  vcm.set_camera_command(0);
end

function update()
  local t = Body.get_time();

  if attackClosest then
    yaw0 = wcm.get_attack_angle();
  else
    yaw0 = wcm.get_defend_angle();
  end

  yawbias = 0;
  yaw1 = math.min(math.max(yaw0+yawbias, yawMin), yawMax);
  local yaw, pitch =HeadTransform.ikineCam(
	dist*math.cos(yaw1),dist*math.sin(yaw1), height);
  
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

