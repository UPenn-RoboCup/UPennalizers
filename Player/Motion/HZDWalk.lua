module(..., package.seeall);

require('Body')
require('Kinematics')
require('Config');
require('Config_OP_HZD')
require('vector')

-- Walk Parameters
bodyHeight = Config.walk.bodyHeight;
footY = Config.walk.footY;
supportX = Config.walk.supportX;
supportY = Config.walk.supportY;
bodyTilt=Config.walk.bodyTilt;
qLArm=Config.walk.qLArm;
qRArm=Config.walk.qRArm;

tStep = Config.walk.tStep;
tZmp = Config.walk.tZmp;
stepHeight = Config.walk.stepHeight;
hipRollCompensation = Config.walk.hipRollCompensation;
hipPitchCompensation = Config.walk.hipPitchCompensation;
hardnessArm=Config.walk.hardnessArm;
hardnessLeg=Config.walk.hardnessLeg;

stanceLimitX=Config.walk.stanceLimitX;
stanceLimitY=Config.walk.stanceLimitY;
stanceLimitA=Config.walk.stanceLimitA;
velLimitX=Config.walk.velLimitX;
velLimitY=Config.walk.velLimitY;
velLimitA=Config.walk.velLimitA;

--Feedback parameters
torsoSensorParamX=Config.walk.torsoSensorParamX;
torsoSensorParamY=Config.walk.torsoSensorParamY;
tSensorDelay = Config.walk.tSensorDelay;

ankleImuParamX=Config.walk.ankleImuParamX;
ankleImuParamY=Config.walk.ankleImuParamY;
hipImuParamY=Config.walk.hipImuParamY;
kneeImuParamX=Config.walk.kneeImuParamX;

--Single support phases
ph1Single = Config.walk.phSingle[1];
ph2Single = Config.walk.phSingle[2];

--ZMP shift phases
ph1Zmp = ph1Single;
ph2Zmp = ph2Single;

--Foot and torso poses
uTorso = vector.new({supportX, 0, 0});
uLeft = vector.new({0, footY, 0});
uRight = vector.new({0, -footY, 0});
pLLeg = vector.new({0, footY, 0, 0,0,0});
pRLeg = vector.new({0, -footY, 0, 0,0,0});
pTorso = vector.new({supportX, 0, bodyHeight, 0,0,0});

--Stabilization variables
uTorsoShift = vector.new({0, 0, 0});
ankleShift = vector.new({0, 0});
kneeShift = vector.new({0});
hipShift = vector.new({0,0});

--Hip servo compensation variables
qLHipRollCompensation = 0;
qRHipRollCompensation = 0;
qLHipPitchCompensation = 0;	
qRHipPitchCompensation = 0;

--ZMP exponential coefficients:
aXP, aXN, aYP, aYN = 0,0,0,0;

--Walk state variables
velCurrent = vector.new({0, 0, 0});
t0 = 0;
iStep0 = -1;
enable=true;
active = true;
stopRequest = 0;

function zmp_solve(zs, z1, z2, x1, x2)
  --[[
    Solves ZMP equation:
    x(t) = z(t) + aP*exp(t/tZmp) + aN*exp(-t/tZmp) - tZmp*mi*sinh((t-Ti)/tZmp)
    where the ZMP point is piecewise linear:
    z(0) = z1, z(T1 < t < T2) = zs, z(tStep) = z2
  --]]
  local T1 = tStep*ph1Zmp;
  local T2 = tStep*ph2Zmp;
  local m1 = (zs-z1)/T1;
  local m2 = -(zs-z2)/(tStep-T2);

  local c1 = x1-z1+tZmp*m1*math.sinh(-T1/tZmp);
  local c2 = x2-z2+tZmp*m2*math.sinh((tStep-T2)/tZmp);
  local expTStep = math.exp(tStep/tZmp);
  local aP = (c2 - c1/expTStep)/(expTStep-1/expTStep);
  local aN = (c1*expTStep - c2)/(expTStep-1/expTStep);
  return aP, aN;
end

