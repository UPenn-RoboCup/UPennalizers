module(..., package.seeall);

require('Body')
require('Kinematics')
require('Config');
require('vector')
require('mcm')
require('unix')
require('util')
require('Body')
require('invhyp')



-- Stance and velocity limit values
stanceLimitX=Config.walk.stanceLimitX or {-0.10 , 0.10};
stanceLimitY={2*Config.walk.footY - 2*Config.walk.supportY,0.20} --needed to prevent from tStep getting too small
stanceLimitA=Config.walk.stanceLimitA or {-0*math.pi/180, 40*math.pi/180};

--Toe/heel overlap checking values
footSizeX = Config.walk.footSizeX or {-0.05,0.05};
stanceLimitMarginY = Config.walk.stanceLimitMarginY or 0.015;
stanceLimitY2= 2* Config.walk.footY-stanceLimitMarginY;

velLimitX = Config.walk.velLimitX or {-.06, .08};
velLimitY = Config.walk.velLimitY or {-.06, .06};
velLimitA = Config.walk.velLimitA or {-.4, .4};

velDelta = Config.walk.velDelta or {.03,.015,.15};
vaFactor = Config.walk.velLimitA[2] or 0.6;
velXHigh = Config.walk.velXHigh or 0.06;
velDeltaXHigh = Config.walk.velDeltaXHigh or 0.01;


--Gyro stabilization parameters
ankleImuParamX = Config.walk.ankleImuParamX;
ankleImuParamY = Config.walk.ankleImuParamY;
kneeImuParamX = Config.walk.kneeImuParamX;
hipImuParamY = Config.walk.hipImuParamY;


--Gyro stabilization variables
ankleShift,kneeShift,hipShift,toeTipCompensation = vector.new({0,0}),0,vector.new({0,0}),0




function load_default_param_values()
  local p={}
  p.bodyTilt = Config.walk.bodyTilt or 0
  p.tStep = Config.walk.tStep   
  p.tStep0 = Config.walk.tStep  
  p.bodyHeight = Config.walk.bodyHeight 
  p.footY = Config.walk.footY  
  p.supportX = Config.walk.supportX
  p.supportY = Config.walk.supportY
  p.tZmp = Config.walk.tZmp
  p.stepHeight0 = Config.walk.stepHeight  
  p.stepHeight = Config.walk.stepHeight
  p.phSingleRatio = Config.walk.phSingleRatio or 0.04
  p.hardnessSupport = Config.walk.hardnessSupport or 0.75
  p.hardnessSwing = Config.walk.hardnessSwing or 0.5  
  p.hipRollCompensation = Config.walk.hipRollCompensation;
  p.zmpparam={aXP=0,aXN=0, aYP=0, aYN=0}
  p.zmp_type = 1 --0 for square zmp
  return p
end






function clip_velocity(vx,vy,va)
--Filter the commanded speed
  vx= math.min(math.max(vx,velLimitX[1]),velLimitX[2]);
  vy= math.min(math.max(vy,velLimitY[1]),velLimitY[2]);
  va= math.min(math.max(va,velLimitA[1]),velLimitA[2]);

  --Slow down when turning
  vFactor = 1-math.abs(va)/vaFactor;
  local stepMag=math.sqrt(vx^2+vy^2);
  local magFactor=math.min(velLimitX[2]*vFactor,stepMag)/(stepMag+0.000001);

  local velCommand={vx*magFactor,vy*magFactor,va}
  velCommand[1] = math.min(math.max(velCommand[1],velLimitX[1]),velLimitX[2]);
  velCommand[2] = math.min(math.max(velCommand[2],velLimitY[1]),velLimitY[2]);
  velCommand[3] = math.min(math.max(velCommand[3],velLimitA[1]),velLimitA[2]);
  return velCommand
end


function update_velocity(velCurrent, velCommand, initial_step,unstable_factor)
  local sf = 1
  local velDiff={0,0,0}
  if unstable_factor> 0.7 then -- robot's unstable, slow down
    print("unstable, slowing down")
    sf = 0.85
  end  
  if velCurrent[1]>velXHigh then --Slower accelleration at high speed 
    velDiff[1]= math.min(math.max(velCommand[1]*sf-velCurrent[1],-velDelta[1]),velDeltaXHigh)
  else
    velDiff[1]= math.min(math.max(velCommand[1]*sf-velCurrent[1],-velDelta[1]),velDelta[1])
  end
  velDiff[2]= math.min(math.max(velCommand[2]*sf-velCurrent[2],-velDelta[2]),velDelta[2])
  velDiff[3]= math.min(math.max(velCommand[3]*sf-velCurrent[3],-velDelta[3]),velDelta[3])
  velCurrent = velCurrent+velDiff
  
  if initial_step>0 then
    velCurrent=vector.new({0,0,0})
    initial_step=initial_step-1
  end
  return velCurrent, velDiff, initial_step
