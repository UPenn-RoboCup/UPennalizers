module(..., package.seeall);

require('Body')
require('Kinematics')
require('Config');
require('vector')
require('mcm')
require('unix')
require('util')


-- Walk Parameters
-- Stance and velocity limit values
stanceLimitX=Config.walk.stanceLimitX or {-0.10 , 0.10};
stanceLimitY=Config.walk.stanceLimitY or {0.09 , 0.20};
stanceLimitA=Config.walk.stanceLimitA or {-0*math.pi/180, 40*math.pi/180};
velLimitX = Config.walk.velLimitX or {-.06, .08};
velLimitY = Config.walk.velLimitY or {-.06, .06};
velLimitA = Config.walk.velLimitA or {-.4, .4};
velDelta = Config.walk.velDelta or {.03,.015,.15};
vaFactor = Config.walk.vaFactor or 0.6;

velXHigh = Config.walk.velXHigh or 0.06;
velDeltaXHigh = Config.walk.velDeltaXHigh or 0.01;

--Toe/heel overlap checking values
footSizeX = Config.walk.footSizeX or {-0.05,0.05};
stanceLimitMarginY = Config.walk.stanceLimitMarginY or 0.015;
stanceLimitY2= 2* Config.walk.footY-stanceLimitMarginY;

--OP default stance width: 0.0375*2 = 0.075
--Heel overlap At radian 0.15 at each foot = 0.05*sin(0.15)*2=0.015
--Heel overlap At radian 0.30 at each foot = 0.05*sin(0.15)*2=0.030

--Stance parameters
bodyHeight = Config.walk.bodyHeight;
bodyTilt=Config.walk.bodyTilt or 0;
footX = mcm.get_footX();
footY = Config.walk.footY;
supportX = Config.walk.supportX;
supportY = Config.walk.supportY;
qLArm0=Config.walk.qLArm;
qRArm0=Config.walk.qRArm;
qLArmKick0=Config.walk.qLArmKick;
qRArmKick0=Config.walk.qRArmKick;

--Hardness parameters
hardnessSupport = Config.walk.hardnessSupport or 0.7;
hardnessSwing = Config.walk.hardnessSwing or 0.5;

hardnessArm0 = Config.walk.hardnessArm or 0.2;
hardnessArm = Config.walk.hardnessArm or 0.2;

--Gait parameters
tStep0 = Config.walk.tStep;
tStep = Config.walk.tStep;
tZmp = Config.walk.tZmp;
stepHeight0 = Config.walk.stepHeight;
stepHeight = Config.walk.stepHeight;
ph1Single = Config.walk.phSingle[1];
ph2Single = Config.walk.phSingle[2];
ph1Zmp,ph2Zmp=ph1Single,ph2Single;

--Compensation parameters
hipRollCompensation = Config.walk.hipRollCompensation;
ankleMod = Config.walk.ankleMod or {0,0};
spreadComp = Config.walk.spreadComp or 0;
turnCompThreshold = Config.walk.turnCompThreshold or 0;
turnComp = Config.walk.turnComp or 0;

--Gyro stabilization parameters
ankleImuParamX = Config.walk.ankleImuParamX;
ankleImuParamY = Config.walk.ankleImuParamY;
kneeImuParamX = Config.walk.kneeImuParamX;
hipImuParamY = Config.walk.hipImuParamY;
armImuParamX = Config.walk.armImuParamX;
armImuParamY = Config.walk.armImuParamY;

--Support bias parameters to reduce backlash-based instability
velFastForward = Config.walk.velFastForward or 0.06;
velFastTurn = Config.walk.velFastTurn or 0.2;
supportFront = Config.walk.supportFront or 0;
supportFront2 = Config.walk.supportFront2 or 0;
supportBack = Config.walk.supportBack or 0;
supportSideX = Config.walk.supportSideX or 0;
supportSideY = Config.walk.supportSideY or 0;
supportTurn = Config.walk.supportTurn or 0;

frontComp = Config.walk.frontComp or 0.003;
AccelComp = Config.walk.AccelComp or 0.003;

--Initial body swing 
supportModYInitial = Config.walk.supportModYInitial or 0;

--WalkKick parameters
walkKickDef = Config.kick.walkKickDef;
walkKickPh = Config.kick.walkKickPh;
toeTipCompensation = 0;

use_alternative_trajectory = Config.walk.use_alternative_trajectory or 0;

----------------------------------------------------------
-- Walk state variables
----------------------------------------------------------

uTorso = vector.new({supportX, 0, 0});
uLeft = vector.new({0, footY, 0});
uRight = vector.new({0, -footY, 0});

pLLeg = vector.new({0, footY, 0, 0,0,0});
pRLeg = vector.new({0, -footY, 0, 0,0,0});
pTorso = vector.new({supportX, 0, bodyHeight, 0,bodyTilt,0});

velCurrent = vector.new({0, 0, 0});
velCommand = vector.new({0, 0, 0});
velDiff = vector.new({0, 0, 0});

--ZMP exponential coefficients:
aXP, aXN, aYP, aYN = 0, 0, 0, 0;

--Gyro stabilization variables
ankleShift = vector.new({0, 0});
kneeShift = 0;
hipShift = vector.new({0,0});
armShift = vector.new({0, 0});

active = true;
started = false;
iStep0 = -1;
iStep = 0;
t0 = Body.get_time();
tLastStep = Body.get_time();
ph0=0;ph=0;

