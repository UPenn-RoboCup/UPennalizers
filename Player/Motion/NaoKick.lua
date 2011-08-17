--Parameterized and gyro stabilized kick code for nao
--Made from darwin kick code
------------------------------------------------------

module(..., package.seeall);

require('Body')
require('keyframe')
require('walk')
require('vector')
require('Config')

-- default kick type
kickType = "kickForwardLeft";
active = false;

bodyHeight = Config.walk.bodyHeight;
footX = Config.walk.footX;
footY = Config.walk.footY;
bodyTilt = Config.walk.bodyTilt;
supportX = Config.walk.supportX;
supportY = Config.walk.supportY;
qLArm0 = Config.kick.qLArm;
qRArm0 = Config.kick.qRArm;

bodyRoll=0;

qLArm = vector.new({qLArm0[1],qLArm0[2],qLArm0[3],qLArm0[4]});
qRArm = vector.new({qRArm0[1],qRArm0[2],qRArm0[3],qRArm0[4]});
armGain=Config.kick.armGain;

ankleShift = vector.new({0, 0});
kneeShift=0;
hipShift=vector.new({0,0});
armShift = vector.new({0, 0});

ankleImuParamX=Config.kick.ankleImuParamX;
ankleImuParamY=Config.kick.ankleImuParamY;
kneeImuParamX=Config.kick.kneeImuParamX;
hipImuParamY=Config.kick.hipImuParamY;
armImuParamX=Config.kick.armImuParamX;
armImuParamY=Config.kick.armImuParamX;

qLHipRollCompensation=0;
qRHipRollCompensation=0;
qLHipPitchCompensation=0;
qRHipPitchCompensation=0;

supportCompL=Config.kick.supportCompL;
supportCompR=Config.kick.supportCompR;

--kick definition

kickLeft=Config.kick.kickLeft;
kickRight=Config.kick.kickRight;
kickSideLeft=Config.kick.kickSideLeft;
kickSideRight=Config.kick.kickSideRight;
kickBackLeft=Config.kick.kickBackLeft;
kickBackRight=Config.kick.kickBackRight;

pTorso = vector.new({0, 0, bodyHeight, 0,bodyTilt,0});
pLLeg=vector.zeros(6);
pRLeg=vector.zeros(6);
kickState=1;

function entry()
  print("Motion SM:".._NAME.." entry");
  walk.stop();
  
  started = false;
  active = true;

  uLeft= vector.new({-supportX, footY, 0});
  uRight=vector.new({-supportX, -footY, 0});
  uLeft1= vector.new({-supportX, footY, 0});
  uRight1=vector.new({-supportX, -footY, 0});


print(unpack(uLeft))
print(unpack(uRight))

  uBody=vector.new({0,0,0});
  uBody0=vector.new({0,0,0});
  uBody1=vector.new({0,0,0});

  zLeft,zRight=0,0;
  zLeft1,zRight1=0,0;
  aLeft,aRight=0,0;
  aLeft1,aRight1=0,0;
  zBody,zBody1=Config.walk.bodyHeight,Config.walk.bodyHeight;
  bodyRoll,bodyRoll1=0,0;

end

function update()
  if (not started and walk.active) then
	walk.update();
	return;
  elseif not started then
	started=true;
	Body.set_head_hardness(.5);
	Body.set_larm_hardness(.3);
	Body.set_rarm_hardness(.3);
	Body.set_lleg_hardness(1);
	Body.set_rleg_hardness(1);
  	kickState=1;
	t0 = Body.get_time();
	  if kickType=="kickForwardLeft" then 
		kickDef=kickLeft;
		walk.supportLeg=1; 	--support leg after kick
     	  elseif kickType=="kickForwardRight" then 
		kickDef=kickRight;
		walk.supportLeg=0; 
  	  elseif kickType=="kickSideLeft" then 
		kickDef=kickSideLeft;
		walk.supportLeg=1; 	--support leg after kick
  	  elseif kickType=="kickSideRight" then 
		kickDef=kickSideRight;
		walk.supportLeg=0; 
  	  elseif kickType=="kickBackLeft" then 
		kickDef=kickBackLeft;
		walk.supportLeg=1; 	--support leg after kick
  	  elseif kickType=="kickBackRight" then 
		kickDef=kickBackRight;
		walk.supportLeg=0; 
  	end

  end

  local t=Body.get_time();
  ph=(t-t0)/kickDef[kickState][2];
  if ph>1 then
	kickState=kickState+1;
	uLeft1[1],uLeft1[2],uLeft1[3]=uLeft[1],uLeft[2],uLeft[3];
	uRight1[1],uRight1[2],uRight1[3]=uRight[1],uRight[2],uRight[3];
	uBody1[1],uBody1[2],uBody1[3]=uBody[1],uBody[2],uBody[3];
	zLeft1,zRight1=zLeft,zRight;
	aLeft1,aRight1=aLeft,aRight;
	bodyRoll1=bodyRoll;
	zBody1=zBody;

	if kickState>#kickDef then return "done";end
	ph=0;
	t0=Body.get_time();
  end

  local kickType=kickDef[kickState][1];

  if kickType==1 then --Moving COM at DS stance
	uBody=se2_interpolate(ph,uBody1,kickDef[kickState][3]);	
	if #kickDef[kickState]>=4 then
		zBody=ph*kickDef[kickState][4] + (1-ph)*zBody1;
	end
	if #kickDef[kickState]>=5 then
		bodyRoll=ph*kickDef[kickState][5] + (1-ph)*bodyRoll1;
	end
	qLHipRollCompensation=0;
	qRHipRollCompensation=0;

  elseif kickType==2 then --Lifting / Landing Left foot

	uLeft=se2_interpolate(ph,uLeft1,pose_global(kickDef[kickState][4],uLeft1));
	zLeft=ph*kickDef[kickState][5] + (1-ph)*zLeft1;
	aLeft=ph*kickDef[kickState][6] + (1-ph)*aLeft1;

	qLHipRollCompensation=0;
	qRHipRollCompensation= -5*math.pi/180;

  elseif kickType==3 then --Lifting / Landing Right foot
	uRight=se2_interpolate(ph,uRight1,pose_global(kickDef[kickState][4],uRight1));
	zRight=ph*kickDef[kickState][5] + (1-ph)*zRight1;
	aRight=ph*kickDef[kickState][6] + (1-ph)*aRight1;

	qLHipRollCompensation= 5*math.pi/180;
	qRHipRollCompensation=0;

  elseif kickType==4 then --Kicking Left foot
	uLeft=pose_global(kickDef[kickState][4],uLeft1);
	zLeft=kickDef[kickState][5]
        aLeft=kickDef[kickState][6]

	qLHipRollCompensation=0;
	qRHipRollCompensation=-5*math.pi/180;

  elseif kickType==5 then --Kicking Right foot
	uRight=pose_global(kickDef[kickState][4],uRight1);
	zRight=kickDef[kickState][5]
        aRight=kickDef[kickState][6]

	qLHipRollCompensation=5*math.pi/180;
	qRHipRollCompensation=0;
  end

  uLeftActual=pose_global(supportCompL, uLeft);
  uRightActual=pose_global(supportCompR, uRight);

  pLLeg[1],pLLeg[2],pLLeg[3],pLLeg[5],pLLeg[6]=uLeftActual[1],uLeftActual[2],zLeft,aLeft,uLeftActual[3];
  pRLeg[1],pRLeg[2],pRLeg[3],pRLeg[5],pRLeg[6]=uRightActual[1],uRightActual[2],zRight,aRight,uRightActual[3];
  uTorso=pose_global(vector.new({-footX,0,0}),uBody);
  pTorso[1],pTorso[2],pTorso[6]=uTorso[1],uTorso[2],uTorso[3];
  pTorso[3]=zBody;
  pTorso[4]=bodyRoll;
  motion_legs();
  motion_arms();
