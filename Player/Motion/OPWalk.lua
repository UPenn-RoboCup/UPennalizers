module(..., package.seeall);

require('Body')
require('Kinematics')
require('Config');
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

  t = Body.get_time();
  iStep, ph = math.modf((t-t0)/tStep);
  if (iStep > iStep0) then
    -- New step
    iStep0 = iStep;
    supportLeg = iStep % 2; -- 0 for left support, 1 for right support

    uLeft1 = uLeft2;
    uRight1 = uRight2;
    uTorso1 = uTorso2;

    if stopRequest == 2 then
      stopRequest = 0;
      active = false;
      return "stop";
    elseif stopRequest == 1 then
      stopRequest = 2;
      --Stopping step
      if supportLeg == 0 then
        -- Left support
        uRight2 = pose_global({0,-2*footY,0},uLeft1);
        uSupport = pose_global({supportX, supportY, 0}, uLeft);
      else
        -- Right support
        uLeft2 = pose_global({0,2*footY,0},uRight1);
        uSupport = pose_global({supportX, -supportY, 0}, uRight);
      end
    else
      --Normal step
      if supportLeg == 0 then
        -- Left support
        uRight2 = step_right_destination(velCurrent, uLeft1, uRight1);
        uSupport = pose_global({supportX, supportY, 0}, uLeft);
      else
        -- Right support
        uLeft2 = step_left_destination(velCurrent, uLeft1, uRight1);
        uSupport = pose_global({supportX, -supportY, 0}, uRight);
      end
    end

    uTorso2 = step_torso(uLeft2, uRight2);

    --Compute ZMP coefficients
    m1X = (uSupport[1]-uTorso1[1])/(tStep*ph1Zmp);
    m2X = (uTorso2[1]-uSupport[1])/(tStep*(1-ph2Zmp));
    m1Y = (uSupport[2]-uTorso1[2])/(tStep*ph1Zmp);
    m2Y = (uTorso2[2]-uSupport[2])/(tStep*(1-ph2Zmp));
    aXP, aXN = zmp_solve(uSupport[1], uTorso1[1], uTorso2[1],
                          uTorso1[1], uTorso2[1]);
    aYP, aYN = zmp_solve(uSupport[2], uTorso1[2], uTorso2[2],
                          uTorso1[2], uTorso2[2]);
  end

  xFoot, zFoot = foot_phase(ph);
  qLHipRollCompensation = 0;
  qRHipRollCompensation = 0;
  qLHipPitchCompensation = 0;
  qRHipPitchCompensation = 0;

  local phComp=math.min(1, phSingle/.1, (1-phSingle)/.1);

  if supportLeg == 0 then
    -- Left support
    uRight = se2_interpolate(xFoot, uRight1, uRight2);

    pLLeg[3] = 0;
    pRLeg[3] = stepHeight*zFoot;

    if (phSingle > 0) and (phSingle < 1) then     
      qLHipRollCompensation = hipRollCompensation*phComp;
      qLHipPitchCompensation = hipPitchCompensation*phComp;
    end
    pTorsoSensor = Kinematics.torso_lleg(Body.get_lleg_position());
    pTorsoSensor[2] = pTorsoSensor[2] + .085*pTorsoSensor[4];
    uTorsoSensor = pose_global({pTorsoSensor[1], pTorsoSensor[2], pTorsoSensor[6]},
                                uLeft);
  else
    -- Right support
    uLeft = se2_interpolate(xFoot, uLeft1, uLeft2);

    pLLeg[3] = stepHeight*zFoot;
    pRLeg[3] = 0;
    
    if (phSingle > 0) and (phSingle < 1) then
      qRHipRollCompensation = - hipRollCompensation*phComp;
      qRHipPitchCompensation = hipPitchCompensation*phComp;
    end
    pTorsoSensor = Kinematics.torso_rleg(Body.get_rleg_position());
    pTorsoSensor[2] = pTorsoSensor[2] + .085*pTorsoSensor[4];
    uTorsoSensor = pose_global({pTorsoSensor[1], pTorsoSensor[2], pTorsoSensor[6]},
                                uRight);
  end
--Torso stabilization using sensory feedback
  uTheoretic = uTorsoShift + zmp_com(ph - tSensorDelay/tStep);
  uTorso = zmp_com(ph);
  uError = uTorsoSensor - uTheoretic;

  uTorsoShift[1] = uTorsoShift[1] + torsoSensorParamX[1]*(torsoSensorParamX[2]*uError[1] - uTorsoShift[1]);
  uTorsoShift[2] = uTorsoShift[2] + torsoSensorParamY[1]*(torsoSensorParamY[2]*uError[2] - uTorsoShift[2]);

  legUpdate();
end