stopRequest = 2;
canWalkKick = 1; --Can we do walkkick with this walk code?
walkKickRequest = 0; 
walkKick = walkKickDef["FrontLeft"];
current_step_type = 0;

initial_step=2;

upper_body_overridden = 0;
motion_playing = 0;

qLArmOR0,qRArmOR0={},{};
qLArmOR0[1],qLArmOR0[2],qLArmOR0[3]=qLArm0[1],qLArm0[2],qLArm0[3];
qRArmOR0[1],qRArmOR0[2],qRArmOR0[3]=qRArm0[1],qRArm0[2],qRArm0[3];
bodyRot0 = {0,bodyTilt,0};

qLArmOR,qRArmOR={},{};
qLArmOR[1],qLArmOR[2],qLArmOR[3]=qLArm0[1],qLArm0[2],qLArm0[3];
qRArmOR[1],qRArmOR[2],qRArmOR[3]=qRArm0[1],qRArm0[2],qRArm0[3];
bodyRot = {0,bodyTilt,0};

qLArmOR1 = {0,0,0};
qRArmOR1 = {0,0,0};
bodyRot1 = {0,0,0};

phSingle = 0;

--Current arm pose
qLArm=math.pi/180*vector.new({90,40,-160});
qRArm=math.pi/180*vector.new({90,-40,-160});

--qLArm0={qLArm[1],qLArm[2]};
--qRArm0={qRArm[1],qRArm[2]};

--Standard offset 
uLRFootOffset = vector.new({0,footY+supportY,0});






--Walking/Stepping transition variables
uLeftI = {0,0,0};
uRightI = {0,0,0};
uTorsoI = {0,0,0};
supportI = 0;
start_from_step = false;


comdot = {0,0};
stepkick_ready = false;
has_ball = 0;

----------------------------------------------------------
-- End initialization 
----------------------------------------------------------


--Direct control of upper body
function upper_body_override(qL, qR, bR)
  upper_body_overridden = 1;
  qLArmOR0 = qL;
  qRArmOR0 = qR;
  bR[1] = -1*bR[1];
  bR[2] = -1*bR[2];
  bodyRot0 = bR;

  --Simple exponential filtering
  alphaArm = 0.2;
  alphaBody = 0.05;

  qLArmOR[1] = alphaArm * qLArmOR0[1] + (1-alphaArm)*qLArmOR[1];
  qLArmOR[2] = alphaArm * qLArmOR0[2] + (1-alphaArm)*qLArmOR[2];
  qLArmOR[3] = alphaArm * qLArmOR0[3] + (1-alphaArm)*qLArmOR[3];

  qRArmOR[1] = alphaArm * qRArmOR0[1] + (1-alphaArm)*qRArmOR[1];
  qRArmOR[2] = alphaArm * qRArmOR0[2] + (1-alphaArm)*qRArmOR[2];
  qRArmOR[3] = alphaArm * qRArmOR0[3] + (1-alphaArm)*qRArmOR[3];

  bodyRot[1] = alphaBody * bodyRot0[1] + (1-alphaBody)*bodyRot[1];
  bodyRot[2] = alphaBody * bodyRot0[2] + (1-alphaBody)*bodyRot[2];
  bodyRot[3] = alphaBody * bodyRot0[3] + (1-alphaBody)*bodyRot[3];

  bodyRot[2] = 	math.min(30*math.pi/180,math.max(10*math.pi/180,bodyRot[2]));
  -- Limit the yawing so that we can maintain good balance
  bodyRot[3] = 	math.min(30*math.pi/180,math.max(-30*math.pi/180,bodyRot[3]));
end


function upper_body_override_on()
  upper_body_overridden = 1;
  hardnessArm = 1;
end

function upper_body_override_off()
  upper_body_overridden = 0;
  hardnessArm = hardnessArm0;
end

function entry()
  print ("Motion: Walk entry")
  --SJ: now we always assume that we start walking with feet together
  --Because joint readings are not always available with darwins
  stance_reset();

  --Place arms in appropriate position at sides
  if has_ball==0 then
    Body.set_larm_command(qLArm0);
    Body.set_rarm_command(qRArm0);
    Body.set_larm_hardness(hardnessArm);
    Body.set_rarm_hardness(hardnessArm);
  end

  walkKickRequest = 0;
  stepkick_ready = false;
  stepKickRequest=0;
  velCurrent = {0,0,0};
  velCommand = {0,0,0};
end


