module(..., package.seeall);

require('Body')
require('keyframe')
require('walk')
require('vector')
require('Config')
require('util')

local cwd = unix.getcwd();
if string.find(cwd, "WebotsController") then
  cwd = cwd.."/Player";
end
cwd = cwd.."/Motion"


bodyHeight = Config.walk.bodyHeight;
footX = Config.walk.footX or 0;
footY = Config.walk.footY;
bodyTilt = Config.walk.bodyTilt;
supportX = Config.walk.supportX;
supportY = Config.walk.supportY;

qLArm0=Config.walk.qLArm;
qRArm0=Config.walk.qRArm;

ankleShift = vector.new({0, 0});
kneeShift=0;
hipShift=vector.new({0,0});
armShift = vector.new({0, 0});

ankleImuParamX=Config.walk.ankleImuParamX;
kneeImuParamX=Config.walk.kneeImuParamX;
hipImuParamY=Config.walk.hipImuParamY;
ankleImuParamY=Config.walk.ankleImuParamY;
armImuParamX=Config.walk.armImuParamX;
armImuParamY=Config.walk.armImuParamX;


uLeft0=vector.zeros(3);
uRight0=vector.zeros(3);
uTorso0=vector.zeros(3);
pLLeg = vector.new({0, footY, 0, 0,0,0});
pRLeg = vector.new({0, -footY, 0, 0,0,0});
pTorso = vector.new({supportX, 0, bodyHeight, 0,bodyTilt,0});

align_velocity = vector.new({0,0,0});
align_velocity = vector.new({0,0,-math.pi/6});
tStep = 1.0;




active = false;


--For sally
ph1Single,ph2Single = 0.3,0.7;

tStep = 4.0;
stepHeight = 0.01;
hipRollCompensation = 3*math.pi/180;
supportY = 0.02;


function entry()
  print("Motion SM:".._NAME.." entry");
  walk.stop();
  started = false;
  active = false;
  Body.set_lleg_slope(1);
  Body.set_rleg_slope(1);

end

function set_velocity(vel)
  align_velocity[1]=math.min(math.max(vel[1],-0.04),0.04);
  align_velocity[2]=math.min(math.max(vel[2],-0.04),0.04);
  align_velocity[3]=math.min(math.max(vel[3],-0.3),0.3);
end

function set_supportLeg(sfoot)
  supportLeg=sfoot;
end

function update()
  if (not started and walk.active) then
    walk.update();
    return;
  elseif not started then
    started=true;
    active = true;
    t0 = Body.get_time();
    uTorso = walk.uTorso;
    uLeft = util.pose_global(vector.new({-supportX,footY,0}),uTorso);
    uRight = util.pose_global(vector.new({-supportX,-footY,0}),uTorso);
    uLeft0[1],uLeft0[2],uLeft0[3]=uLeft[1],uLeft[2],uLeft[3];
    uRight0[1],uRight0[2],uRight0[3]=uRight[1],uRight[2],uRight[3];
    zLeft,zRight=0,0;
    step_count=0;
  end
  
  local t=Body.get_time();
  ph=(t-t0)/tStep;

  if ph>1 then --Second step
    step_count=step_count+1;
    if step_count==2 then
      active=false;
      return "done"
    else 
      ph=ph-1;
      t0=t0+tStep;
      supportLeg=1-supportLeg;
      if supportLeg==0 then --left support
	uRightTarget=util.pose_global(vector.new({0,-2*footY,0}),uLeft);
	align_velocity=util.pose_relative(uRightTarget,uRight);
      else
	uLeftTarget=util.pose_global(vector.new({0,2*footY,0}),uRight);
	align_velocity=util.pose_relative(uLeftTarget,uLeft);
      end
    end
  end
  Xfoot,Zfoot=foot_phase(ph);
  uTorso=motion_torso(ph);

  yaw0=(uLeft0[3]+uRight0[3])/2;
  if step_count==0 then
    uTorso[3]=yaw0 + ph*align_velocity[3]/2;
  else
    uTorso[3]=yaw0 + (ph+1)*align_velocity[3]/2;
  end




  if supportLeg==0 then --left support
    uRight = util.pose_global(Xfoot * align_velocity,uRight0)
    zLeft,zRight=0,Zfoot*stepHeight;
  else
    uLeft = util.pose_global(Xfoot * align_velocity,uLeft0)
    zLeft,zRight=Zfoot*stepHeight,0;
  end

  uTorsoActual=util.pose_global(vector.new({-footX,0,0}),uTorso);
  pTorso[1],pTorso[2],pTorso[6]=uTorsoActual[1],uTorsoActual[2],uTorsoActual[3];
  pLLeg[1],pLLeg[2],pLLeg[3],pLLeg[6]=uLeft[1],uLeft[2],zLeft,uLeft[3];
  pRLeg[1],pRLeg[2],pRLeg[3],pRLeg[6]=uRight[1],uRight[2],zRight,uRight[3];

  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);

  walk.uLeft=uLeft;
  walk.uRight=uRight;
  walk.uTorso=uTorso;

  motion_legs(qLegs);
  motion_arms();
end

