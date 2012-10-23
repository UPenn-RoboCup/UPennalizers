module(..., package.seeall);

require('Body')
require('keyframe')
require('walk')
require('vector')
require('Config')
require('util')
require('mcm')

local cwd = unix.getcwd();
if string.find(cwd, "WebotsController") then
  cwd = cwd.."/Player";
end
cwd = cwd.."/Motion"

--Kick definition list
kickDefList = Config.kick.def;

-- default kick type
kickType = "kickForwardLeft";

active = false;

--Feedback gain parameters
ankleImuParamX=Config.kick.ankleImuParamX;
kneeImuParamX=Config.kick.kneeImuParamX;
hipImuParamY=Config.kick.hipImuParamY;
ankleImuParamY=Config.kick.ankleImuParamY;
armImuParamX=Config.kick.armImuParamX;
armImuParamY=Config.kick.armImuParamX;

--Gyro stabilization variables
ankleShift = vector.new({0, 0});
kneeShift=0;
hipShift=vector.new({0,0});
armShift = vector.new({0, 0});

--Arm movement parameters
qLArm0 = Config.kick.qLArm;
qRArm0 = Config.kick.qRArm;
armGain = Config.kick.armGain;

--Compensation parameters
supportCompL=Config.walk.supportCompL or vector.new({0,0,0});
supportCompR=Config.walk.supportCompR or vector.new({0,0,0});
hipRollCompensation = Config.kick.hipRollCompensation or 5*math.pi/180;

hipRollCompensation = 5*math.pi/180;


qLHipRollCompensation=0;
qRHipRollCompensation=0;

--Hardness parameters
hardnessArm=Config.kick.hardnessArm;
hardnessLeg=Config.kick.hardnessLeg;

bodyHeight = Config.walk.bodyHeight;
bodyTilt = Config.walk.bodyTilt or 0;
footX = mcm.get_footX();
footY = Config.walk.footY;
supportX = Config.walk.supportX;
kickXComp = mcm.get_kickX();


qLArm = vector.new({qLArm0[1],qLArm0[2],qLArm0[3]});
qRArm = vector.new({qRArm0[1],qRArm0[2],qRArm0[3]});
qLArm1 = vector.new({qLArm0[1],qLArm0[2],qLArm0[3]});
qRArm1 = vector.new({qRArm0[1],qRArm0[2],qRArm0[3]});

kickState=1;
pLLeg=vector.zeros(6);
pRLeg=vector.zeros(6);

torsoShiftX=0;

function entry()
  footX = mcm.get_footX();
  kickXComp = mcm.get_kickX();

  print("Motion SM:".._NAME.." entry");
  walk.stop();
  walk.zero_velocity();
  torsoShiftX=0;
  
  started = false;
  active = true;
 
  --Parse kick definition
  kickDef = kickDefList[kickType].def;
  supportLeg = kickDefList[kickType].supportLeg;

  --Initialize state variables
  uLeft= vector.new({-supportX, footY, 0});
  uRight=vector.new({-supportX, -footY, 0});
  uLeft1= vector.new({-supportX, footY, 0});
  uRight1=vector.new({-supportX, -footY, 0});
  uBody=vector.new({0,0,0});
  uBody1=vector.new({0,0,0});
  zLeft,zRight,zLeft1,zRight1=0,0,0,0;--foot height
  aLeft,aRight,aLeft1,aRight1=0,0;--foot pitch angle
  zBody,zBody1=bodyHeight,bodyHeight;
  bodyRoll,bodyRoll1=0,0;
  bodyPitch,bodyPitch1=bodyTilt,bodyTilt;
  qLArm = vector.new({qLArm0[1],qLArm0[2],qLArm0[3]});
  qRArm = vector.new({qRArm0[1],qRArm0[2],qRArm0[3]});
  qLArm1[1],qLArm1[2],qLArm1[3]=qLArm[1],qLArm[2],qLArm[3];
  qRArm1[1],qRArm1[2],qRArm1[3]=qRArm[1],qRArm[2],qRArm[3];

  -- disable joint encoder reading
  Body.set_syncread_enable(0);
  qLHipRollCompensation,qRHipRollCompensation= 0,0;

end

