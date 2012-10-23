module(..., package.seeall);
--require('dcm');
require('vector');
require('unix');
require('util');


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


get_time = function() return 0; end

function update()
end

-- all  get functions will return zero, and all set functions are empty.
function get_head_position()
  return {0,0};
end
function get_larm_position()
  return 0;
end
function get_rarm_position()
  return 0;
end
function get_lleg_position()
  return 0;
end
function get_rleg_position()
  return 0;
end



function set_body_hardness(val)
end

function set_head_hardness(val)
end

function set_larm_hardness(val)
end

function set_rarm_hardness(val)
end

function set_lleg_hardness(val)
end

function set_rleg_hardness(val)
end

function set_waist_hardness(val)
end


function set_head_command(val)
end

function set_lleg_command(val)
end

function set_rleg_command(val)
end

function set_larm_command(val)
end

function set_rarm_command(val)
end

function set_waist_command(val)
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
end

function set_indicator_goal(color)

end

function get_battery_level()
  return 0;
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


ccount = -1;
function calibrate(count)
end


--SJ: normalize gyro values here
--Value should be Roll-pitch-yaw, in degree per seconds 
function get_sensor_imuGyrRPY()
  return 0;
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