function motion_torso(ph)
  --simple static walk with linear body movement 
  local uTorso,uSupport;
  local uMid = util.se2_interpolate(0.5,uLeft,uRight);
  if supportLeg==0 then
    uSupport = util.pose_global(vector.new({supportX,supportY,0}),uLeft);
  else
    uSupport = util.pose_global(vector.new({supportX,-supportY,0}),uRight);
  end

  if ph<ph1Single then
    k = ph/ph1Single;
  elseif ph>ph2Single then
    k = (1-ph)/(1-ph2Single);
  else
    k=1;
  end
  k_eff= 0.5*(1-math.cos(math.pi*k));
  uTorso=util.se2_interpolate(k_eff,uMid,uSupport);
  return uTorso;
end

function foot_phase(ph)
  -- Computes relative x,z motion of foot during single support phase
  -- phSingle = 0: x=0, z=0, phSingle = 1: x=1,z=0
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local phSingleSkew = phSingle^0.8 - 0.17*phSingle*(1-phSingle);
  local xf = .5*(1-math.cos(math.pi*phSingleSkew));
  local zf = .5*(1-math.cos(2*math.pi*phSingleSkew));
  return xf,zf;
end

function motion_legs(qLegs)
  phComp = math.min(1, phSingle/.1, (1-phSingle)/.1);

  --Ankle stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyrRPY();

  gyro_roll0=imuGyr[1];
  gyro_pitch0=imuGyr[2];

  gyro_roll0,  gyro_pitch0 = 0,0;

  --get effective gyro angle considering body angle offset
  if not active then --double support
    yawAngle = (uLeft[3]+uRight[3])/2-uTorsoActual[3];
  elseif supportLeg == 0 then  -- Left support
    yawAngle = uLeft[3]-uTorsoActual[3];
  elseif supportLeg==1 then
    yawAngle = uRight[3]-uTorsoActual[3];
  end
  gyro_roll = gyro_roll0*math.cos(yawAngle) +
    -gyro_pitch0* math.sin(yawAngle);
  gyro_pitch = gyro_pitch0*math.cos(yawAngle)
    -gyro_roll0* math.sin(yawAngle);

  ankleShiftX=util.procFunc(gyro_pitch*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4]);
  ankleShiftY=util.procFunc(gyro_roll*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4]);
  kneeShiftX=util.procFunc(gyro_pitch*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4]);
  hipShiftY=util.procFunc(gyro_roll*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4]);
  armShiftX=util.procFunc(gyro_pitch*armImuParamY[2],armImuParamY[3],armImuParamY[4]);
  armShiftY=util.procFunc(gyro_roll*armImuParamY[2],armImuParamY[3],armImuParamY[4]);

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);
  kneeShift=kneeShift+kneeImuParamX[1]*(kneeShiftX-kneeShift);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);
  armShift[1]=armShift[1]+armImuParamX[1]*(armShiftX-armShift[1]);
  armShift[2]=armShift[2]+armImuParamY[1]*(armShiftY-armShift[2]);

  --TODO: Toe/heel lifting
  toeTipCompensation = 0;

  if not active then --Double support, standing still
    qLegs[4] = qLegs[4] + kneeShift;    --Knee pitch stabilization
    qLegs[5] = qLegs[5]  + ankleShift[1];    --Ankle pitch stabilization

    qLegs[10] = qLegs[10] + kneeShift;    --Knee pitch stabilization
    qLegs[11] = qLegs[11]  + ankleShift[1];    --Ankle pitch stabilization

  elseif supportLeg == 0 then  -- Left support
    qLegs[2] = qLegs[2] + hipShift[2];    --Hip roll stabilization
    qLegs[4] = qLegs[4] + kneeShift;    --Knee pitch stabilization
    qLegs[5] = qLegs[5]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[6] = qLegs[6] + ankleShift[2];    --Ankle roll stabilization

    qLegs[11] = qLegs[11]  + toeTipCompensation*phComp;--Lifting toetip
    qLegs[2] = qLegs[2] + hipRollCompensation*phComp; --Hip roll compensation
  else
    qLegs[8] = qLegs[8]  + hipShift[2];    --Hip roll stabilization
    qLegs[10] = qLegs[10] + kneeShift;    --Knee pitch stabilization
    qLegs[11] = qLegs[11]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[12] = qLegs[12] + ankleShift[2];    --Ankle roll stabilization

    qLegs[5] = qLegs[5]  + toeTipCompensation*phComp;--Lifting toetip
    qLegs[8] = qLegs[8] - hipRollCompensation*phComp;--Hip roll compensation
  end

  Body.set_lleg_command(qLegs);
end

function motion_arms()
  local qLArmActual={};   
  local qRArmActual={};   
  qLArmActual[1],qLArmActual[2]=qLArm0[1]+armShift[1],qLArm0[2]+armShift[2];
  qRArmActual[1],qRArmActual[2]=qRArm0[1]+armShift[1],qRArm0[2]+armShift[2];
  qLArmActual[2]=math.max(8*math.pi/180,qLArmActual[2])
  qRArmActual[2]=math.min(-8*math.pi/180,qRArmActual[2]);
  qLArmActual[3]=qLArm0[3];
  qRArmActual[3]=qRArm0[3];
  Body.set_larm_command(qLArmActual);
  Body.set_rarm_command(qRArmActual);
end

function exit()
  print("Align exit");
  active = false;
  Body.set_lleg_slope(0);
  Body.set_rleg_slope(0);

end