end

function step_torso(uLeft, uRight,shiftFactor,p)
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  local uLeftSupport = util.pose_global({p.supportX, p.supportY, 0}, uLeft);
  local uRightSupport = util.pose_global({p.supportX, -p.supportY, 0}, uRight);
  return util.se2_interpolate(shiftFactor, uLeftSupport, uRightSupport);
end

function step_left_destination(vel, uLeft, uRight,p)
  local uLRFootOffset = vector.new({0,p.footY,0})
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel, u0);
  local u2 = util.pose_global(.5*vel, u1);
  local uLeftPredict = util.pose_global(uLRFootOffset, u2);
  local uLeftRight = util.pose_relative(uLeftPredict, uRight);

  --Check toe and heel overlap
  local toeOverlap= -footSizeX[1]*uLeftRight[3];
  local heelOverlap= -footSizeX[2]*uLeftRight[3];
  local limitY = math.max(stanceLimitY[1],
  stanceLimitY2+math.max(toeOverlap,heelOverlap));

  uLeftRight[1] = math.min(math.max(uLeftRight[1], stanceLimitX[1]), stanceLimitX[2]);
  uLeftRight[2] = math.min(math.max(uLeftRight[2], limitY),stanceLimitY[2]);
  uLeftRight[3] = math.min(math.max(uLeftRight[3], stanceLimitA[1]), stanceLimitA[2]);
  return util.pose_global(uLeftRight, uRight);
end

function step_right_destination(vel, uLeft, uRight,p)
  local uLRFootOffset = vector.new({0,p.footY,0})
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel, u0);
  local u2 = util.pose_global(.5*vel, u1);
  local uRightPredict = util.pose_global(-1*uLRFootOffset, u2);
  local uRightLeft = util.pose_relative(uRightPredict, uLeft);

  --Check toe and heel overlap
  local toeOverlap= footSizeX[1]*uRightLeft[3];
  local heelOverlap= footSizeX[2]*uRightLeft[3];
  local limitY = math.max(stanceLimitY[1],
  stanceLimitY2+math.max(toeOverlap,heelOverlap));

  uRightLeft[1] = math.min(math.max(uRightLeft[1], stanceLimitX[1]), stanceLimitX[2]);
  uRightLeft[2] = math.min(math.max(uRightLeft[2], -stanceLimitY[2]), -limitY);
  uRightLeft[3] = math.min(math.max(uRightLeft[3], -stanceLimitA[2]), -stanceLimitA[1]);
  return util.pose_global(uRightLeft, uLeft);
end

function stop_left_destination(uLeft, uRight,p) return util.pose_global({0,2*p.footY,0}, uRight) end
function stop_right_destination(uLeft, uRight,p) return util.pose_global({0,-2*p.footY,0}, uLeft) end

function foot_phase(ph,p)
  -- Computes relative x,z motion of foot during single support phase
  -- phSingle = 0: x=0, z=0, phSingle = 1: x=1,z=0
  local ph1Single,ph2Single = p.phSingleRatio/2,1-p.phSingleRatio/2
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local phSingleSkew = phSingle^0.8 - 0.17*phSingle*(1-phSingle);
  local xf = .5*(1-math.cos(math.pi*phSingleSkew));
  local zf = .5*(1-math.cos(2*math.pi*phSingleSkew));
  return xf, zf
end

function foot_tilt(ph,velCurrent,supportLeg,p)
  local ph1Single,ph2Single = p.phSingleRatio/2,1-p.phSingleRatio/2
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local aLeft,aRight=0,0
  local heeltoe_angles = Config.walk.heeltoe_angles or {0,0}
  local foot_tilt = math.sin(phSingle*2*math.pi)  
  if phSingle<0.5 then foot_tilt = foot_tilt*heeltoe_angles[1]
  else foot_tilt = foot_tilt*heeltoe_angles[2]
  end
  if velCurrent[1]>(Config.walk.heeltoe_vel_min or 0.06) then
    if supportLeg==0 then aRight=foot_tilt
    else aLeft= foot_tilt
    end
  end
  return aLeft,aRight