function legUpdate()
  --Stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyr();

  ankleShiftX=procFunc(imuGyr[2]*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4]);
  ankleShiftY=procFunc(imuGyr[3]*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4]);

  kneeShiftX=procFunc(imuGyr[2]*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4]);
  hipShiftY=procFunc(imuGyr[3]*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4]);

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);

  kneeShift[1]=kneeShift[1]+kneeImuParamX[1]*(kneeShiftX-kneeShift[1]);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);

  pLLeg[1], pLLeg[2], pLLeg[6] = uLeft[1], uLeft[2], uLeft[3];
  pRLeg[1], pRLeg[2], pRLeg[6] = uRight[1], uRight[2], uRight[3];
  pTorso[1], pTorso[2], pTorso[6], pTorso[5]  =
	    uTorso[1]+uTorsoShift[1], uTorso[2]+uTorsoShift[2], uTorso[3], bodyTilt;

  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, supportLeg);

  if supportLeg == 0 then
    -- Left support
    qLegs[2] = qLegs[2]  + hipShift[2] + qLHipRollCompensation;
    qLegs[3] = qLegs[3] + qLHipPitchCompensation;
    qLegs[4] = qLegs[4]  + kneeShift[1];
    qLegs[5] = qLegs[5]  + ankleShift[1];
    qLegs[6] = qLegs[6] + ankleShift[2];
  else
    qLegs[8] = qLegs[8]  + hipShift[2] + qRHipRollCompensation;
    qLegs[9] = qLegs[9] + qRHipPitchCompensation;
    qLegs[11] = qLegs[11]  + kneeShift[1];
    qLegs[11] = qLegs[11]  + ankleShift[1];
    qLegs[12] = qLegs[12] + ankleShift[2];
  end

  Body.set_lleg_command(qLegs);

end

function exit()
end

function procFunc(a,deadband,maxvalue)
	if a>0 then b=math.min( math.max(0,math.abs(a)-deadband), maxvalue);
	else b=-math.min( math.max(0,math.abs(a)-deadband), maxvalue);
	end
	return b;
end

function mod_angle(a)
  -- Reduce angle to [-pi, pi)
  a = a % (2*math.pi);
  if (a >= math.pi) then
    a = a - 2*math.pi;
  end
  return a;
end

function pose_global(pRelative, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  return vector.new{pose[1] + ca*pRelative[1] - sa*pRelative[2],
                    pose[2] + sa*pRelative[1] + ca*pRelative[2],
                    pose[3] + pRelative[3]};
end

function pose_relative(pGlobal, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  local px = pGlobal[1]-pose[1];
  local py = pGlobal[2]-pose[2];
  local pa = pGlobal[3]-pose[3];
  return vector.new{ca*px + sa*py, -sa*px + ca*py, mod_angle(pa)};
end

function se2_interpolate(t, u1, u2)
  return vector.new{u1[1]+t*(u2[1]-u1[1]),
                    u1[2]+t*(u2[2]-u1[2]),
                    u1[3]+t*mod_angle(u2[3]-u1[3])};
end

function step_left_destination(vel, uLeft, uRight)
  local u0 = se2_interpolate(.5, uLeft, uRight);

  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = pose_global(vel, u0);
  local u2 = pose_global(.5*vel, u1);
  local uLeftPredict = pose_global({0, footY, 0}, u2);
  local uLeftRight = pose_relative(uLeftPredict, uRight);

  -- Do not pidgeon toe, cross feet:
  uLeftRight[1] = math.min(math.max(uLeftRight[1], stanceLimitX[1]), stanceLimitX[2]);
  uLeftRight[2] = math.min(math.max(uLeftRight[2], stanceLimitY[1]), stanceLimitY[2]);
  uLeftRight[3] = math.min(math.max(uLeftRight[3], stanceLimitA[1]), stanceLimitA[2]);
  return pose_global(uLeftRight, uRight);
end

function step_right_destination(vel, uLeft, uRight)
  local u0 = se2_interpolate(.5, uLeft, uRight);

  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = pose_global(vel, u0);
  local u2 = pose_global(.5*vel, u1);
  local uRightPredict = pose_global({0, -footY, 0}, u2);
  local uRightLeft = pose_relative(uRightPredict, uLeft);

  -- Do not pidgeon toe, cross feet:
  uRightLeft[1] = math.min(math.max(uRightLeft[1], -stanceLimitX[2]), -stanceLimitX[1]);
  uRightLeft[2] = math.min(math.max(uRightLeft[2], -stanceLimitY[2]), -stanceLimitY[1]);
  uRightLeft[3] = math.min(math.max(uRightLeft[3], -stanceLimitA[2]), -stanceLimitA[1]);
  return pose_global(uRightLeft, uLeft);
end

function step_torso(uLeft, uRight)
  local u0 = se2_interpolate(.5, uLeft, uRight);
  local uLeftSupport = pose_global({supportX, supportY, 0}, uLeft);
  local uRightSupport = pose_global({supportX, -supportY, 0}, uRight);
  return se2_interpolate(.5, uLeftSupport, uRightSupport);
end

function set_velocity(vx, vy, vz)
  velCurrent[1] = math.min(math.max(vx, velLimitX[1]), velLimitX[2]);
  velCurrent[2] = math.min(math.max(vy, velLimitY[1]), velLimitY[2]);
  velCurrent[3] = math.min(math.max(vz, velLimitA[1]), velLimitA[2]);
end

function start()
  stopRequest = 0;
  if (not active) then
    active = true;
    iStep0 = -1;
    t0 = Body.get_time();
    velCurrent=vector.new({0,0,0});
  end
end

function stop()
  stopRequest = 1;
end

function stopAlign()
  stop()
end

function get_odometry(u0)
  if (not u0) then
    u0 = vector.new({0, 0, 0});
  end
  local uFoot = se2_interpolate(.5, uLeft, uRight);
  return pose_relative(uFoot, u0), uFoot;
end

function get_body_offset()
  local uFoot = se2_interpolate(.5, uLeft, uRight);
  return pose_relative(uTorso, uFoot);
end