function update()

  advanceMotion();
  footX = mcm.get_footX();

  t = Body.get_time();

  --Don't run update if the robot is sitting or standing
  bodyHeightCurrent = vcm.get_camera_bodyHeight();
  if  bodyHeightCurrent<bodyHeight-0.01 then
    return;
  end

  if (not active) then 
    mcm.set_walk_isMoving(0); --not walking
    update_still();
    return; 
  end

  if not started then
    started=true;
    tLastStep = Body.get_time();
  end
  ph0=ph;
  mcm.set_walk_isMoving(1); --walking

  --SJ: Variable tStep support for walkkick
  ph = (t-tLastStep)/tStep;
  if ph>1 then
    iStep=iStep+1;
    ph=ph-math.floor(ph);
    tLastStep=tLastStep+tStep;
  end

  --Stop when stopping sequence is done
  if (iStep > iStep0) and(stopRequest==2) then
    stopRequest = 0;
    active = false;
    return "stop";
  end

  -- New step
  if (iStep > iStep0) then
    update_velocity();
    iStep0 = iStep;
    supportLeg = iStep % 2; -- 0 for left support, 1 for right support
    uLeft1 = uLeft2;
    uRight1 = uRight2;
    uTorso1 = uTorso2;

    supportMod = {0,0}; --Support Point modulation for walkkick
    shiftFactor = 0.5; --How much should we shift final Torso pose?

    check_walkkick(); 
    check_stepkick(); 

    if stepkick_ready then
      stepkick.init_switch(uLeft,uRight,uTorso,comdot);
      return "step";
    end

    if walkKickRequest==0 and stepKickRequest == 0 then
      if (stopRequest==1) then 
        stopRequest=2;
        velCurrent=vector.new({0,0,0});
        velCommand=vector.new({0,0,0});
        if supportLeg == 0 then        -- Left support
          uRight2 = util.pose_global(-2*uLRFootOffset, uLeft1);
        else        -- Right support
          uLeft2 = util.pose_global(2*uLRFootOffset, uRight1);
        end
      else --Normal walk, advance steps
        tStep=tStep0; 
        if supportLeg == 0 then-- Left support
          uRight2 = step_right_destination(velCurrent, uLeft1, uRight1);
        else  -- Right support
          uLeft2 = step_left_destination(velCurrent, uLeft1, uRight1);
        end
        --Velocity-based support point modulation
        toeTipCompensation = 0;
        if velDiff[1]>0 then --Accelerating to front
          supportMod[1] = supportFront2;
        elseif velCurrent[1]>velFastForward then
          supportMod[1] = supportFront;
          toeTipCompensation = ankleMod[1];
        elseif velCurrent[1]<0 then
          supportMod[1] = supportBack;
        elseif math.abs(velCurrent[3])>velFastTurn then
          supportMod[1] = supportTurn; 
        else
          if velCurrent[2]>0.015 then
            supportMod[1] = supportSideX; 
            supportMod[2] = supportSideY; 
          elseif velCurrent[2]<-0.015 then
            supportMod[1] = supportSideX; 
            supportMod[2] = -supportSideY; 
          end
        end
      end
    end

    uTorso2 = step_torso(uLeft2, uRight2,shiftFactor);

    --Adjustable initial step body swing
    if initial_step>0 then 
      if supportLeg == 0 then --LS
        supportMod[2]=supportModYInitial;
      else --RS
        supportMod[2]=-supportModYInitial;
      end
    end





    --Apply velocity-based support point modulation for uSupport
    if supportLeg == 0 then --LS
      local uLeftTorso = util.pose_relative(uLeft1,uTorso1);
      local uTorsoModded = util.pose_global(
      vector.new({supportMod[1],supportMod[2],0}),uTorso);
      local uLeftModded = util.pose_global (uLeftTorso,uTorsoModded); 
      uSupport = util.pose_global(
      {supportX, supportY, 0},uLeftModded);
      Body.set_lleg_hardness(hardnessSupport);
      Body.set_rleg_hardness(hardnessSwing);
    else --RS
      local uRightTorso = util.pose_relative(uRight1,uTorso1);
      local uTorsoModded = util.pose_global(
      vector.new({supportMod[1],supportMod[2],0}),uTorso);
      local uRightModded = util.pose_global (uRightTorso,uTorsoModded); 
      uSupport = util.pose_global(
      {supportX, -supportY, 0}, uRightModded);
      Body.set_lleg_hardness(hardnessSwing);
      Body.set_rleg_hardness(hardnessSupport);
    end

    --Compute ZMP coefficients
    m1X = (uSupport[1]-uTorso1[1])/(tStep*ph1Zmp);
    m2X = (uTorso2[1]-uSupport[1])/(tStep*(1-ph2Zmp));
    m1Y = (uSupport[2]-uTorso1[2])/(tStep*ph1Zmp);
    m2Y = (uTorso2[2]-uSupport[2])/(tStep*(1-ph2Zmp));
    aXP, aXN = zmp_solve(uSupport[1], uTorso1[1], uTorso2[1],
    uTorso1[1], uTorso2[1]);
    aYP, aYN = zmp_solve(uSupport[2], uTorso1[2], uTorso2[2],
    uTorso1[2], uTorso2[2]);

    --Compute COM speed at the boundary 

    dx0=(aXP-aXN)/tZmp + m1X* (1-math.cosh(ph1Zmp*tStep/tZmp));
    dy0=(aYP-aYN)/tZmp + m1Y* (1-math.cosh(ph1Zmp*tStep/tZmp));

    dx1=(aXP*math.exp(tStep/tZmp)-aXN*math.exp(-tStep/tZmp))/tZmp 
	+ m2X* (1-math.cosh((1-ph2Zmp)*tStep/tZmp));
    dy1=(aYP*math.exp(tStep/tZmp)-aYN*math.exp(-tStep/tZmp))/tZmp 
	+ m2Y* (1-math.cosh((1-ph2Zmp)*tStep/tZmp));