function zmp_com(ph)
  local com = vector.new({0, 0, 0});
  expT = math.exp(tStep*ph/tZmp);
  com[1] = uSupport[1] + aXP*expT + aXN/expT;
  com[2] = uSupport[2] + aYP*expT + aYN/expT;
  if (ph < ph1Zmp) then
    com[1] = com[1] + m1X*tStep*(ph-ph1Zmp)
              -tZmp*m1X*math.sinh(tStep*(ph-ph1Zmp)/tZmp);
    com[2] = com[2] + m1Y*tStep*(ph-ph1Zmp)
              -tZmp*m1Y*math.sinh(tStep*(ph-ph1Zmp)/tZmp);
  elseif (ph > ph2Zmp) then
    com[1] = com[1] + m2X*tStep*(ph-ph2Zmp)
              -tZmp*m2X*math.sinh(tStep*(ph-ph2Zmp)/tZmp);
    com[2] = com[2] + m2Y*tStep*(ph-ph2Zmp)
              -tZmp*m2Y*math.sinh(tStep*(ph-ph2Zmp)/tZmp);
  end
  com[3] = .5*(uLeft[3] + uRight[3]);
  return com;
end

function foot_phase(ph)
  -- Computes relative x,z motion of foot during single support phase
  -- phSingle = 0: x=0, z=0, phSingle = 1: x=1,z=0
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local phSingleSkew = phSingle^0.8 - 0.17*phSingle*(1-phSingle);
  local xf = .5*(1-math.cos(math.pi*phSingleSkew));
  local zf = .5*(1-math.cos(2*math.pi*phSingleSkew));
  return xf, zf;
end

function entry()
  print("Motion SM:".._NAME.." entry");

--initialize left and right foot positions
  uLeft = pose_global({-supportX, footY, 0}, uTorso);
  uRight = pose_global({-supportX, -footY, 0}, uTorso);
  uLeft1 = uLeft;
  uLeft2 = uLeft;
  uRight1 = uRight;
  uRight2 = uRight;
  uTorso1 = uTorso;
  uTorso2 = uTorso;
  uSupport = uTorso;
  pLLeg = vector.new{uLeft[1], uLeft[2], 0, 0, 0, uLeft[3]};
  pRLeg = vector.new{uRight[1], uRight[2], 0, 0, 0, uRight[3]};
  pTorso = vector.new{uTorso[1], uTorso[2], bodyHeight, 0, bodyTilt, uTorso[3]};
  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);
  -- This assumes RLeg follows LLeg in servo order:
  Body.set_lleg_command(qLegs);
  -- Arms
  Body.set_larm_command(qLArm);
  Body.set_rarm_command(qRArm);
  Body.set_larm_hardness(hardnessArm);
  Body.set_rarm_hardness(hardnessArm);
  Body.set_lleg_hardness(hardnessLeg);
  Body.set_rleg_hardness(hardnessLeg);

  iStep0 = -1;
  t0 = Body.get_time();
  active=enable;
end

function update()
  if (not active) then 
	return;
  end

  -- Left leg on the round
  hardnessLeg_gnd = hardnessLeg;
  hardnessLeg_gnd[5] = 0;
  
  if( foot_on_ground == 'left' ) then
    Body.set_lleg_hardness(hardnessLeg_gnd);
    Body.set_rleg_hardness(hardnessLeg);    
    stance_leg = Body.get_lleg_position();
    alpha = Config.alpha_L;
  else
    Body.set_rleg_hardness(hardnessLeg_gnd);
    Body.set_lleg_hardness(hardnessLeg);    
    stance_leg = Body.get_rleg_position();
    alpha = Config.alpha_R;
  end
  
  t = Body.get_time();
  
  theta = stance_leg[5]; -- Just use the ankle
  theta_min = 0.01294;
  theta_max = -0.3054;
  s = (theta - theta_min) / (theta_max - theta_min);
  
  qLegs = vector.zeros(12);
  for i=1,12 do
    qLegs[i] = Util.polyval_bz(alpha[i], s);
  end

  Body.set_lleg_command(qLegs);

--[[
  jointNames = {"PelvYL", "PelvL", "Left Hip Pitch", "LegLowerL", "AnkleL", "FootL", 
"PelvYR", "PelvR", "LegUpperR", "LegLowerR", "AnkleR", "FootR",
             };
--  print('Joint ID: ', unpack(jointNames))
  for i=1,12 do
  print( jointNames[i] .. ': '..qLegs[i]*180/math.pi );
  end
  print();
--]]

end

function exit()
end

