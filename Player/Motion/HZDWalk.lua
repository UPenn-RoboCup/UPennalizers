module(..., package.seeall);

require('Body')
require('Kinematics')
require('Config');
require('Config_OP_HZD')
require('vector')
require 'util'

t0 = Body.get_time();

-- Walk Parameters
hardnessLeg_gnd = Config.walk.hardnessLeg;
hardnessLeg_gnd[5] = 0; -- Ankle pitch is free moving
hardnessLeg_air = Config.walk.hardnessLeg;

-- For Debugging
saveCount = 0;
jointNames = {"Left_Hip_Yaw", "Left_Hip_Roll", "Left_Hip_Pitch", "Left_Knee_Pitch", "Left_Ankle_Pitch", "Left_Ankle_Roll", "Right_Hip_Yaw", "Right_Hip_Roll", "Right_Hip_Pitch", "Right_Knee_Pitch", "Right_Ankle_Pitch", "Right_Ankle_Roll"};
logfile_name = string.format("/tmp/joint_angles.raw");


function update( supportLeg, qLegs )

  if( supportLeg == 0 ) then -- Left left on ground
    Body.set_lleg_hardness(hardnessLeg_gnd);
    Body.set_rleg_hardness(hardnessLeg_air);    
    alpha = Config_OP_HZD.alpha_L;
    stance_ankle_id = 5;
  else
    Body.set_rleg_hardness(hardnessLeg_gnd);
    Body.set_lleg_hardness(hardnessLeg_air);    
    alpha = Config_OP_HZD.alpha_R;
    stance_ankle_id = 11;
  end
  
  t = Body.get_time();
  
  theta = qLegs[stance_ankle_id]; -- Just use the ankle
--[[--webots
  theta_max = -0.3527;
  theta_min = 0.2063;
--]]
  theta_max = -0.6776;
  theta_min = -0.1290;

  s = (theta - theta_min) / (theta_max - theta_min) ;

  if( s>1 ) then s = 1; end;
  if(s<0) then s = 0; end;
  
  for i=1,12 do
    if (i~=stance_ankle_id) then
      qLegs[i] = util.polyval_bz(alpha[i], s);
    end
  end

  -- Debug Printing in degrees
  print('Support Leg: ', supportLeg);
  print('theta: ', theta, ', s: ', s);
  for i=1,12 do
    print( jointNames[i] .. ':\t'..qLegs[i]*180/math.pi );
  end
  print();
  
  -- return the HZD qLegs
  return qLegs;

end

function record_joint_angles( supportLeg )

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
  local lleg = Body.get_lleg_position();
  for i=1,6 do
    f:write( string.format(",%f",lleg[i]) );
  end
  local rleg = Body.get_rleg_position();
  for i=1,6 do
    f:write( string.format(",%f",rleg[i]) );
  end
  f:write( "\n" );
  -- Close the file
  f:close();
  saveCount = saveCount + 1;

end