function update()
  if (not started and walk.active) then
    walk.update();
    return;
  elseif not started then
    started=true;
    Body.set_head_hardness(.5);
    Body.set_larm_hardness(hardnessArm);
    Body.set_rarm_hardness(hardnessArm);
    Body.set_lleg_hardness(hardnessLeg);
    Body.set_rleg_hardness(hardnessLeg);
    kickState=1;
    t0 = Body.get_time();
  end

  local t=Body.get_time();
  ph=(t-t0)/kickDef[kickState][2];
  if ph>1 then
    kickState=kickState+1;
    uLeft1[1],uLeft1[2],uLeft1[3]=uLeft[1],uLeft[2],uLeft[3];
    uRight1[1],uRight1[2],uRight1[3]=uRight[1],uRight[2],uRight[3];
    uBody1[1],uBody1[2],uBody1[3]=uBody[1],uBody[2],uBody[3];
    qLArm1[1],qLArm1[2],qLArm1[3]=qLArm[1],qLArm[2],qLArm[3];
    qRArm1[1],qRArm1[2],qRArm1[3]=qRArm[1],qRArm[2],qRArm[3];

    zLeft1,zRight1=zLeft,zRight;
    aLeft1,aRight1=aLeft,aRight;
    bodyRoll1=bodyRoll;
    bodyPitch1=bodyPitch;
    zBody1=zBody;

    if kickState>#kickDef then return "done";end

    ph=0;
    t0=Body.get_time();
    if supportLeg ==0 then --left support 
        Body.set_lleg_slope(1);
        Body.set_rleg_slope(0);
    else --right support
        Body.set_rleg_slope(1);
        Body.set_lleg_slope(0);
    end
  end

  kickStepType=kickDef[kickState][1];

  -- Tosro X position offxet (for differetly calibrated robots)
  if kickState==1 then --Initial slide
     torsoShiftX=kickXComp*ph;
--  elseif kickState == #kickDef-1 then
  elseif kickState == #kickDef then
     torsoShiftX=kickXComp*(1-ph);
  end

  if kickState==2 then --Lift step
    if kickStepType==2 then 
--Instant roll compensation
--      qRHipRollCompensation= -hipRollCompensation*ph;
      qRHipRollCompensation= -hipRollCompensation;
    elseif kickStepType==3 then
--      qLHipRollCompensation= hipRollCompensation*ph;
      qLHipRollCompensation= hipRollCompensation;
    end
  elseif kickState == #kickDef then --Final step
    if qRHipRollCompensation<0 then
      qRHipRollCompensation= -hipRollCompensation*(1-ph);
    elseif qLHipRollCompensation>0 then
      qLHipRollCompensation= hipRollCompensation*(1-ph);
    end
  end

  if kickStepType==1 then
    uBody=util.se2_interpolate(ph,uBody1,kickDef[kickState][3]);	
    if #kickDef[kickState]>=4 then
      zBody=ph*kickDef[kickState][4] + (1-ph)*zBody1;
    end
    if #kickDef[kickState]>=5 then
      bodyRoll=ph*kickDef[kickState][5] + (1-ph)*bodyRoll1;
    end
    if #kickDef[kickState]>=6 then
      bodyPitch=ph*kickDef[kickState][6] + (1-ph)*bodyPitch1;
    end
  elseif kickStepType==2 then --Lifting / Landing Left foot
    uLeft=util.se2_interpolate(ph,uLeft1,
      util.pose_global(kickDef[kickState][4],uLeft1));
    zLeft=ph*kickDef[kickState][5] + (1-ph)*zLeft1;
    aLeft=ph*kickDef[kickState][6] + (1-ph)*aLeft1;

  elseif kickStepType==3 then --Lifting / Landing Right foot
    uRight=util.se2_interpolate(ph,uRight1,
      util.pose_global(kickDef[kickState][4],uRight1));
    zRight=ph*kickDef[kickState][5] + (1-ph)*zRight1;
    aRight=ph*kickDef[kickState][6] + (1-ph)*aRight1;

  elseif kickStepType==4 then --Kicking Left foot
    uLeft=util.pose_global(kickDef[kickState][4],uLeft1);
    zLeft=kickDef[kickState][5]
    aLeft=kickDef[kickState][6]

  elseif kickStepType==5 then --Kicking Right foot
    uRight=util.pose_global(kickDef[kickState][4],uRight1);
    zRight=kickDef[kickState][5]
    aRight=kickDef[kickState][6]

  elseif kickStepType ==6 then --Returning to walk stance
    uBody=util.se2_interpolate(ph,uBody1,kickDef[kickState][3]);	
    zBody=ph*bodyHeight + (1-ph)*zBody1;
    bodyRoll=(1-ph)*bodyRoll1;
    qLArm = vector.new({qLArm0[1],qLArm0[2],qLArm0[3]});
    qRArm = vector.new({qRArm0[1],qRArm0[2],qRArm0[3]});

  elseif kickStepType ==7 then --Upper body movement
    uBody=util.se2_interpolate(ph,uBody1,kickDef[kickState][3]);	
    qLArm=util.se2_interpolate(ph,qLArm1,kickDef[kickState][4]);
    qRArm=util.se2_interpolate(ph,qRArm1,kickDef[kickState][5]);
    if #kickDef[kickState]>=6 then
      zBody=ph*kickDef[kickState][6] + (1-ph)*zBody1;
    end
    if #kickDef[kickState]>=7 then
      bodyRoll=ph*kickDef[kickState][7] + (1-ph)*bodyRoll1;
    end
    if #kickDef[kickState]>=8 then
      bodyPitch=ph*kickDef[kickState][8] + (1-ph)*bodyPitch1;
    end
  end

  uLeftActual=util.pose_global(supportCompL, uLeft);
  uRightActual=util.pose_global(supportCompR, uRight);
  uTorso=util.pose_global(vector.new({-footX-torsoShiftX,0,0}),uBody);
  pLLeg=vector.new({uLeftActual[1],uLeftActual[2],zLeft,
		    0,aLeft,uLeftActual[3]})
  pRLeg=vector.new({uRightActual[1],uRightActual[2],zRight,
		    0,aRight,uRightActual[3]})
  pTorso = vector.new({uTorso[1], uTorso[2], zBody,
		      bodyRoll,bodyPitch,uTorso[3]});
  motion_legs();
  motion_arms();