--    print("xdot0:",dx0,dy0);
--    print("xdot1:",dx1,dy1);
    comdot = {dx1,dy1}; --Final COM velocity 

  end --End new step

  xFoot, zFoot = foot_phase(ph);  
  if initial_step>0 then zFoot=0;  end --Don't lift foot at initial step
  pLLeg[3], pRLeg[3] = 0;
  if supportLeg == 0 then    -- Left support
    if current_step_type>1 then --walkkick
      if xFoot<walkKickPh then uRight = 
        util.se2_interpolate(xFoot*2, uRight1, uRight15);
      else uRight = util.se2_interpolate(xFoot*2-1, uRight15, uRight2);
      end
    else
      uRight = util.se2_interpolate(xFoot, uRight1, uRight2);
    end
    pRLeg[3] = stepHeight*zFoot;
  else    -- Right support
    if current_step_type>1 then --walkkick
      if xFoot<walkKickPh then uLeft = util.se2_interpolate(xFoot*2, uLeft1, uLeft15);
      else uLeft = util.se2_interpolate(xFoot*2-1, uLeft15, uLeft2);      
      end
    else
      uLeft = util.se2_interpolate(xFoot, uLeft1, uLeft2);
    end
    pLLeg[3] = stepHeight*zFoot;
  end
  uTorsoOld=uTorso;

  uTorso = zmp_com(ph);

  --Turning
  local turnCompX=0;
  if math.abs(velCurrent[3])>turnCompThreshold and
    velCurrent[1]>-0.01 then
    turnCompX = turnComp;
  end

  --Walking front
  local frontCompX = 0;
  if velCurrent[1]>0.04 then 
    frontCompX = frontComp;
  end
  if velDiff[1]>0.02 then
    frontCompX = frontCompX + AccelComp;
  end

  --Arm movement compensation
  if upper_body_overridden>0 or motion_playing > 0 then
    --mass shift to X
    elbowX = 
    - math.sin(qLArmOR[1]-math.pi/2+bodyRot[1])*math.cos(qLArmOR[2])
    - math.sin(qRArmOR[1]-math.pi/2+bodyRot[1])*math.cos(qRArmOR[2]);
    --mass shift to Y
    elbowY = math.sin(qLArmOR[2]) + math.sin(qRArmOR[2]);
    armPosCompX = elbowX * - 0.009;
    armPosCompY = elbowY * - 0.009;

    pTorso[4], pTorso[5],pTorso[6] = 
    bodyRot[1],bodyRot[2],bodyRot[3];
  else
    armPosCompX, armPosCompY = 0,0;
    pTorso[4], pTorso[5],pTorso[6] = 
    0,bodyTilt,0;
  end

  if has_ball>0 then
    turnCompX = turnCompX - 0.01;
  end



  uTorsoActual = util.pose_global(
    vector.new({-footX+frontCompX+turnCompX+armPosCompX,armPosCompY,0}),
    uTorso);
  pTorso[1], pTorso[2] = uTorsoActual[1],uTorsoActual[2]; 
  pTorso[6] = pTorso[6]+ uTorsoActual[3];
  pLLeg[1], pLLeg[2], pLLeg[6] = uLeft[1], uLeft[2], uLeft[3];
  pRLeg[1], pRLeg[2], pRLeg[6] = uRight[1], uRight[2], uRight[3];

  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, supportLeg);
  motion_legs(qLegs);
  motion_arms();
  -- end motion_body
end

step_check_count = 0;

function check_stepkick()
  if stepKickRequest==0 then 
    step_check_count = 0;
		return; 
	end
  if stepKickRequest==1 then 
    --Check current supporLeg and feet positions
    --and advance steps until ready
    uFootErr = util.pose_relative(uLeft1,
       util.pose_global(2*uLRFootOffset,uRight1) );
    step_check_count = step_check_count + 1;

--[[
print("---------------------")
print("support:",supportLeg,stepKickSupport);
print("uLeft:",uLeft1[1],uLeft1[2],uLeft1[3]*180/math.pi);
print("uRight:",uRight1[1],uRight1[2],uRight1[3]*180/math.pi);
--]]

print("Step check",step_check_count)
print("Err:",uFootErr[1],uFootErr[2],uFootErr[3]*180/math.pi);


    if supportLeg==stepKickSupport then
      if (step_check_count>2) or 
