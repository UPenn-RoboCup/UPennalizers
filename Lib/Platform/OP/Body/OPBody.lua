module(..., package.seeall);
controller = require('dcm');
require('vector');
require('unix');

host = "dcm";

-- Time step in sec
tDelta = 0.010;

for k,v in pairs(dcm) do
  getfenv()[k] = v;
end

-- I don't think we use these joint names ever
--[[
jointNames = {"HeadYaw", "HeadPitch",
              "LShoulderPitch", "LShoulderRoll",
              "LElbowYaw", "LElbowRoll",
              "LHipYawPitch", "LHipRoll", "LHipPitch",
              "LKneePitch", "LAnklePitch", "LAnkleRoll",
              "RHipYawPitch", "RHipRoll", "RHipPitch",
              "RKneePitch", "RAnklePitch", "RAnkleRoll",
              "RShoulderPitch", "RShoulderRoll",
              "RElbowYaw", "RElbowRoll"};

----]]

nJoint = controller.nJoint; --DLC

indexHead = 1;			--Head: 1 2
nJointHead = 2;
indexLArm = 3;			--LArm: 3 4 5 
nJointLArm = 3; 		
indexLLeg = 6;			--LLeg: 6 7 8 9 10 11
nJointLLeg = 6;
indexRLeg = 12; 		--RLeg: 12 13 14 15 16 17
nJointRLeg = 6;
indexRArm = 18; 		--RArm: 18 19 20
nJointRArm = 3; 

--Aux servo (for gripper / etc)
indexAux= 21; 
nJointAux=nJoint-20; 

--get_time = function() return dcm.get_sensor_time(1); end
get_time = unix.time; --DLC specific

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


function set_waist_hardness(val)

end

function set_lleg_pid(val)
  --Usage: {P gain, I gain, D gain}

  p_param = val[1]*vector.ones(nJointLLeg);
  i_param = val[2]*vector.ones(nJointLLeg);
  d_param = val[3]*vector.ones(nJointLLeg);

  set_actuator_p_param(p_param,indexLLeg);
  set_actuator_i_param(i_param,indexLLeg);
  set_actuator_d_param(d_param,indexLLeg);
  set_actuator_slopeChanged(1,1);
end

function set_rleg_pid(val)
  --Usage: {P gain, I gain, D gain}
  p_param = val[1]*vector.ones(nJointRLeg);
  i_param = val[2]*vector.ones(nJointRLeg);
  d_param = val[3]*vector.ones(nJointRLeg);

  set_actuator_p_param(p_param,indexRLeg);
  set_actuator_i_param(i_param,indexRLeg);
  set_actuator_d_param(d_param,indexRLeg);

  set_actuator_slopeChanged(1,1);
end

function set_body_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJoint);
  end
  set_actuator_hardness(val);
  set_actuator_hardnessChanged(1);
end
function set_head_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointHead);
  end
  set_actuator_hardness(val, indexHead);
  set_actuator_hardnessChanged(1);

end
function set_larm_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointLArm);
  end
  set_actuator_hardness(val, indexLArm);
  set_actuator_hardnessChanged(1);

end
function set_rarm_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointRArm);
  end
  set_actuator_hardness(val, indexRArm);  
  set_actuator_hardnessChanged(1);
end
function set_lleg_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointLLeg);
  end
  set_actuator_hardness(val, indexLLeg);
  set_actuator_hardnessChanged(1);

end
function set_rleg_hardness(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointRLeg);
  end
  set_actuator_hardness(val, indexRLeg);
  set_actuator_hardnessChanged(1);
end

function set_aux_hardness(val)
  if nJointAux==0 then return;end
  if (type(val) == "number") then
    val = val*vector.ones(nJointAux);
  end
  set_actuator_hardness(val, indexAux);
  set_actuator_hardnessChanged(1);
end

function set_waist_command(val)
  --Do nothing
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

function set_aux_command(val)
  if nJointAux==0 then return;end
  set_actuator_command(val, indexAux);
end

--Added by SJ
function set_syncread_enable(val) 
  set_actuator_readType(val);
end

function set_lleg_slope(val)
  if (type(val) == "number") then
    val = val*vector.ones(nJointLLeg);
  end
  set_actuator_gain(val, indexLLeg);
  set_actuator_gainChanged(1,1);
end

function set_rleg_slope(val)
  --Now val==0 for regular p gain
  --    val==1 for stiff p gain (for kicking

  if (type(val) == "number") then
    val = val*vector.ones(nJointRLeg);
  end
  set_actuator_gain(val, indexRLeg);
  set_actuator_gainChanged(1,1);
end

function set_torque_enable(val)
  set_actuator_torqueEnable(val);
  set_actuator_torqueEnableChanged(1);
end

-- Set API compliance functions
function get_sensor_imuGyr0()
  return vector.zeros(3)
end

--Added function for nao
--returns gyro values in RPY, degree per seconds unit
function get_sensor_imuGyrRPY()
  return get_sensor_imuGyr();
end

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
  --Body.set_actuator_headled({0,0,0});
  color[1] = 31*color[1];
  color[2] = 31*color[2];
  color[3] = 31*color[3];
  Body.set_actuator_eyeled( color );
end

function set_indicator_goal(color)
  -- color is a 3 element vector
  -- convention is all zero indicates no detection
  color[1] = 31*color[1];
  color[2] = 31*color[2];
  color[3] = 31*color[3];
  Body.set_actuator_headled(color);
  --Body.set_actuator_eyeled({0,0,0});
end

function get_battery_level()
  batt=get_sensor_battery();
  return batt[1]/10;
end

function get_change_state()
  local b = get_sensor_button();
  return b[1];
end

function get_change_enable()
  return 0;
end

function get_change_team()
  return 0;
end

function get_change_role()
  local b = get_sensor_button();
  return b[2];
end

function get_change_kickoff()
  return 0;
end

-- OP doe not have the UltraSound device
function set_actuator_us()
end

function get_sensor_usLeft()
  return vector.zeros(10);
end

function get_sensor_usRight()
  return vector.zeros(10);
end

function calibrate( count )
  return true
end

function get_sensor_fsrRight()
  fsr = {0};
  return fsr
end

function get_sensor_fsrLeft()
  fsr = {0};
  return fsr
end

