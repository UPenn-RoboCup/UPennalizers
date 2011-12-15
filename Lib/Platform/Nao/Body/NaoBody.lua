module(..., package.seeall);
require('dcm');
require('vector');
require('unix');
require('util');

host = "dcm";

-- Time step in sec
tDelta = 0.010;

-- add gyro0 to dcm
gyro0 = {0, 0, 0};
if (not util.shm_key_exists(dcm.sensorShm, 'imuGyr0', #gyro0)) then
  dcm.sensorShm:set('imuGyr0', gyro0);
end

--Initialize dcm.
dcm.init();

--Copy dcm to local namespace
for k,v in pairs(dcm) do
  getfenv()[k] = v;
end

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


get_time = function() return dcm.get_sensor_time(1); end

function update()
end

-- setup convience functions
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

function set_indicator_state(color)
  set_actuator_ledChest(color)
end

function set_indicator_team(teamColor)
  if (teamColor == 1) then
    set_actuator_ledFootLeft({1, 0, 0});
  else
    set_actuator_ledFootLeft({0, 0, 1});
  end
end

function set_indicator_kickoff(kickoff)
  if (kickoff == 1) then
    set_actuator_ledFootRight({1, 1, 1});
  else
    set_actuator_ledFootRight({0, 0, 0});
  end
end

function set_indicator_batteryLevel(level)
  led = vector.ones(10);
  i = 1;
  while (i < 10-charge) do
    led[i] = 0;
    i = i+1;
  end
  
  set_actuator_ledEarsRight(led);
end

function set_indicator_role(role)
  if role == 1 then
    -- attack
    set_actuator_ledEarsLeft({0, 0, 0, 0, 0, 0, 0, 1, 1, 1});
  elseif role == 2 then
    -- defend
    set_actuator_ledEarsLeft({0, 0, 1, 1, 1, 0, 0, 0, 0, 0});
  elseif role == 3 then
    -- support
    set_actuator_ledEarsLeft({1, 1, 0, 0, 0, 0, 0, 0, 0, 1});
  elseif role == 0 then
    -- goalier
    set_actuator_ledEarsLeft({0, 0, 0, 0, 1, 1, 1, 0, 0, 0});
  else
    -- unkown role
    set_actuator_ledEarsLeft({0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
  end
end

function set_indicator_ball(color)
  -- color is a 3 element vector
  -- convention is all zero indicates no detection
  if (color[1] == 1 and color[2] == 0 and color[3] == 0) then
    Body.set_actuator_ledFaceRight(vector.ones(8), 1);
  else
    Body.set_actuator_ledFaceRight(vector.zeros(24));
  end
end

function set_indicator_goal(color)
  -- color is a 3 element vector
  -- convention is all zero indicates no detection
  if (color[1] == 1 and color[2] == 1 and color[3] == 0) then
    -- yellow
    set_actuator_ledFaceLeft(vector.zeros(24));
    set_actuator_ledFaceLeft(vector.ones(8), 9);
  elseif (color[1] == 0 and color[2] == 0 and color[3] == 1) then
    -- cyan 
    set_actuator_ledFaceLeft(vector.zeros(24));
    set_actuator_ledFaceLeft(vector.ones(8), 17);
  else
    set_actuator_ledFaceLeft(vector.zeros(24));
  end
end

function get_battery_level()
  -- return the battery level (0-10)
  charge = get_sensor_batteryCharge();
  charge = math.ceil(charge[1] * 10);
  return charge;
end

function get_change_state()
  return get_sensor_button()[1];
end

function get_change_enable()
  return 0;
end

function get_change_team()
  bumperLeft = get_sensor_bumperLeft();
  if (bumperLeft[1] == 1 and bumperLeft[2] == 1) then
    return 1;
  else
    return 0;
  end
end

function get_change_role()
  return 0;
end

function get_change_kickoff()
  bumperRight = get_sensor_bumperRight();
  if (bumperRight[1] == 1 and bumperRight[2] == 1) then
    return 1;
  else
    return 0;
  end
end


ccount = -1;
function calibrate(count)
  if (ccount == -1) then
    -- initialize calibration values
    gyro0sum = {0, 0};
    gyrocount = 0;
    gyroMax = {-math.huge, -math.huge};
    gyroMin = {math.huge, math.huge};
    gyroThreshold = 500;

    ccount = ccount + 1;
    return false;

  else
    if (ccount < 100) then 
      imuGyr = get_sensor_imuGyr();
      gyro0sum[1] = gyro0sum[1] + imuGyr[1];
      gyro0sum[2] = gyro0sum[2] + imuGyr[2];
      gyroMax[1] = math.max(gyroMax[1], math.abs(imuGyr[1]));
      gyroMax[2] = math.max(gyroMax[2], math.abs(imuGyr[2]));
      gyroMin[1] = math.min(gyroMin[1], math.abs(imuGyr[1]));
      gyroMin[2] = math.min(gyroMin[2], math.abs(imuGyr[2]));

      ccount = ccount + 1;
      return false;

    else
      gyroMag = (gyroMax[1]-gyroMin[1])^2 + (gyroMax[2]-gyroMin[2])^2;

      print('Gyro max: ', unpack(gyroMax))
      print('Gyro min: ', unpack(gyroMin))
      print('Gyro mag: ', gyroMag);

      if (gyroMag > gyroThreshold) then
        print('Recalibrating Gyro')
        ccount = -1;
        return false;

      else
        gyro0[1] = gyro0sum[1]/ccount;
        gyro0[2] = gyro0sum[2]/ccount;
        dcm.sensorShm:set('imuGyr0', {gyro0[1], gyro0[2], 0.0});
        print('Calibration done.');
        print('gyro0: ', unpack(gyro0));

        calibrating = false;
        return true;
      end
    end
  end
end


--SJ: normalize gyro values here
--Value should be Roll-pitch-yaw, in degree per seconds 
function get_sensor_imuGyrRPY()
  imuGyrRaw = get_sensor_imuGyr();
  gyro_roll = -(imuGyrRaw[1]-gyro0[1]);
  gyro_pitch = -(imuGyrRaw[2]-gyro0[2]);
  gyrRPY = vector.new({gyro_roll, gyro_pitch, 0});
  return gyrRPY;
end




-- dummy functions
function set_syncread_enable(val)
end
function set_lleg_slope(val)
end
function set_rleg_slope(val)
end



--[[
function 
for k,v in actuatorShm.next, actuatorShm do
  actuator[k] = carray.cast(actuatorShm:pointer(k));
  getfenv()["set_actuator_"..k] =
    function(val, index)
      return set_actuator_shm(k, val, index);
    end
end
--]]