--      ( math.abs(uFootErr[1])<0.02 and
--        math.abs(uFootErr[2])<0.01 and

      ( math.abs(uFootErr[1])<0.02 and
        math.abs(uFootErr[2])<0.01 and


        math.abs(uFootErr[3])<10*math.pi/180) then
        print("Stepkick Ready!!!");
        stepkick_ready = true;
        return; 
      end
    end

    if supportLeg == 0 then
      uRight2 = util.pose_global( -2*uLRFootOffset, uLeft1); 
    else
      uLeft2 = util.pose_global( 2*uLRFootOffset, uRight1); 
    end
  end
end



function check_walkkick()
  --Walkkick def: 
  --tStep stepType supportFoot stepHeight bodyPosMod footPos1 footPos2
  if walkKickRequest==0 then return; end

  if walkKickRequest>0 and
    walkKickRequest>#walkKick then

    print("NEWNEWNEWKICK: WALKKICK DONE");
    walkKickRequest = 0;
    tStep = tStep0;
    stepHeight = stepHeight0;
    current_step_type=0;
    velCurrent=vector.new({0,0,0});
    velCommand=vector.new({0,0,0});
    return;
  end

  if walkKickRequest==1 then 
    --Check current supporLeg and feet positions
    --and advance steps until ready
    uFootErr = util.pose_relative(uLeft1,
       util.pose_global(2*uLRFootOffset,uRight1) );
    if supportLeg~=walkKick[1][3] or 
      math.abs(uFootErr[1])>0.02 or
      math.abs(uFootErr[2])>0.01 or
      math.abs(uFootErr[3])>10*math.pi/180 then
      if supportLeg == 0 then
        uRight2 = util.pose_global( -2*uLRFootOffset, uLeft1); 
      else
        uLeft2 = util.pose_global( 2*uLRFootOffset, uRight1); 
      end
      return;
    end
  end
  --  print("NEWNEWNEWKICK: WALKKICK, count",walkKickRequest);

  tStep = walkKick[walkKickRequest][1];   
  current_step_type = walkKick[walkKickRequest][2];   
  supportLeg = walkKick[walkKickRequest][3];
  stepHeight = walkKick[walkKickRequest][4];
  supportMod = walkKick[walkKickRequest][5];
  shiftFactor = walkKick[walkKickRequest][6];

  if #walkKick[walkKickRequest] <=7 then
    footPos1 =  walkKick[walkKickRequest][7];
    if supportLeg == 0 then
      -- TODO: look at uLRFootOffset for use here
      uRight2 = util.pose_global(
      {footPos1[1],footPos1[2]-2*footY,footPos1[3]},uLeft1);
    else
      uLeft2 = util.pose_global(
      {footPos1[1],footPos1[2]+2*footY,footPos1[3]},uRight1);
    end
  else
    footPos1 =  walkKick[walkKickRequest][7];
    footPos2 =  walkKick[walkKickRequest][8];
    if supportLeg == 0 then
      uRight15 = util.pose_global(
      {footPos1[1],footPos1[2]-2*footY,footPos1[3]},uLeft1);
      uRight2 = util.pose_global(
      {footPos2[1],footPos2[2]-2*footY,footPos2[3]},uLeft1);
    else
      uLeft15 = util.pose_global(
      {footPos1[1],footPos1[2]+2*footY,footPos1[3]},uRight1);
      uLeft2 = util.pose_global(
      {footPos2[1],footPos2[2]+2*footY,footPos2[3]},uRight1);
    end
  end

  walkKickRequest = walkKickRequest + 1;
end


function update_still()
  uTorso = step_torso(uLeft, uRight,0.5);

  --Arm movement compensation
  if upper_body_overridden>0 or motion_playing>0 then
    --mass shift to X
    elbowX = 
    - math.sin(qLArmOR[1]-math.pi/2+bodyRot[1])*math.cos(qLArmOR[2])
    - math.sin(qRArmOR[1]-math.pi/2+bodyRot[1])*math.cos(qRArmOR[2]);
    --mass shift to Y
    elbowY = math.sin(qLArmOR[2]) + math.sin(qRArmOR[2]);
    armPosCompX = elbowX * - 0.007;
    armPosCompY = elbowY * - 0.007;
    pTorso[4], pTorso[5],pTorso[6] = 
    bodyRot[1],bodyRot[2],bodyRot[3];
  else
    armPosCompX, armPosCompY = 0,0;
    pTorso[4], pTorso[5],pTorso[6] = 
    0,bodyTilt,0;
  end

  uTorsoActual = util.pose_global(
    vector.new({-footX+armPosCompX,armPosCompY,0}), uTorso);

  pTorso[6] = pTorso[6]+ uTorsoActual[3];
  pTorso[1], pTorso[2] = uTorsoActual[1],uTorsoActual[2]; 

  pLLeg[1], pLLeg[2], pLLeg[6] = uLeft[1], uLeft[2], uLeft[3];
  pRLeg[1], pRLeg[2], pRLeg[6] = uRight[1], uRight[2], uRight[3];
  
  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, supportLeg);
  motion_legs(qLegs,true);
  motion_arms();
end


