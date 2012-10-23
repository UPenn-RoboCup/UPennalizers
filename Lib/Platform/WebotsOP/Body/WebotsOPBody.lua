module(..., package.seeall);
require('controller');
require('Transform');

controller.wb_robot_init();
timeStep = controller.wb_robot_get_basic_time_step();
tDelta = .001*timeStep;
imuAngle = {0, 0, 0};
aImuFilter = 1 - math.exp(-tDelta/0.5);

gps_enable = 0;

-- Get webots tags:
tags = {};

-- DarwinOP names in webots
jointNames = {"Neck", "Head",
              "ShoulderL", "ArmUpperL", "ArmLowerL",
              "PelvYL", "PelvL", "LegUpperL", "LegLowerL", "AnkleL", "FootL", 
              "PelvYR", "PelvR", "LegUpperR", "LegLowerR", "AnkleR", "FootR",
              "ShoulderR", "ArmUpperR", "ArmLowerR",
             };

nJoint = #jointNames;
indexHead = 1;			--Head: 1 2
nJointHead = 2;
indexLArm = 3;			--LArm: 3 4 5 
nJointLArm = 3; 		
indexLLeg = 6;			--LLeg:6 7 8 9 10 11
nJointLLeg = 6;
indexRLeg = 12; 		--RLeg: 12 13 14 15 16 17
nJointRLeg = 6;
indexRArm = 18; 		--RArm: 18 19 20
nJointRArm = 3;

jointReverse={
	1,--Head: 1,2
	--LArm: 3,4,5
	7,8,9,--LLeg: 6,7,8,9,10,11,
	16,--RLeg: 12,13,14,15,16,17
	18,20--RArm: 18,19,20
}

jointBias={
	0,0,
	-math.pi/2,0,math.pi/2,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	-math.pi/2,0,math.pi/2,
}

moveDir={};
for i=1,nJoint do moveDir[i]=1; end
for i=1,#jointReverse do moveDir[jointReverse[i]]=-1; end


tags.joints = {};
for i,v in ipairs(jointNames) do
  tags.joints[i] = controller.wb_robot_get_device(v);
  controller.wb_servo_enable_position(tags.joints[i], timeStep);
end

tags.accelerometer = controller.wb_robot_get_device("Accelerometer");
controller.wb_accelerometer_enable(tags.accelerometer, timeStep);
tags.gyro = controller.wb_robot_get_device("Gyro");
controller.wb_gyro_enable(tags.gyro, timeStep);
if( gps_enable>0 ) then
  tags.gps = controller.wb_robot_get_device("GPS");
  controller.wb_gps_enable(tags.gps, timeStep);
  tags.compass = controller.wb_robot_get_device("Compass");
  controller.wb_compass_enable(tags.compass, timeStep);
end

tags.eyeled = controller.wb_robot_get_device("EyeLed");
controller.wb_led_set(tags.eyeled,0xffffff)
tags.headled = controller.wb_robot_get_device("HeadLed");
controller.wb_led_set(tags.headled,0x00ff00);

--[[
-- Add Bumper Touch sensors
tags.bumpL = controller.wb_robot_get_device("footL_touch");
controller.wb_touch_sensor_enable(tags.bumpL, timeStep);
tags.bumpR = controller.wb_robot_get_device("footR_touch");
controller.wb_touch_sensor_enable(tags.bumpR, timeStep);
--]]

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
    actuator.command[index] = moveDir[index]*(a+jointBias[index]);
  else
    for i = 1,#a do
      actuator.command[index+i-1] = moveDir[index+i-1]*(a[i]+jointBias[index+i-1]);
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
    return moveDir[index]*controller.wb_servo_get_position(tags.joints[index])-jointBias[index];
  else
    local t = {};
    for i = 1,nJoint do
      t[i] = moveDir[i]*controller.wb_servo_get_position(tags.joints[i])-jointBias[i];
    end
    return t;
  end
end

function get_sensor_imuAngle(index)
  if (not index) then
    return imuAngle;
  else
    return imuAngle[index];
  end
end

-- Two buttons in the array
function get_sensor_button(index)
  return {0,0};
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

function update()

  if( gps_enable>0 ) then
    get_sensor_gps()
  end

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
  update_IMU();

--[[
  -- Bumper Touch Sensor
  bumpL = controller.wb_touch_sensor_get_value( tags.bumpL );
  bumpR = controller.wb_touch_sensor_get_value( tags.bumpR );
--]]

end

