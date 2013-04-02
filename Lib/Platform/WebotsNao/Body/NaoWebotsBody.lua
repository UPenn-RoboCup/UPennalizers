module(..., package.seeall);
require('controller');

controller.wb_robot_init(); timeStep = controller.wb_robot_get_basic_time_step();
tDelta = .001*timeStep;

gps_enable = 0;

-- Get webots tags:
tags = {};
jointNames = {"HeadYaw", "HeadPitch",
              "LShoulderPitch", "LShoulderRoll",
              "LElbowYaw", "LElbowRoll",
              "LHipYawPitch", "LHipRoll", "LHipPitch",
              "LKneePitch", "LAnklePitch", "LAnkleRoll",
              "RHipYawPitch", "RHipRoll", "RHipPitch",
              "RKneePitch", "RAnklePitch", "RAnkleRoll",
              "RShoulderPitch", "RShoulderRoll",
              "RElbowYaw", "RElbowRoll"};

nJoint = #jointNames;
indexHead = 1;
nJointHead = 2;
indexLArm = 3;
nJointLArm = 4;
indexLLeg = 7;
nJointLLeg = 6;
indexRLeg = 13;
nJointRLeg = 6;
indexRArm = 19;
nJointRArm = 4;

tags.joints = {};
for i,v in ipairs(jointNames) do
  tags.joints[i] = controller.wb_robot_get_device(v);
  controller.wb_servo_enable_position(tags.joints[i], timeStep);
end

tags.accelerometer = controller.wb_robot_get_device("accelerometer");
controller.wb_accelerometer_enable(tags.accelerometer, timeStep);
tags.gyro = controller.wb_robot_get_device("gyro");
controller.wb_gyro_enable(tags.gyro, timeStep);
if gps_enable==1 then
  tags.gps = controller.wb_robot_get_device("GPS");
  controller.wb_gps_enable(tags.gps, timeStep);
  tags.compass = controller.wb_robot_get_device("Compass");
  controller.wb_compass_enable(tags.compass, timeStep);
end

controller.wb_robot_step(timeStep);

actuator = {};
actuator.command = {};
actuator.velocity = {};
actuator.position = {};
actuator.hardness = {};
for i = 1,nJoint do
  actuator.command[i] = 0;
  actuator.velocity[i] = 0;
  actuator.position[i] = 0;
  actuator.hardness[i] = 0;
end

function set_actuator_command(a, index)
  index = index or 1;
  if (type(a) == "number") then
    actuator.command[index] = a;
  else
    for i = 1,#a do
      actuator.command[index+i-1] = a[i];
    end
  end
end

get_time = controller.wb_robot_get_time;

function set_actuator_velocity(a, index)
  index = index or 1;
  if (type(a) == "number") then
    actuator.velocity[index] = a;
  else
    for i = 1,#a do
      actuator.velocity[index+i-1] = a[i];
    end
  end
end

function set_actuator_hardness(a, index)
  index = index or 1;
  if (type(a) == "number") then
    actuator.hardness[index] = a;
  else
    for i = 1,#a do
      actuator.hardness[index+i-1] = a[i];
    end
  end
end

function get_sensor_position(index)
  if (index) then
    return controller.wb_servo_get_position(tags.joints[index]);
  else
    local t = {};
    for i = 1,nJoint do
      t[i] = controller.wb_servo_get_position(tags.joints[i]);
    end
    return t;
  end
end

imuAngle = {0, 0};
aImuFilter = 1 - math.exp(-tDelta/0.5);
function get_sensor_imuAngle(index)
  if (not index) then
    return imuAngle;
  else
    return imuAngle[index];
  end
end

function get_sensor_button(index)
  local randThreshold = 0.001;
  if (math.random() < randThreshold) then
    return {1};
  else
    return {0};
  end
end



function get_head_position()
  local q = get_sensor_position();
  return {unpack(q, indexHead, indexHead+nJointHead-1)};
end
function get_larm_position()
  local q = get_sensor_position();
  return {unpack(q, indexLArm, indexLArm+nJointLArm-1)};
end
function get_rarm_position()
  local q = get_sensor_position();
  return {unpack(q, indexRArm, indexRArm+nJointRArm-1)};
end
function get_lleg_position()
  local q = get_sensor_position();
  return {unpack(q, indexLLeg, indexLLeg+nJointLLeg-1)};
end
function get_rleg_position()
  local q = get_sensor_position();
  return {unpack(q, indexRLeg, indexRLeg+nJointRLeg-1)};
end



function set_body_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJoint);
  end
  set_actuator_hardness(val);
end
function set_head_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointHead);
  end
  set_actuator_hardness(val, indexHead);