end

function motion_legs()

--Ankle stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyr();

  gyro_roll=imuGyr[1];
  gyro_pitch=imuGyr[2];

  ankleShiftX=util.procFunc(gyro_pitch*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4]);
  ankleShiftY=util.procFunc(gyro_roll*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4]);
  kneeShiftX=util.procFunc(gyro_pitch*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4]);
  hipShiftY=util.procFunc(gyro_roll*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4]);
  armShiftX=util.procFunc(gyro_pitch*armImuParamX[2],armImuParamX[3],armImuParamX[4]);
--armShiftY=util.procFunc(gyro_roll*armImuParamY[2],armImuParamY[3],armImuParamY[4]);
  armShiftY = 0; --No arm Y stabilization during kick

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);
  kneeShift=kneeShift+kneeImuParamX[1]*(kneeShiftX-kneeShift);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);

  armShift[1]=armShift[1]+armImuParamX[1]*(armShiftX-armShift[1]);
  armShift[2]=armShift[2]+armImuParamY[1]*(armShiftY-armShift[2]);

  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso,0);

--print("RollCompensation:",qLHipRollCompensation*180/math.pi,qRHipRollCompensation*180/math.pi)

  if kicktype==4 then	--Left kick
    qLegs[10] = qLegs[10] + kneeShift;
    qLegs[11] = qLegs[11]  + ankleShift[1];
  elseif kicktype==5 then  --Right kick
    qLegs[4] = qLegs[4] + kneeShift;
    qLegs[5] = qLegs[5]  + ankleShift[1];
  else
    qLegs[4] = qLegs[4] + kneeShift;
    qLegs[5] = qLegs[5]  + ankleShift[1];
    qLegs[10] = qLegs[10] + kneeShift;
    qLegs[11] = qLegs[11]  + ankleShift[1];
  end

  qLegs[2] = qLegs[2] + qLHipRollCompensation+hipShift[2];
  qLegs[8] = qLegs[8] + qRHipRollCompensation+hipShift[2];

  qLegs[6] = qLegs[6] + ankleShift[2];
  qLegs[12] = qLegs[12] + ankleShift[2];
  Body.set_lleg_command(qLegs);
end

function motion_arms()

  if kickStepType ~=7 then
    local uBodyLeft=util.pose_relative(uLeft,uBody);
    local uBodyRight=util.pose_relative(uRight,uBody);
    local footRel=uBodyLeft[1]-uBodyRight[1];
    local armAngle=math.min(50*math.pi/180,
	math.max(-50*math.pi/180,
	footRel/armGain * 50*math.pi/180
	));  
    qLArm[1],qLArm[2]=qLArm0[1]+armShift[1],qLArm0[2]+armShift[2];
    qRArm[1],qRArm[2]=qRArm0[1]+armShift[1],qRArm0[2]+armShift[2];
    qLArm[1]=qLArm[1]+armAngle;
    qRArm[1]=qRArm[1]-armAngle;
  end
  Body.set_larm_command(qLArm);
  Body.set_rarm_command(qRArm);
end

function exit()
  print("Kick exit");
  active = false;

  Body.set_lleg_slope(0);
  Body.set_rleg_slope(0);

  walk.start();
--  step.stepqueue={};
end

function set_kick(newKick)
    if (kickDefList[newKick]) then
	kickType = newKick;
    end
end