end

function foot_interpolate(uFoot1, uFoot2, uFoot15, xFoot, step_type)
  walkKickPh = Config.kick.walkKickPh or 0.5
  local uFoot
  if step_type>1 then --walkkick
    if xFoot<walkKickPh then uFoot = util.se2_interpolate(xFoot*2, uFoot1, uFoot15)
    else uFoot = util.se2_interpolate(xFoot*2-1, uFoot15, uFoot2) end
  else uFoot = util.se2_interpolate(xFoot, uFoot1, uFoot2) end
  return uFoot
end


function move_legs(pLLeg,pRLeg,pTorso,supportLeg,phSingle, p,gyro_off)
  if not Config.ik_testing then
    qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, supportLeg);
  else
    local qLCurrent = Body.get_lleg_position();
    local qRCurrent = Body.get_rleg_position();    
    qLegs = Kinematics.inverse_legs_heeltoe(pLLeg, pRLeg, pTorso, 
      qLCurrent, qRCurrent, aLeft, aRight)
  end

  phComp = math.min(1, phSingle/.1, (1-phSingle)/.1);

  --Ankle stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyrRPY();
  gyro_roll0,gyro_pitch0=imuGyr[1],imuGyr[2]
  if gyro_off or Config.disable_gyro_feedback then  gyro_roll0,gyro_pitch0=0,0 end

  --get effective gyro angle considering body angle offset
  if supportLeg==2  then yawAngle = (pLLeg[6]+pRLeg[6])/2-pTorso[6] --double support
  elseif supportLeg == 0 then yawAngle = pLLeg[6]-pTorso[6]  -- Left support
  elseif supportLeg==1 then yawAngle = pRLeg[6]-pTorso[6]
  end
  gyro_roll = gyro_roll0*math.cos(yawAngle) -gyro_pitch0* math.sin(yawAngle)
  gyro_pitch = gyro_pitch0*math.cos(yawAngle) -gyro_roll0* math.sin(yawAngle)

  ankleShiftX=util.procFunc(gyro_pitch*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4])
  ankleShiftY=util.procFunc(gyro_roll*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4])
  kneeShiftX=util.procFunc(gyro_pitch*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4])
  hipShiftY=util.procFunc(gyro_roll*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4])

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);
  kneeShift=kneeShift+kneeImuParamX[1]*(kneeShiftX-kneeShift);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);
  --TODO: Toe/heel lifting

  if supportLeg==2 then --Double support, standing still
    qLegs[4] = qLegs[4] + kneeShift;    --Knee pitch stabilization
    qLegs[5] = qLegs[5]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[10] = qLegs[10] + kneeShift;    --Knee pitch stabilization
    qLegs[11] = qLegs[11]  + ankleShift[1];    --Ankle pitch stabilization

  elseif supportLeg == 0 then  -- Left support
    qLegs[2] = qLegs[2] + hipShift[2];    --Hip roll stabilization
    qLegs[4] = qLegs[4] + kneeShift;    --Knee pitch stabilization
    qLegs[5] = qLegs[5]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[6] = qLegs[6] + ankleShift[2];    --Ankle roll stabilization

    qLegs[11] = qLegs[11]
    qLegs[2] = qLegs[2] + p.hipRollCompensation*phComp; --Hip roll compensation
  else
    qLegs[8] = qLegs[8]  + hipShift[2];    --Hip roll stabilization
    qLegs[10] = qLegs[10] + kneeShift;    --Knee pitch stabilization
    qLegs[11] = qLegs[11]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[12] = qLegs[12] + ankleShift[2];    --Ankle roll stabilization

    qLegs[5] = qLegs[5]
    qLegs[8] = qLegs[8] - p.hipRollCompensation*phComp;--Hip roll compensation
  end

  qLegs[3] = qLegs[3]  + Config.walk.LHipOffset
  qLegs[9] = qLegs[9]  + Config.walk.RHipOffset
  qLegs[5] = qLegs[5]  + Config.walk.LAnkleOffset
  qLegs[11] = qLegs[11]  + Config.walk.RAnkleOffset

  Body.set_lleg_command(qLegs);
end