end


function motion_arms()
  qLArm[1],qLArm[2]=qLArm0[1]+armShift[1],qLArm0[2]+armShift[2];
  qRArm[1],qRArm[2]=qRArm0[1]+armShift[1],qRArm0[2]+armShift[2];

  local uBodyLeft=pose_relative(uLeft,uBody);
  local uBodyRight=pose_relative(uRight,uBody);
  local footRel=uBodyLeft[1]-uBodyRight[1];

  local armAngle=math.min(50*math.pi/180,
	math.max(-50*math.pi/180,
	footRel/armGain * 50*math.pi/180
	));  

  qLArm[1]=qLArm[1]+armAngle;
  qRArm[1]=qRArm[1]-armAngle;

  Body.set_larm_command(qLArm);
  Body.set_rarm_command(qRArm);
end

function motion_legs()
  --Ankle stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyr();
  gyro0 = Body.get_sensor_imuGyr0();

  --Mapping between OP gyro to nao gyro
  gyro_roll=-(imuGyr[1]-gyro0[1]);
  gyro_pitch=-(imuGyr[2]-gyro0[2]);

  --print("Gyro:",gyro_roll,gyro_pitch);

  ankleShiftX=procFunc(gyro_pitch*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4]);
  ankleShiftY=procFunc(gyro_roll*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4]);
  kneeShiftX=procFunc(gyro_pitch*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4]);
  hipShiftY=procFunc(gyro_roll*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4]);
  armShiftX=procFunc(gyro_pitch*armImuParamX[2],armImuParamX[3],armImuParamX[4]);
  armShiftY=procFunc(gyro_roll*armImuParamY[2],armImuParamY[3],armImuParamY[4]);

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);
  kneeShift=kneeShift+kneeImuParamX[1]*(kneeShiftX-kneeShift);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);
  armShift[1]=armShift[1]+armImuParamX[1]*(armShiftX-armShift[1]);
  armShift[2]=armShift[2]+armImuParamY[1]*(armShiftY-armShift[2]);

--pTorso[1], pTorso[2]  = uTorsoActual[1]+uTorsoShift[1], uTorsoActual[2]+uTorsoShift[2];

  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso,0);

  qLegs[2] = qLegs[2] + qLHipRollCompensation+hipShift[2];
  qLegs[8] = qLegs[8] + qRHipRollCompensation+hipShift[2];
  qLegs[3] = qLegs[3] + qLHipPitchCompensation;
  qLegs[9] = qLegs[9] + qRHipPitchCompensation;
  qLegs[4] = qLegs[4] + kneeShift;
  qLegs[10] = qLegs[10] + kneeShift;
  qLegs[5] = qLegs[5]  + ankleShift[1];
  qLegs[11] = qLegs[11]  + ankleShift[1];
  qLegs[6] = qLegs[6] + ankleShift[2];
  qLegs[12] = qLegs[12] + ankleShift[2];
  Body.set_lleg_command(qLegs);

end

function exit()
  print("Kick exit");
  active = false;
--  walk.active=true;

  walk.start();

--  walk.uLeft=pose_global(pose_relative(uLeft,uBody),walk.uBody);
--  walk.uRight=pose_global(pose_relative(uRight,uBody),walk.uBody);
end

function set_kick(newKick)
    kickType = newKick;
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

