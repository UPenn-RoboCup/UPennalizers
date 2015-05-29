module(..., package.seeall);

require('Body')
require('walk')
require('vcm')

t0 = 0;
timeout = Config.falling_timeout or 0.3;
qLArmFront = vector.new({45,9,-135})*math.pi/180;
qRArmFront = vector.new({45,-9,-135})*math.pi/180;


--Prepare the body to safely fall. This primarily involves setting all joints
--to zero hardness, so that the motors will be safe after the fall.
function entry()
  print(_NAME.." entry");

  -- relax all the joints while falling
  Body.set_body_hardness(0);

  t0 = Body.get_time();
  -- Body.set_syncread_enable(1); --OP specific
  walk.stance_reset(); --reset current stance
  --vcm.set_vision_enable(0);
end

--Update the body after the fall has occurred. This is primarily used to set
--the actuator commands to the values of the motors in the robot's position
--after it has completed its fall.
function update()
  local t = Body.get_time();
  -- set the robots command joint angles to thier current positions
  --  this is needed to that when the hardness is re-enabled
  if Config.enable_getup then
    if (t-t0 > timeout) then
      return "done"
    end
  else
    local imuAngle = Body.get_sensor_imuAngle()
    print("imuangle: ",imuAngle[1]*180/math.pi,imuAngle[2]*180/math.pi)

    if math.abs(imuAngle[1]) < 45*math.pi/180 and math.abs(imuAngle[2]) < 45*math.pi/180 then
      return "restand"
    end
  end
end

function exit()
  local qSensor = Body.get_sensor_position();
  Body.set_actuator_command(qSensor);
end