end
function set_larm_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointLArm);
  end
  set_actuator_hardness(val, indexLArm);
end
function set_rarm_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointRArm);
  end
  set_actuator_hardness(val, indexRArm);
end
function set_lleg_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointLLeg);
  end
  set_actuator_hardness(val, indexLLeg);
end
function set_rleg_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointRLeg);
  end
  set_actuator_hardness(val, indexRLeg);
end
function set_waist_hardness(val)
end

function set_head_command(val)
  set_actuator_command(val, indexHead);
end
function set_lleg_command(val)
  set_actuator_command(val, indexLLeg);
end
function set_rleg_command(val)
  set_actuator_command(val, indexRLeg);
end
function set_larm_command(val)
  set_actuator_command(val, indexLArm);
end
function set_rarm_command(val)
  set_actuator_command(val, indexRArm);
end
function set_waist_command(val)
end

-- dummy functions used by nsl
function set_syncread_enable(val)
end

function set_waist_command(val)
end

function set_waist_hardness(val)
end


function update()
  -- Set actuators
  for i = 1,nJoint do
    if actuator.hardness[i] > 0 then
      if actuator.velocity[i] > 0 then
        local delta = actuator.command[i] - actuator.position[i];
        local deltaMax = tDelta*actuator.velocity[i];
        if (delta > deltaMax) then
          delta = deltaMax;
        elseif (delta < -deltaMax) then
          delta = -deltaMax;
        end
        actuator.position[i] = actuator.position[i]+delta;
      else
	    actuator.position[i] = actuator.command[i];
      end
      controller.wb_servo_set_position(tags.joints[i],
                                        actuator.position[i]);
    end
  end

  if (controller.wb_robot_step(timeStep) < 0) then
    --Shut down controller:
    os.exit();
  end

  -- Process sensors
  accel = controller.wb_accelerometer_get_values(tags.accelerometer);
  gyro = controller.wb_gyro_get_values(tags.gyro);
  local gAccel = 9.80;
  accX = accel[2]/gAccel;
  accY = -accel[1]/gAccel;
  if ((accX > -1) and (accX < 1) and (accY > -1) and (accY < 1)) then
    imuAngle[1] = imuAngle[1] + aImuFilter*(math.asin(accX) - imuAngle[1]);
    imuAngle[2] = imuAngle[2] + aImuFilter*(math.asin(accY) - imuAngle[2]);
  end
end

-- Set API compliance functions
function set_indicator_state(color)
end

function set_indicator_team(teamColor)
end

function set_indicator_kickoff(kickoff)
end

function set_indicator_batteryLevel(level)
end

function set_indicator_role(role)
end

function set_indicator_ball(color)
  -- color is a 3 element vector
  -- convention is all zero indicates no detection
end

function set_indicator_goal(color)
  -- color is a 3 element vector
  -- convention is all zero indicates no detection
end

function get_battery_level()
  return 10;
end

function get_change_state()
  return 0;
end

function get_change_enable()
  return 0;
end

function get_change_team()
  return 0;
end

function get_change_role()
  return 0;
end

function get_change_kickoff()
  return 0;
end

-- OP does not have the UltraSound device
function set_actuator_us()
end

function get_sensor_usLeft()
  return vector.zeros(10);
end

function get_sensor_usRight()
  return vector.zeros(10);
end

-- Kick method API compliance for NSLKick
function set_lleg_slope(val)
end
function set_rleg_slope(val)
end

function get_sensor_imuGyr0()
  return vector.zeros(3)
end

function get_sensor_imuGyr( )
  gyro = controller.wb_gyro_get_values(tags.gyro);
  return gyro;
end

--Roll Pitch Yaw in degree per seconds
function get_sensor_imuGyrRPY( )
  --SJ: modified the controller wrapper function
  gyro = controller.wb_gyro_get_values(tags.gyro);
  -- From rad/s to DPS conversion
  gyro_proc={-gyro[1]*57.2, -gyro[2]*57.2,0};
  return gyro_proc;
end


function get_sensor_imuAcc( )
  accel = controller.wb_accelerometer_get_values(tags.accelerometer);
  return {accel[1]-512,accel[2]-512,0};
end

--[[
function get_sensor_gps( )
  --For DARwInOPGPS prototype 
  gps = controller.wb_gps_get_values(tags.gps);
  compass = controller.wb_compass_get_values(tags.compass);
  angle=math.atan2(compass[1],compass[3]);
  gps={gps[1],-gps[3],-angle};
--  print("Current gps pose:",gps[1],gps[2],gps[3]*180/math.pi)
  return gps;
end
--]]
