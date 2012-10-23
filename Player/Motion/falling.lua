module(..., package.seeall);

require('Body')
require('walk')

t0 = 0;
timeout = Config.falling_timeout or 0.3;


qLArmFront = vector.new({45,9,-135})*math.pi/180;
qRArmFront = vector.new({45,-9,-135})*math.pi/180;

function entry()
  print(_NAME.." entry");

  -- relax all the joints while falling
  Body.set_body_hardness(0);

--[[
  --Ukemi motion (safe fall)
  local imuAngleY = Body.get_sensor_imuAngle(2);
  if (imuAngleY > 0) then --Front falling 
print("UKEMI FRONT")
    Body.set_larm_hardness({0.6,0,0.6});
    Body.set_rarm_hardness({0.6,0,0.6});
    Body.set_larm_command(qLArmFront);
    Body.set_rarm_command(qRArmFront);
  else
  end
--]]

  t0 = Body.get_time();
  Body.set_syncread_enable(1); --OP specific
  walk.stance_reset();--reset current stance
end

function update()
  local t = Body.get_time();
  -- set the robots command joint angles to thier current positions
  --  this is needed to that when the hardness is re-enabled
  if (t-t0 > timeout) then
    return "done"
  end
end

function exit()
  local qSensor = Body.get_sensor_position();
  Body.set_actuator_command(qSensor);
end
