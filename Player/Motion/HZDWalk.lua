module(..., package.seeall);

require('Body')
require('Kinematics')
require('Config');
require('Config_OP_HZD')
require('vector')
require 'util'

-- Walk Parameters
hardnessLeg_gnd = Config.walk.hardnessLeg;
hardnessLeg_gnd[5] = 0; -- Ankle pitch is free moving
hardnessLeg_air = Config.walk.hardnessLeg;

function update( supportLeg )
  
  if( supportLeg == 0 ) then -- Left left on ground
    Body.set_lleg_hardness(hardnessLeg_gnd);
    Body.set_rleg_hardness(hardnessLeg_air);    
    stance_leg = Body.get_lleg_position();
    alpha = Config_OP_HZD.alpha_L;
  else
    Body.set_rleg_hardness(hardnessLeg_gnd);
    Body.set_lleg_hardness(hardnessLeg_air);    
    stance_leg = Body.get_rleg_position();
    alpha = Config_OP_HZD.alpha_R;
  end
  
  t = Body.get_time();
  
  theta = stance_leg[5]; -- Just use the ankle
  theta_min = 0.01294;
  theta_max = -0.3054;
  s = (theta - theta_min) / (theta_max - theta_min);
  
  qLegs = vector.zeros(12);
  for i=1,12 do
    qLegs[i] = util.polyval_bz(alpha[i], s);
  end

  Body.set_lleg_command(qLegs);


  jointNames = {"PelvYL", "PelvL", "Left_Hip_Pitch", "LegLowerL", "Left_Ankle_Pitch", "Left_Ankle_Roll", 
"PelvYR", "PelvR", "Right_Hip_Pitch", "LegLowerR", "AnkleR", "FootR",
             };
--  print('Joint ID: ', unpack(jointNames))
  for i=1,12 do
  print( jointNames[i] .. ': '..qLegs[i]*180/math.pi );
  end
  print();


end

function exit()
end