function motion_legs(qLegs,gyro_off)
  phComp = math.min(1, phSingle/.1, (1-phSingle)/.1);

  --Ankle stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyrRPY();

  gyro_roll0=imuGyr[1];
  gyro_pitch0=imuGyr[2];
  if gyro_off then  gyro_roll0 = 0; gyro_pitch0 = 0;  end

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

  armShiftX=util.procFunc(gyro_pitch*armImuParamY[2],armImuParamY[3],armImuParamY[4]);
  armShiftY=util.procFunc(gyro_roll*armImuParamY[2],armImuParamY[3],armImuParamY[4]);

  ankleShiftX=util.procFunc(gyro_pitch*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4]);
  ankleShiftY=util.procFunc(gyro_roll*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4]);
  kneeShiftX=util.procFunc(gyro_pitch*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4]);
  hipShiftY=util.procFunc(gyro_roll*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4]);

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);
  kneeShift=kneeShift+kneeImuParamX[1]*(kneeShiftX-kneeShift);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);
  armShift[1]=armShift[1]+armImuParamX[1]*(armShiftX-armShift[1]);
  armShift[2]=armShift[2]+armImuParamY[1]*(armShiftY-armShift[2]);

  --TODO: Toe/heel lifting

  if not active then --Double support, standing still
    --qLegs[2] = qLegs[2] + hipShift[2];    --Hip roll stabilization
    qLegs[4] = qLegs[4] + kneeShift;    --Knee pitch stabilization
    qLegs[5] = qLegs[5]  + ankleShift[1];    --Ankle pitch stabilization
    --qLegs[6] = qLegs[6] + ankleShift[2];    --Ankle roll stabilization

    --qLegs[8] = qLegs[8]  + hipShift[2];    --Hip roll stabilization
    qLegs[10] = qLegs[10] + kneeShift;    --Knee pitch stabilization
    qLegs[11] = qLegs[11]  + ankleShift[1];    --Ankle pitch stabilization
    --qLegs[12] = qLegs[12] + ankleShift[2];    --Ankle roll stabilization

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
  if has_ball>0 then
    return;
  end

  local qLArmActual={};   
  local qRArmActual={};   

  qLArmActual[1],qLArmActual[2]=qLArm0[1]+armShift[1],qLArm0[2]+armShift[2];
  qRArmActual[1],qRArmActual[2]=qRArm0[1]+armShift[1],qRArm0[2]+armShift[2];

  if upper_body_overridden>0 or motion_playing>0 then
    qLArmActual[1],qLArmActual[2],qLArmActual[3]=qLArmOR[1],qLArmOR[2],qLArmOR[3];
    qRArmActual[1],qRArmActual[2],qRArmActual[3]=qRArmOR[1],qRArmOR[2],qRArmOR[3];
  end

  --Check leg hitting
  RotLeftA =  util.mod_angle(uLeft[3] - uTorso[3]);
  RotRightA =  util.mod_angle(uTorso[3] - uRight[3]);

  LLegTorso = util.pose_relative(uLeft,uTorso);
  RLegTorso = util.pose_relative(uRight,uTorso);

  qLArmActual[2]=math.max(
    5*math.pi/180 + math.max(0, RotLeftA)/2
    + math.max(0,LLegTorso[2] - 0.04) /0.02 * 6*math.pi/180
    ,qLArmActual[2])
  qRArmActual[2]=math.min(
    -5*math.pi/180 - math.max(0, RotRightA)/2
    - math.max(0,-RLegTorso[2] - 0.04)/0.02 * 6*math.pi/180
    ,qRArmActual[2]);
  if upper_body_overridden>0 or motion_playing>0 then
  else
    qLArmActual[3]=qLArm0[3];
    qRArmActual[3]=qRArm0[3];
  end
  Body.set_larm_command(qLArmActual);
  Body.set_rarm_command(qRArmActual);
end

function exit()
end

function step_left_destination(vel, uLeft, uRight)
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel, u0);
  local u2 = util.pose_global(.5*vel, u1);
  local uLeftPredict = util.pose_global(uLRFootOffset, u2);
  local uLeftRight = util.pose_relative(uLeftPredict, uRight);
  -- Do not pidgeon toe, cross feet:

  --Check toe and heel overlap
  local toeOverlap= -footSizeX[1]*uLeftRight[3];
  local heelOverlap= -footSizeX[2]*uLeftRight[3];
  local limitY = math.max(stanceLimitY[1],
  stanceLimitY2+math.max(toeOverlap,heelOverlap));

  --print("Toeoverlap Heeloverlap",toeOverlap,heelOverlap,limitY)

  uLeftRight[1] = math.min(math.max(uLeftRight[1], stanceLimitX[1]), stanceLimitX[2]);
  uLeftRight[2] = math.min(math.max(uLeftRight[2], limitY),stanceLimitY[2]);
  uLeftRight[3] = math.min(math.max(uLeftRight[3], stanceLimitA[1]), stanceLimitA[2]);

  return util.pose_global(uLeftRight, uRight);
end

function step_right_destination(vel, uLeft, uRight)
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel, u0);
  local u2 = util.pose_global(.5*vel, u1);
  local uRightPredict = util.pose_global(-1*uLRFootOffset, u2);
  local uRightLeft = util.pose_relative(uRightPredict, uLeft);
  -- Do not pidgeon toe, cross feet:

  --Check toe and heel overlap
  local toeOverlap= footSizeX[1]*uRightLeft[3];
  local heelOverlap= footSizeX[2]*uRightLeft[3];
  local limitY = math.max(stanceLimitY[1],
  stanceLimitY2+math.max(toeOverlap,heelOverlap));

  --print("Toeoverlap Heeloverlap",toeOverlap,heelOverlap,limitY)

  uRightLeft[1] = math.min(math.max(uRightLeft[1], stanceLimitX[1]), stanceLimitX[2]);
  uRightLeft[2] = math.min(math.max(uRightLeft[2], -stanceLimitY[2]), -limitY);
  uRightLeft[3] = math.min(math.max(uRightLeft[3], -stanceLimitA[2]), -stanceLimitA[1]);

  return util.pose_global(uRightLeft, uLeft);
end

function step_torso(uLeft, uRight,shiftFactor)
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  local uLeftSupport = util.pose_global({supportX, supportY, 0}, uLeft);
  local uRightSupport = util.pose_global({supportX, -supportY, 0}, uRight);
  return util.se2_interpolate(shiftFactor, uLeftSupport, uRightSupport);
end

function set_velocity(vx, vy, va)
  --Filter the commanded speed
  vx= math.min(math.max(vx,velLimitX[1]),velLimitX[2]);
  vy= math.min(math.max(vy,velLimitY[1]),velLimitY[2]);
  va= math.min(math.max(va,velLimitA[1]),velLimitA[2]);

  --Slow down when turning
  vFactor = 1-math.abs(va)/vaFactor;

  local stepMag=math.sqrt(vx^2+vy^2);
  local magFactor=math.min(velLimitX[2]*vFactor,stepMag)/(stepMag+0.000001);

  velCommand[1]=vx*magFactor;
  velCommand[2]=vy*magFactor;
  velCommand[3]=va;

  velCommand[1] = math.min(math.max(velCommand[1],velLimitX[1]),velLimitX[2]);
  velCommand[2] = math.min(math.max(velCommand[2],velLimitY[1]),velLimitY[2]);
  velCommand[3] = math.min(math.max(velCommand[3],velLimitA[1]),velLimitA[2]);

