module(..., package.seeall);

require('Body')
require('Kinematics')
require('Config');
require('Config_OP_HZD')
require('vector')
require 'util'

t0 = Body.get_time();

-- Suport the Walk API
velCurrent = vector.new({0, 0, 0});
stopRequest = 0;
uLeft = vector.new({0, 0, 0});
uRight = vector.new({0, 0, 0});

-- Walk Parameters
--hardnessLeg_gnd = Config.walk.hardnessLeg;
hardnessLeg_gnd = vector.new({1,1,1,1,1,1});
--hardnessLeg_gnd = vector.new({.1,.1,.1,.1,.1,.1});
hardnessLeg_gnd[5] = 0; -- Ankle pitch is free moving
--hardnessLeg_air = Config.walk.hardnessLeg;
hardnessLeg_air = vector.new({1,1,1,1,1,1});
--hardnessLeg_air = vector.new({.1,.1,.1,.1,.1,.1});


-- For Debugging
saveCount = 0;
jointNames = {"Left_Hip_Yaw", "Left_Hip_Roll", "Left_Hip_Pitch", "Left_Knee_Pitch", "Left_Ankle_Pitch", "Left_Ankle_Roll", "Right_Hip_Yaw", "Right_Hip_Roll", "Right_Hip_Pitch", "Right_Knee_Pitch", "Right_Ankle_Pitch", "Right_Ankle_Roll"};
logfile_name = string.format("/tmp/joint_angles.raw");
stance_ankle_id = 5;
air_ankle_id = 11;
supportLeg = 0;
beta = .2;
qLegs = Body.get_lleg_position();

function entry()
  Body.set_syncread_enable( 3 );
  supportLeg = 0;
  qLegs = Body.get_lleg_position();
  theta_running = qLegs[stance_ankle_id];
end

entry();

function update( )
  t = Body.get_time();
  -- Read the ankle joint value
  qLegs = Body.get_lleg_position();
  qLegs2 = Body.get_rleg_position();
  for i=1,6 do
    qLegs[i+6] = qLegs2[i];
  end

  if( supportLeg == 0 ) then -- Left left on ground
    Body.set_lleg_hardness(hardnessLeg_gnd);
    Body.set_rleg_hardness(hardnessLeg_air);    
    alpha = Config_OP_HZD.alpha_L;
    stance_ankle_id = 5;
    air_ankle_id = 11;
    theta_min = Config_OP_HZD.theta_min_L;
    theta_max = Config_OP_HZD.theta_max_L;
  else
    Body.set_rleg_hardness(hardnessLeg_gnd);
    Body.set_lleg_hardness(hardnessLeg_air);    
    alpha = Config_OP_HZD.alpha_R;
    -- Read the ankle joint value
    stance_ankle_id = 11;
    air_ankle_id = 5;
    theta_min = Config_OP_HZD.theta_min_R;
    theta_max = Config_OP_HZD.theta_max_R;
  end

   
  theta = qLegs[stance_ankle_id]; -- Just use the stance ankle
  theta_running = beta*theta + (1-beta)*theta_running
  
--[[--webots
  theta_max = -0.3527;
  theta_min = 0.2063;
--]]
--[[
  theta_max = -0.3458;
  theta_min = -0.2003;
--]]

  s = (theta - theta_min) / (theta_max - theta_min) ;

  local hyst = 0.02;
  if( s>(1-hyst) ) then
    switchLeg = 1;
    s = 1;
  end
  if(s<hyst) then
    supportLeg = 1 - supportLeg;
    s = 0;
  end;

  if( switchLeg == 1 ) then
    switchLeg = 0;
    supportLeg = 1 - supportLeg;
    theta_running = qLegs[air_ankle_id];    
  end

  for i=1,12 do
    if (i~=stance_ankle_id) then
      qLegs[i] = util.polyval_bz(alpha[i], s);
    end
  end

  -- Debug Printing in degrees
  print();
  print('Support Leg: ', supportLeg);
  print('theta: ', theta, ', s: ', s);
--[[
  for i=1,12 do
    print( jointNames[i] .. ':\t'..qLegs[i]*180/math.pi );
  end
--]]

  Body.set_lleg_command(qLegs);
  -- return the HZD qLegs
  return qLegs;

end

function record_joint_angles( supportLeg, qlegs )

  -- Open the file
  local f = io.open(logfile_name, "a");
  assert(f, "Could not open save image file");
  if( saveCount == 0 ) then
    -- Write the Header
    f:write( "time,LeftOnGnd,RightOnGnd,IMU_Roll,IMU_Pitch,IMU_Yaw" );
    for i=1,12 do
      f:write( string.format(",%s",jointNames[i]) );
    end
    f:write( "\n" );
  end

  -- Write the data
  local t = Body.get_time();
  f:write( string.format("%f",t-t0) );
  f:write( string.format(",%d,%d",1-supportLeg,supportLeg) );
  local imuAngle = Body.get_sensor_imuAngle();
  f:write( string.format(",%f,%f,%f",unpack(imuAngle)) );
  -- Read the joint values
--[[
  qLegs = Body.get_lleg_position();
  qLegs2 = Body.get_rleg_position();
  for i=1,6 do
    qLegs[i+6] = qLegs2[i];
  end
--]]
  for i=1,12 do
    f:write( string.format(",%f",qlegs[i]) );
  end
  f:write( "\n" );
  -- Close the file
  f:close();
  saveCount = saveCount + 1;

end

-- Walk API functions
function set_velocity(vx, vy, vz)
end

function stop()
  stopRequest = math.max(1,stopRequest);
end

function stopAlign()
  stop()
end

--dummy function for NSL kick
function zero_velocity()
end

function start()
--  stopRequest = false;
  stopRequest = 0;
  if (not active) then
    active = true;
    iStep0 = -1;
    t0 = Body.get_time();
    initdone=false;
    delaycount=0;
    initial_step=1;
  end
end

function get_velocity()
  return velCurrent;
end

function exit()
end

function get_odometry(u0)
  return vector.new({0,0,0}),vector.new({0,0,0});
end
   
function get_body_offset()
  return {0,0,0}; 
end