function update_IMU()
    
  acc=get_sensor_imuAcc();
  gyr=get_sensor_imuGyrRPY();

  local tTrans = Transform.rotZ(imuAngle[3]);
  tTrans= tTrans * Transform.rotY(imuAngle[2]);
  tTrans= tTrans * Transform.rotX(imuAngle[1]);

  gyrFactor = 0.6;--heuristic value
  gyrDelta = vector.new(gyr)*math.pi/180*tDelta*gyrFactor;

  local tTransDelta = Transform.rotZ(gyrDelta[3]);
  tTransDelta= tTransDelta * Transform.rotY(gyrDelta[2]);
  tTransDelta= tTransDelta * Transform.rotX(gyrDelta[1]);

  tTrans=tTrans*tTransDelta;
  imuAngle = Transform.getRPY(tTrans);

  local accMag = acc[1]^2+acc[2]^2+acc[3]^2;
  if accMag>0.8 and accMag<1 then
    local angR=math.asin(-acc[2]);
    local angP=math.asin(acc[1]);
    imuAngle[1] = imuAngle[1] + aImuFilter*(angR - imuAngle[1]);
    imuAngle[2] = imuAngle[2] + aImuFilter*(angP - imuAngle[2]);
  end

--  print("RPY:",unpack(imuAngle*180/math.pi))
end

-- Extra for compatibility
function set_syncread_enable(val)
end

function set_actuator_eyeled( val )
end

function set_waist_hardness( val )
end

function set_waist_command( val )
end

function set_aux_hardness( val )
end

function set_aux_command( val )
end

function get_sensor_imuGyr0()
  return vector.zeros(3)
end

function get_sensor_imuGyr( )
  return get_sensor_imuGyrRPY();
end

--Roll, Pitch Yaw angles in degree per seconds unit 
function get_sensor_imuGyrRPY( )
  gyro = controller.wb_gyro_get_values(tags.gyro);
  --Checked with webots OP model
  gyro_proc={-(gyro[1]-512)/0.273, -(gyro[2]-512)/0.273,(gyro[3]-512)/0.273};
  return gyro_proc;
end

--Acceleration in X,Y,Z axis in g unit
function get_sensor_imuAcc( )
  accel = controller.wb_accelerometer_get_values(tags.accelerometer);
  --Checked with webots OP model
  return {-(accel[2]-512)/128,-(accel[1]-512)/128,(accel[3]-512)/128};
end

function set_actuator_eyeled(color)
  --input color is 0 to 31, so multiply by 8 to make 0-255
  code= color[1] * 0x80000 + color[2] * 0x800 + color[3]*8;
  controller.wb_led_set(tags.eyeled,code)
end

function set_actuator_headled(color)
  --input color is 0 to 31, so multiply by 8 to make 0-255
  code= color[1] * 0x80000 + color[2] * 0x800 + color[3]*8;
  controller.wb_led_set(tags.headled,code)
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
  if( color[1]==0 and color[2]==0 and color[3]==0 ) then
    set_actuator_eyeled({15,15,15});
  else
    set_actuator_eyeled({31*color[1],31*color[2],31*color[3]});
  end
end

function set_indicator_goal(color)
  -- color is a 3 element vector
  -- convention is all zero indicates no detection
  if( color[1]==0 and color[2]==0 and color[3]==0 ) then
    set_actuator_headled({15,15,15});
  else
    set_actuator_headled({31*color[1],31*color[2],31*color[3]});
  end

end

function get_battery_level()
  return 120;
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

function set_lleg_slope(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointLLeg);
  end
  set_actuator_slope(val, indexLLeg);
  set_actuator_slopeChanged(1,1);
end
function set_rleg_slope(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointRLeg);
  end
  set_actuator_slope(val, indexRLeg);
  set_actuator_slopeChanged(1,1);
end


-- Kick method API compliance for NSLKick
function set_lleg_slope(val)
end
function set_rleg_slope(val)
end

-- Gripper method needed
function set_gripper_hardness(val)
end
function set_gripper_command(val)
end


function get_sensor_gps( )
  --For DARwInOPGPS prototype 
  gps = controller.wb_gps_get_values(tags.gps);
  compass = controller.wb_compass_get_values(tags.compass);
  angle=math.atan2(compass[1],compass[3]);
  gps={gps[1],-gps[3],-angle};
--  print("Current gps pose:",gps[1],gps[2],gps[3]*180/math.pi)
  return gps;
end

function get_sensor_fsrRight()
  fsr = {0};
  return fsr
end

function get_sensor_fsrLeft()
  fsr = {0};
  return fsr
end