end

function update_velocity()
  if velCurrent[1]>velXHigh then
    --Slower accelleration at high speed 
    velDiff[1]= math.min(math.max(velCommand[1]-velCurrent[1],
    -velDelta[1]),velDeltaXHigh); 
  else
    velDiff[1]= math.min(math.max(velCommand[1]-velCurrent[1],
    -velDelta[1]),velDelta[1]);
  end
  velDiff[2]= math.min(math.max(velCommand[2]-velCurrent[2],
  -velDelta[2]),velDelta[2]);
  velDiff[3]= math.min(math.max(velCommand[3]-velCurrent[3],
  -velDelta[3]),velDelta[3]);

  velCurrent[1] = velCurrent[1]+velDiff[1];
  velCurrent[2] = velCurrent[2]+velDiff[2];
  velCurrent[3] = velCurrent[3]+velDiff[3];

  if initial_step>0 then
    velCurrent=vector.new({0,0,0})
    initial_step=initial_step-1;
  end
end

function get_velocity()
  return velCurrent;
end

function start()
  stopRequest = 0;
  if (not active) then
    active = true;
    started = false;
    iStep0 = -1;
    t0 = Body.get_time();
    tLastStep = Body.get_time();
    initial_step=2;
  end
end

function stop()
  --Always stops with feet together (which helps transition)
  stopRequest = math.max(1,stopRequest);
end

function stopAlign() --Depreciated, we always stop with feet together 
  stop()
end

function doWalkKickLeft()

  doStepKickLeft();

--[[
  if walkKickRequest==0 then
    walkKickRequest = 1; 
    walkKick = walkKickDef["FrontLeft"];
  end
--]]
end

function doWalkKickRight()

  doStepKickRight();
--[[
  if walkKickRequest==0 then
    walkKickRequest = 1; 
    walkKick = walkKickDef["FrontRight"];
  end
--]]
end

function doWalkKickLeft2()
  if walkKickRequest==0 then
    walkKickRequest = 1; 
    walkKick = walkKickDef["FrontLeft2"];
  end
end

function doWalkKickRight2()
  if walkKickRequest==0 then
    walkKickRequest = 1; 
    walkKick = walkKickDef["FrontRight2"];
  end
end

function doSideKickLeft()
  if walkKickRequest==0 then
    walkKickRequest = 1; 
    walkKick = walkKickDef["SideLeft"];
  end
end

function doSideKickRight()
  if walkKickRequest==0 then
    walkKickRequest = 1; 
    walkKick = walkKickDef["SideRight"];
  end
end

--dummy function for NSL kick, depreciated
function zero_velocity()
end

function doPunch(punchtype)
  if(punchtype=='left') then
    if walkKickRequest==0 then
      walkKickRequest = 1;
      walkKick = walkKickDef["PunchRight"];
    end
  else
    if walkKickRequest==0 then
      walkKickRequest = 1;
      walkKick = walkKickDef["PunchLeft"];
    end
  end
end

function doStepKickLeft()
  if stepKickRequest==0 then
    mcm.set_walk_isStepping(1);
    support_start, support_end = 
				stepkick.set_kick_type("nonstop_kick_left");
    stepKickRequest = 1; 
    stepKickSupport = support_start;
  end
end

function doStepKickRight()
  if stepKickRequest==0 then
    mcm.set_walk_isStepping(1);
    support_start, support_end = 
				stepkick.set_kick_type("nonstop_kick_right");
    stepKickRequest = 1; 
    stepKickSupport = support_start;
  end
end





function startMotion(motionname)
  if motion_playing==0 then
    motion_playing = 1;
    current_motion = Config.walk.motionDef[motionname];
    motion_index = 1;
    motion_start_time = Body.get_time();

    qLArmOR1 = current_motion[1][2];
    qRArmOR1 = current_motion[1][3];
    bodyRot0 = {0,bodyTilt,0};

    if #current_motion[1] > 3 then
      bodyRot1 = current_motion[1][4];
    else
      bodyRot1 = bodyRot0;
    end

    Body.set_larm_hardness({0.7,0.7,0.7});
    Body.set_rarm_hardness({0.7,0.7,0.7});

  end
end

function advanceMotion()
  if motion_playing==0 then
    return;
  end
  t = Body.get_time();
  cur_motion_frame = current_motion[motion_index];
  ph = (t-motion_start_time) / cur_motion_frame[1];
  if ph>1 then --Advance frame
    if #current_motion == motion_index then
      motion_playing = 0;
      Body.set_larm_hardness(hardnessArm);
      Body.set_rarm_hardness(hardnessArm);

    else
      motion_index = motion_index + 1;
      motion_start_time = t;
      qLArmOR0[1],qLArmOR0[2],qLArmOR0[3]=
      qLArmOR1[1],qLArmOR1[2],qLArmOR1[3];
      qRArmOR0[1],qRArmOR0[2],qRArmOR0[3]=
      qRArmOR1[1],qRArmOR1[2],qRArmOR1[3];
      bodyRot0[1],bodyRot0[2],bodyRot0[3]=
      bodyRot1[1],bodyRot1[2],bodyRot1[3];

      qLArmOR1 = current_motion[motion_index][2];
      qRArmOR1 = current_motion[motion_index][3];
      if #current_motion[1] > 3 then
        bodyRot1 = current_motion[motion_index][4];
      else
        bodyRot1 = bodyRot0;
      end
    end
  else
    qLArmOR[1] = (1-ph) * qLArmOR0[1] + ph* qLArmOR1[1];
    qLArmOR[2] = (1-ph) * qLArmOR0[2] + ph* qLArmOR1[2];
    qLArmOR[3] = (1-ph) * qLArmOR0[3] + ph* qLArmOR1[3];
    qRArmOR[1] = (1-ph) * qRArmOR0[1] + ph* qRArmOR1[1];
    qRArmOR[2] = (1-ph) * qRArmOR0[2] + ph* qRArmOR1[2];
    qRArmOR[3] = (1-ph) * qRArmOR0[3] + ph* qRArmOR1[3];

    bodyRot[1] = (1-ph) * bodyRot0[1] + ph* bodyRot1[1];
    bodyRot[2] = (1-ph) * bodyRot0[2] + ph* bodyRot1[2];
    bodyRot[3] = (1-ph) * bodyRot0[3] + ph* bodyRot1[3];
  end
end

function set_initial_stance(uL,uR,uT,support)
  uLeftI = uL;
  uRightI = uR;
  uTorsoI = uT;
  supportI = support;
  start_from_step = true;
end


function stance_reset() --standup/sitdown/falldown handling
  if start_from_step then
    uLeft = uLeftI;
    uRight = uRightI;
    uTorso = uTorsoI;
    if supportI ==0 then --start with left support
      iStep0 = -1;
      iStep = 0;
    else
      iStep0 = 0; --start with right support
      iStep = 1;
    end
    initial_step = 1; --start walking asap
  else
    print("Stance Resetted")
    uLeft = util.pose_global(vector.new({-supportX, footY, 0}),uTorso);
    uRight = util.pose_global(vector.new({-supportX, -footY, 0}),uTorso);
    iStep0 = -1;
    iStep = 0;
  end
  uLeft1, uLeft2 = uLeft, uLeft;
  uRight1, uRight2 = uRight, uRight;
  uTorso1, uTorso2 = uTorso, uTorso;
  uSupport = uTorso;
  tLastStep=Body.get_time();
  walkKickRequest = 0; 
  current_step_type=0;
  motion_playing = 0;
  upper_body_overridden=0;
  uLRFootOffset = vector.new({0,footY,0});
  start_from_step = false;
end

function switch_stance(stance)
end

function get_odometry(u0)
  if (not u0) then
    u0 = vector.new({0, 0, 0});
  end
  local uFoot = util.se2_interpolate(.5, uLeft, uRight);
  return util.pose_relative(uFoot, u0), uFoot;
end

function get_body_offset()
  local uFoot = util.se2_interpolate(.5, uLeft, uRight);
  return util.pose_relative(uTorso, uFoot);
end

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






--Finds the necessary COM for stability and returns it
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
  --com[3] = .5*(uLeft[3] + uRight[3]);
  --Linear speed turning
  com[3] = ph* (uLeft2[3]+uRight2[3])/2 + (1-ph)* (uLeft1[3]+uRight1[3])/2;
  return com;
end

function foot_phase(ph)
  -- Computes relative x,z motion of foot during single support phase
  -- phSingle = 0: x=0, z=0, phSingle = 1: x=1,z=0
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local phSingleSkew = phSingle^0.8 - 0.17*phSingle*(1-phSingle);
  local xf = .5*(1-math.cos(math.pi*phSingleSkew));
  local zf = .5*(1-math.cos(2*math.pi*phSingleSkew));


  if use_alternative_trajectory>0 then
    ph1FootPhase = 0.1;
    ph2FootPhase = 0.5;
    ph3FootPhase = 0.8;

    exp1FootPhase = 2;
    exp2FootPhase = 2;
    exp3FootPhase = 2;

    zFootLand = 0.3;    

    if phSingle < ph1FootPhase then
      phZTemp = phSingle / ph2FootPhase;
      --      xf = 0;
      --      zf = 1 - (1-phZTemp)^exp1FootPhase;
    elseif phSingle < ph2FootPhase then
      phXTemp = (phSingle-ph1FootPhase)/(ph3FootPhase-ph1FootPhase);
      phZTemp = phSingle / ph2FootPhase;
      --      xf =  .5*(1-math.cos(math.pi*phXTemp));
      --      zf = 1 - (1-phZTemp)^exp1FootPhase;
    elseif phSingle < ph3FootPhase then
      phXTemp = (phSingle-ph1FootPhase)/(ph3FootPhase-ph1FootPhase);
      phZTemp = (phSingle-ph2FootPhase)/(ph3FootPhase-ph2FootPhase);
      --      xf =  .5*(1-math.cos(math.pi*phXTemp));
      --      zf = 1 - phZTemp^exp2FootPhase*(1-zFootLand);
    else
      phZTemp = (1-phSingle) / (1-ph3FootPhase);
      --      xf = 1;
      --      zf = phZTemp^exp3FootPhase*zFootLand;
    end
  end
  return xf, zf;
end

entry();
