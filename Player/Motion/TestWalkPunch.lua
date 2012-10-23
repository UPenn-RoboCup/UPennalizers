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

--Stance parameters
bodyHeight = Config.walk.bodyHeight;
bodyTilt=Config.walk.bodyTilt or 0;
footX = Config.walk.footX or 0;
footY = Config.walk.footY;
supportX = Config.walk.supportX;
supportY = Config.walk.supportY;

qLArm0=math.pi/180*vector.new({135,22,-135});
qRArm0=math.pi/180*vector.new({135,-22,-135});

--qLArm0=Config.walk.qLArm;
--qRArm0=Config.walk.qRArm;
qLArm={qLArm0[1],qLArm0[2],qLArm0[3]};
qRArm={qRArm0[1],qRArm0[2],qRArm0[3]};
hardnessSupport = Config.walk.hardnessSupport or 0.7;
hardnessSwing = Config.walk.hardnessSwing or 0.5;
hardnessArm = Config.walk.hardnessArm or 0.2;

hardnessArm = 1;


qLFootOffset = {0,footY,0};
qRFootOffset = {0,-footY,0};
qTorsoOffset = {-footX,0,0};
---------------------------------------------------------
--Experimental non-uniform stance
--[[
qLFootOffset = {0.02,footY,0};
qRFootOffset = {-0.05,-footY,-45*math.pi/180};
qTorsoOffset = {-footX,0,-10*math.pi/180};

qLFootOffset = {0.04,footY,0};
qRFootOffset = {-0.04,-footY,0};
qTorsoOffset = {-footX,0,0*math.pi/180};


qLFootOffset = {0.02,footY,0};
qRFootOffset = {-0.00,-footY,0};
qTorsoOffset = {-footX,0,0*math.pi/180};
--]]
---------------------------------------------------------

--Gait parameters
tStep0 = Config.walk.tStep;
tStep = Config.walk.tStep;
tZmp = Config.walk.tZmp;
stepHeight = Config.walk.stepHeight;
ph1Single = Config.walk.phSingle[1];
ph2Single = Config.walk.phSingle[2];
if (Config.walk.phZmp) then
  ph1Zmp=Config.walk.phZmp[1];
  ph2Zmp=Config.walk.phZmp[2];
else
  ph1Zmp,ph2Zmp=ph1Single,ph2Single;
end




--Compensation parameters
hipRollCompensation = Config.walk.hipRollCompensation;
ankleMod = Config.walk.ankleMod or {0,0};

--Gyro stabilization parameters
ankleImuParamX = Config.walk.ankleImuParamX;
ankleImuParamY = Config.walk.ankleImuParamY;
kneeImuParamX = Config.walk.kneeImuParamX;
hipImuParamY = Config.walk.hipImuParamY;
armImuParamX = Config.walk.armImuParamX;
armImuParamY = Config.walk.armImuParamY;

--Feedback stabilization parameters
uTorsoShift = vector.zeros(3);

--WalkKick parameters
walkKickVel = Config.walk.walkKickVel;
walkKickSupportMod = Config.walk.walkKickSupportMod;
walkKickHeightFactor = Config.walk.walkKickHeightFactor;

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

--ZMP exponential coefficients:
aXP, aXN, aYP, aYN = 0, 0, 0, 0;

--Gyro stabilization variables
ankleShift = vector.new({0, 0});
kneeShift = 0;
hipShift = vector.new({0,0});
armShift = vector.new({0, 0});

active = false;
iStep0 = -1;
iStep = 0;
t0 = Body.get_time();

stopRequest = 2;
canWalkKick = 1; --Can we do walkkick with this walk code?
walkKickRequest = 0; 
walkKickType = 0;

initdone=false;
initial_step=2;

enable_ankle_pr = true;
enable_hip_pr = false;
enable_step_pr = true;


hipStrategy = 0;
hipAngle = {0,0};
hipTargetAngle = {0,0};
hipStrategyTime = 0;

stepStrategy = 0;
stepStrategyVel = {0,0};
stepStrategyTime=0;



qLArmA=math.pi/180*vector.new({135,22,-135});
qRArmA=math.pi/180*vector.new({135,-22,-135});
qLArmB=math.pi/180*vector.new({90,20,-160});
qRArmB=math.pi/180*vector.new({90,-20,-160});
qLArmC=math.pi/180*vector.new({-20,20,0});
qRArmC=math.pi/180*vector.new({-20,-20,0});

d2=0.03;
d3=0.001;

kick={} kick.p=-0.20; 
t0=1;t1=0.2;t2=0.5;d1=-0.04; --Works fine w/o non-stabilized 3kg punch
step_mag = 0.06;
tStep=0.25;








--t0=1;t1=0.2;t2=0.4;d1=-0.037; 

I_min=-0.13;I_max=0.05;
--All disable
I_min=-50;I_max=50;
enable_ankle_pr = false;





qTorsoOffset = {-footX+d3,0,0};

punchDef = {
    {7, t0, {d1,0,45*math.pi/180},qLArmB,qRArmA},
    {7, t1, {d2,0,-55*math.pi/180},qLArmC,qRArmA},
    {7, t2, {0,0,0},qLArmA,qRArmA},
  }

--Actual OP values
t0=1;t1=0.4;t2=1.4;p=-0.04;d1=-0.03;d2=0.0; --won't fall 

t0=1;t1=0.3;t2=1.4;p=-0.05;d1=-0.03;d2=0.0; --barely stable 

--t0=1;t1=0.3;t2=1.4;p=-0.05;d1=-0.03;d2=0.01; --barely stable 

step_mag = 0.04;
tStep=0.35;

qLArmC=math.pi/180*vector.new({20,20,-20});
qRArmC=math.pi/180*vector.new({20,-20,-20});
	

punchDef = {
    {7, t0, {d1,0,30*math.pi/180},qLArmB,qRArmA},
    {7, t1, {d2,0,-30*math.pi/180},qLArmC,qRArmA},
    {7, t2, {0,0,0},qLArmA,qRArmA},
  }


punchCount=0;
punchStartTime=0;


----------------------------------------------------------
-- End initializat----------------------------------------------------------

function entry()
--  print ("walk entry")
  --SJ: now we always assume that we start walking with feet together
  --Because joint readings are not always available with darwins
  uLeft = util.pose_global(vector.new({-supportX, footY, 0}),uTorso);
  uRight = util.pose_global(vector.new({-supportX, -footY, 0}),uTorso);

  uLeft1, uLeft2 = uLeft, uLeft;
  uRight1, uRight2 = uRight, uRight;
  uTorso1, uTorso2 = uTorso, uTorso;
  uSupport = uTorso;

  pLLeg = vector.new{uLeft[1], uLeft[2], 0, 0, 0, uLeft[3]};
  pRLeg = vector.new{uRight[1], uRight[2], 0, 0, 0, uRight[3]};
  pTorso = vector.new{uTorso[1], uTorso[2], bodyHeight, 0, bodyTilt, uTorso[3]};
   
  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);
  Body.set_lleg_command(qLegs);

  --Place arms in appropriate position at sides
  Body.set_larm_command(qLArm);
  Body.set_larm_hardness(hardnessArm);
  Body.set_rarm_command(qRArm);
  Body.set_rarm_hardness(hardnessArm);

  t = Body.get_time();
  walkKickRequest = 0;

  hipStrategy = 0;
  hipAngle = {0,0};
  hipStrategyTime=t+1.0;

  stepStrategy = 0;
  stepStrategyVel = {0,0};
  stepStrategyTime=t+1.0;

  m1X,m2X,m1Y,m2Y=0,0,0,0;

  uBodyPunch1={0,0,0};
  uBodyPunch={0,0,0};
  qLArmPunch1={qLArm0[1],qLArm0[2],qLArm0[3]};
  qRArmPunch1={qRArm0[1],qRArm0[2],qRArm0[3]};

end


push_recovery_manual = 0;


  gyro_min = 0.7;


  gyro_min = 1.5;


  --step_mag = 0.10;

-- step_mag = 0.12;
  stepFactor1=0.2; --for step strategy alone
--stepFactor1=0.5; --for step strategy alone

stepFactor1=0.5; --for actual OP


function set_push_recovery(ankle,hip,step)
   enable_ankle_pr = ankle;
   enable_hip_pr = hip;
   enable_step_pr = step;
end

function check_step_foot(fx,fy)
    RFootTorso=util.pose_relative(uRight, uTorso);
    LFootTorso=util.pose_relative(uLeft, uTorso);
    footVec = LFootTorso-RFootTorso;
    cosVec = footVec[1]*fx + footVec[2]*fy;

--    print("previous SupportLeg:",supportLeg);

    if cosVec>0 then
       print("Right support");
       sleg= 1;
    else
       print("Left support");
       sleg= 0;
    end

    sleg=0; --Force left support testing   
    sleg=1;
    return sleg;
end


angleTiltOld =0;

gp_old=0;
ip_old=0;
alpha=0.5;
punchPh=0;

function check_push_recovery()
--if punchCount==2 and punchPh<0.5 then return; end

if punchCount<=2 and stepStrategy==0 then return;end

--    imuGyr = Body.get_sensor_imuGyrNormalized();
    imuGyr = Body.get_sensor_imuGyr();
    gyro_roll=imuGyr[1];
    gyro_pitch=imuGyr[2];

    imuAngle = Body.get_sensor_imuAngle();
    imuRoll = imuAngle[1];
    imuPitch = imuAngle[2]-Config.walk.bodyTilt;


gyro_roll=0; --hack
gp_old=(1-alpha)*gp_old + alpha*gyro_pitch;
gyro_min = 1.2;
w=math.sqrt(9.8/0.295);

I=0.295*(imuPitch+gp_old/w);





--  if punchCount==2 then
--   print(string.format("PC: %d Ph:%.3f I:%.3f",punchCount,punchPh,I));
--  end





--print(string.format("gyro %.4f I %.4f",gp_old,I));


--[[
--Rotation compensation
c_punch=math.cos(uBodyPunch[3]);
s_punch=math.sin(uBodyPunch[3]);
gyro_roll=c_punch*imuGyr[1]+s_punch*imuGyr[2];
gyro_pitch=-s_punch*imuGyr[1]+c_punch*imuGyr[2];

imuRoll = c_punch*imuAngle[1]+s_punch*(imuAngle[2]-Config.walk.bodyTilt);
imuPitch = -s_punch*imuAngle[1]+c_punch*(imuAngle[2]-Config.walk.bodyTilt);
print("Gyro roll pitch",gyro_roll,gyro_pitch);
--]]
    llegReading= Body.get_lleg_position();
    rlegReading= Body.get_rleg_position();
    angle1= llegReading[3];
    angle2= rlegReading[3];

    angleTilt=- ((angle1+angle2)/2 + Config.walk.bodyTilt + 28.76*math.pi/180);
    gyroTilt = (angleTilt-angleTiltOld)/0.010;
    angleTiltOld =angleTilt;

--[[  gyro_roll=imuGyr[1];
  gyro_pitch=imuGyr[2];
  imuRoll = imuAngle[1];
  imuPitch = imuAngle[2]-bodyTilt;
--]]

  gyromag= math.sqrt(gp_old^2);


--  gyromag= math.sqrt(gyro_pitch^2+gyro_roll^2);
  imuMag = math.sqrt(imuPitch^2+imuRoll^2);

  if imuMag>60*math.pi/180 
     and stepStrategy==0 
     and hipStrategy==0 then
     Body.set_body_hardness(0);
     return;
  end


  t = Body.get_time();

  tReflex = 0.6;
  tRecover = 0.5;

  tReflex = 0.3;
  tRecover = 0.3;

--Check for gyro angles

--  print("Gyro:",gyro_pitch);


--[[
  if enable_step_pr==true and active then
    if ph<0.6 and stepStrategy==0 and gyromag>1.0 then --Inter-step step strategy
      print("Inter-step strategy")
      stepStrategyVel = {0.06*gyro_pitch/gyromag,0.06*gyro_roll/gyromag,0};

      if supportLeg==0 --left support
          uRightTarget = limit_right(util.pose_global(stepStrategyVel, uTorso));
      else
          uLeftTarget = limit_left(util.pose_global(stepStrategyVel, uTorso));
      end

      print("Vel: ",unpack(stepStrategyVel));
      stepStrategy = 5; --inter-step strategy
    end
  elseif stepStrategy == 0 and enable_step_pr==true then	
--]]


--  print("Gyro IMU:",gyro_pitch,imuPitch*180/math.pi,gyromag)




  if stepStrategy == 0 and enable_step_pr==true and push_recovery_manual==0 then	

--      if gyromag>gyro_min and stepStrategyTime<t then
--      if (I<I_min or I>I_max) and stepStrategyTime<t then
imuTh= 0.05;


imuTh= 0.08;

imuTh=10000; --disable


imuTh2=-0.20;


enable_ankle_pr = true;


      if stepStrategyTime<t and ((imuPitch>imuTh) or (imuPitch<imuTh2)) 
then --for OP, front


gyro_pitch=imuPitch; --hack for OP
gyromag=math.abs(imuPitch);
         supportLegTarget=check_step_foot(gyro_pitch,gyro_roll);
 
         print("Step state 1",I)
         stepStrategy = 1;
         stepStrategyVel = {step_mag*gyro_pitch/gyromag,step_mag*-gyro_roll/gyromag,0};
        
         uRightTarget = limit_right(util.pose_global(stepStrategyVel, uTorso));
         uLeftTarget = limit_left(util.pose_global(stepStrategyVel, uTorso));
         uStepTorsoShift = stepStrategyVel;
   
         uRightTarget = limit_right(util.pose_global(stepStrategyVel, uTorso));
         uLeftTarget = limit_left(util.pose_global(stepStrategyVel, uTorso));
 	 print("Step strategy velocity:",unpack(stepStrategyVel))
      else
--        print("Gyro IMU:",gyro_pitch,imuPitch*180/math.pi,gyromag)
      end
  elseif stepStrategy==3 then
      if t-stepStrategyTime>1.0 then
--        print("Step state END")
        stepStrategy = 0;
--	active=false; --stop walking any more
        stepStrategyTime=t+3;
      end
  end


  if hipStrategy ==0 and enable_hip_pr and push_recovery_manual==0 then
    if t>hipStrategyTime then
      if (I<I_min or I>I_max) and stepStrategyTime<t then
--      if gyromag>gyro_min then
        print("Gyro IMU:",gyro_pitch,gyro_roll,gyromag)

	hipStrategy =1;
        hipTargetAngle = {
		40*math.pi/180*gyro_pitch/gyromag,
		30*math.pi/180*gyro_roll/gyromag
		};

        hipStrategyTime = t;
	print("Hip state 1",t)
      else
--        print("Gyro IMU:",gyro_pitch,imuPitch*180/math.pi)
      end
    end
  elseif hipStrategy ==1 then
    hipAngle[1],hipAngle[2]=hipTargetAngle[1],hipTargetAngle[2];
    if t-hipStrategyTime > tReflex then
--      print("Hip state 2",t) 
      hipStrategy=2;
      hipStrategyTime = t;
    end
  elseif hipStrategy ==2 then
    if t-hipStrategyTime > tRecover then
--      print("Hip state End",t) 
      active=false; --stop walking any more
      hipStrategy=0;
      hipStrategyTime = t+3.0;
    else
      phHip= (t- hipStrategyTime) /tRecover;
      hipAngle[1],hipAngle[2]=(1-phHip)*hipTargetAngle[1],(1-phHip)*hipTargetAngle[2];
    end
  end
end





function new_step()
    t = Body.get_time();
    update_velocity();

    iStep0 = iStep;
    supportLeg = iStep % 2; -- 0 for left support, 1 for right support

    uLeft1 = uLeft2;
    uRight1 = uRight2;
    uTorso1 = uTorso2;

    if stepStrategy==5 then 
      stepStrategy = 0;
    end

    if stepStrategy==2 then
       --reactive stepping done, wait a bit 
       stepStrategyTime=t;
       stepStrategy=3;
--       print("Step state 3")
    end

    --If stop signal sent, put two feet together
    if (stopRequest==1) then  --Final step
      stopRequest=2;
      velCurrent=vector.new({0,0,0});
      if supportLeg == 0 then        -- Left support
        uRight2 = util.pose_global({0,-2*footY,0}, uLeft1);
      else        -- Right support
        uLeft2 = util.pose_global({0,2*footY,0}, uRight1);
      end
    end

    --Code to check walk-kick phases
    supportMod = {0,0}; --Support Point modulation for walkkick
   
    if walkKickRequest ==1 then --If step is right skip 1st step
      if supportLeg==walkKickType then 
	walkKickRequest = 2;
      end
    end

    if walkKickRequest == 1 then -- Feet together
      if supportLeg == 0 then uRight2 = util.pose_global({0,-2*footY,0}, uLeft1); 
      else uLeft2 = util.pose_global({0,2*footY,0}, uRight1); 
      end
      walkKickRequest = walkKickRequest + 1;
    elseif walkKickRequest ==2 then -- Support step forward
      if supportLeg == 0 then uRight2 = util.pose_global({walkKickVel[1],-2*footY,0}, uLeft1);
      else uLeft2 = util.pose_global({walkKickVel[1],2*footY,0}, uRight1); 
      end
      supportMod = walkKickSupportMod[1];
      walkKickRequest = walkKickRequest + 1;
    elseif walkKickRequest ==3 then -- Kicking step forward
      if supportLeg == 0 then uRight2 = util.pose_global({walkKickVel[2],-2*footY,0}, uLeft1);
      else uLeft2 = util.pose_global({walkKickVel[2],2*footY,0}, uRight1);--RS
      end
      supportMod = walkKickSupportMod[2];
      walkKickRequest = walkKickRequest + 1;

    else --Normal walk
      if supportLeg == 0 then-- Left support
        uRight2 = step_right_destination(velCurrent, uLeft1, uRight1);
      else  -- Right support
        uLeft2 = step_left_destination(velCurrent, uLeft1, uRight1);
      end
      walkKickRequest = 0; 
    end

    uTorso2 = step_torso(uLeft2, uRight2);

    if stepStrategy==1 then	
       --2 means reactive intra-step stepping
--       print("Step state 2")
       supportLeg = supportLegTarget;

       if supportLeg ==0 then --left support
 	  uRight2 = uRightTarget;
          uTorso2 = util.se2_interpolate(1-stepFactor1,uLeft2, uRight2);
       else
 	  uLeft2=uLeftTarget;
          uTorso2 = util.se2_interpolate(stepFactor1,uLeft2, uRight2);
       end

       stepStrategy=2;
	--More support bias for step strategy from DS
       if not active then 
 	 supportMod[2] = 0.04;
       end
    end

    if supportLeg == 0 then --LS
        uSupport = util.pose_global({supportX+supportMod[1], supportY+supportMod[2], 0}, uLeft);
        Body.set_lleg_hardness(hardnessSupport);
        Body.set_rleg_hardness(hardnessSwing);
    else --RS
        uSupport = util.pose_global({supportX+supportMod[1], -supportY-supportMod[2], 0}, uRight);
        Body.set_lleg_hardness(hardnessSwing);
        Body.set_rleg_hardness(hardnessSupport);
    end


--[[
    if stepStrategy==1 then
      uTorsoTemp = step_torso(uLeft2, uRight2);
      if supportLeg == 0 then --LS
         uRightCapture = util.se2_interpolate(0.5,uRight1,uRight2)
         uTorso2 = util.se2_interpolate(0.5,uLeft1,uRightCapture);
      else
         uLeftCapture = util.se2_interpolate(0.5,uLeft1,uLeft2)
         uTorso2 = util.se2_interpolate(0.5,uRight1,uLeftCapture);
      end
    end
--]]

    --TODO:Velocity based support point modulation

--print("new torso X:",uTorso2[1])

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


function update()

  if (active and stepStrategy~=3 and hipStrategy~=2) then
    is_stepping=true;
    t = Body.get_time();
    iStep, ph = math.modf((t-t0)/tStep);
    --Stop when stopping sequence is done
    if (iStep > iStep0) and(stopRequest==2) then
      stopRequest = 0;
      active = false;
      return "stop";
    end
    if (iStep > iStep0) then     -- New step
      new_step();
    end
  elseif (not active) then
    if stepStrategy==1 then
      new_step();
      t0=t;
    elseif stepStrategy==2 then
      iStep, ph = math.modf((t-t0)/tStep);
      if t>t0+tStep then new_step();end
    else
      is_stepping=false;
      t0=t;
      iStep=iStep0;
      ph = 0;
    end
  end     
  
  xFoot, zFoot = foot_phase(ph);  
  pLLeg[3], pRLeg[3] = 0;

  if stepStrategy ==2 then
    zFoot = zFoot * 2 ;
  else
    if initial_step>0 then zFoot=0;  end --Don't lift foot at initial step
  end


  footStepPitch0 = stepStrategyVel[1]/step_mag * 5*math.pi/180;

footStepPitch0 = 0; --for actual OP



  if stepStrategy==1 then
     footStepPitch=footStepPitch0;
  elseif stepStrategy==2 then
     footStepPitch=footStepPitch0;
  elseif stepStrategy==3 then
    footStepPitch=  (stepStrategyTime+1.0-t)*footStepPitch0;
  else
    footStepPitch = 0;
  end

  --disable ankle tilt for stepping
--  footStepPitch = 0;



--  print("ph:",ph)
  legHeight = 0.30;

  if supportLeg == 0 then    -- Left support
    uRight = util.se2_interpolate(xFoot, uRight1, uRight2);
    pRLeg[3] = stepHeight*zFoot;

    pRLeg[5] = -footStepPitch;
    pRLeg[3]=pRLeg[3]+legHeight*(1-math.cos(footStepPitch));

  else    -- Right support
    uLeft = util.se2_interpolate(xFoot, uLeft1, uLeft2);
    pLLeg[3] = stepHeight*zFoot;

    pLLeg[5] = -footStepPitch;
    pLLeg[3]=pLLeg[3]+legHeight*(1-math.cos(footStepPitch));
  end

  uTorso = zmp_com(ph);
  check_push_recovery();
  motion_arms();



  uTorsoActual = util.pose_global(qTorsoOffset,uTorso);

  uTorsoActual = util.pose_global(qTorsoOffset+
	vector.new({-0.06*math.sin(hipAngle[1])+  uBodyPunch[1],
	-0.06*math.sin(hipAngle[2]),
	uBodyPunch[3]}),uTorso);

  uTorsoActual = util.pose_global(qTorsoOffset+
	vector.new({-0.06*math.sin(hipAngle[1])+  uBodyPunch[1]-0.005,
	-0.06*math.sin(hipAngle[2]),
	uBodyPunch[3]}),uTorso);
--print("uLeft uTorso",uLeft[1],uTorsoActual[1]);


  pLLeg[1], pLLeg[2], pLLeg[6] = uLeft[1], uLeft[2], uLeft[3];
  pRLeg[1], pRLeg[2], pRLeg[6] = uRight[1], uRight[2], uRight[3];
  pTorso[1], pTorso[2], pTorso[6] = uTorsoActual[1], uTorsoActual[2], uTorsoActual[3];
  pTorso[4],pTorso[5]=hipAngle[2],bodyTilt+hipAngle[1];




  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, supportLeg);
  motion_legs(qLegs);
end

function motion_torso() --Torso swing during walking
  armGain = 0.40;
  torsoAngleMax = 20*math.pi/180;
  local uBodyLeft=util.pose_relative(uLeft,uTorso);
  local uBodyRight=util.pose_relative(uRight,uTorso);
  local footRel=uBodyLeft[1]-uBodyRight[1];
  local torsoAngle=math.min(torsoAngleMax,
	math.max(-torsoAngleMax,
	footRel/armGain * torsoAngleMax
	));  
  uTorso[3]=uTorso[3] + torsoAngle;
end

function motion_legs(qLegs)

-- gyro_pitch=gyro_pitch-gyroTilt; --canceling out body motion

  phComp = math.min(1, phSingle/.1, (1-phSingle)/.1);

  if enable_ankle_pr and punchCount==3 then
    ankleShiftX=util.procFunc(gyro_pitch*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4]);
    ankleShiftY=util.procFunc(gyro_roll*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4]);
    kneeShiftX=util.procFunc(gyro_pitch*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4]);
    hipShiftY=util.procFunc(gyro_roll*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4]);
    armShiftX=util.procFunc(gyro_pitch*armImuParamY[2],armImuParamY[3],armImuParamY[4]);
    armShiftY=util.procFunc(gyro_roll*armImuParamY[2],armImuParamY[3],armImuParamY[4]);
  else
    ankleShiftX=0;
    ankleShiftY=0;
    kneeShiftX=0;
    hipShiftY=0;
    armShiftX=0;
    armShiftY=0;
  end

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);
  kneeShift=kneeShift+kneeImuParamX[1]*(kneeShiftX-kneeShift);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);
  armShift[1]=armShift[1]+armImuParamX[1]*(armShiftX-armShift[1]);
  armShift[2]=armShift[2]+armImuParamY[1]*(armShiftY-armShift[2]);

--TODO: Toe/heel lifting

  toeTipCompensation = 0;

  if (not active) then --Double support, standing still
    qLegs[2] = qLegs[2] + hipShift[2];    --Hip roll stabilization
    qLegs[4] = qLegs[4] + kneeShift;    --Knee pitch stabilization
    qLegs[5] = qLegs[5]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[6] = qLegs[6] + ankleShift[2];    --Ankle roll stabilization

    qLegs[8] = qLegs[8]  + hipShift[2];    --Hip roll stabilization
    qLegs[10] = qLegs[10] + kneeShift;    --Knee pitch stabilization
    qLegs[11] = qLegs[11]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[12] = qLegs[12] + ankleShift[2];    --Ankle roll stabilization
  elseif supportLeg == 0 then  -- Left support
    qLegs[2] = qLegs[2] + hipShift[2];    --Hip roll stabilization
    qLegs[4] = qLegs[4] + kneeShift;    --Knee pitch stabilization
    qLegs[5] = qLegs[5]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[6] = qLegs[6] + ankleShift[2];    --Ankle roll stabilization
    qLegs[11] = qLegs[11]  + toeTipCompensation;

    qLegs[2] = qLegs[2] + hipRollCompensation*phComp; --Hip roll compensation
  else
    qLegs[8] = qLegs[8]  + hipShift[2];    --Hip roll stabilization
    qLegs[10] = qLegs[10] + kneeShift;    --Knee pitch stabilization
    qLegs[11] = qLegs[11]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[12] = qLegs[12] + ankleShift[2];    --Ankle roll stabilization

    --Lifting toetip
    qLegs[5] = qLegs[5]  + toeTipCompensation;
    qLegs[8] = qLegs[8] -hipRollCompensation*phComp;--Hip roll compensation
  end

--[[
  local spread=(uLeft[3]-uRight[3])/2;
  qLegs[5] = qLegs[5] + Config.walk.anklePitchComp[1]*math.cos(spread);
  qLegs[11] = qLegs[11] + Config.walk.anklePitchComp[2]*math.cos(spread);
--]]

  Body.set_lleg_command(qLegs);
end

function motion_arms()

--[[
   armGain = 0.40;

   local uBodyLeft=util.pose_relative(uLeft,uTorso);
   local uBodyRight=util.pose_relative(uRight,uTorso);
   local footRel=uBodyLeft[1]-uBodyRight[1];
   local armAngle=math.min(50*math.pi/180,
	math.max(-50*math.pi/180,
	footRel/armGain * 50*math.pi/180
	));  
  
    armAngle=0;

    qLArm[1],qLArm[2]=qLArm0[1]+armShift[1],qLArm0[2]+armShift[2];
    qRArm[1],qRArm[2]=qRArm0[1]+armShift[1],qRArm0[2]+armShift[2];
    qLArm[1]=qLArm[1]+armAngle;
    qRArm[1]=qRArm[1]-armAngle;

--
  qLArm[1],qLArm[2]=qLArm0[1]+armShift[1],qLArm0[2]+armShift[2];
  qRArm[1],qRArm[2]=qRArm0[1]+armShift[1],qRArm0[2]+armShift[2];
--

  qLArm[2]=math.max(8*math.pi/180,qLArm[2])
  qRArm[2]=math.min(-8*math.pi/180,qRArm[2]);


--]]

  t = Body.get_time();

  if punchCount>0 then
    tPassed = t-punchStartTime;
    punchPh = tPassed/punchDef[punchCount][2];
    if punchPh>1 then
      punchStartTime=punchStartTime+punchDef[punchCount][2];
      punchCount=(punchCount+1)%4;
      punchPh=punchPh-1;
      uBodyPunch1[1],uBodyPunch1[2],uBodyPunch1[3]=uBodyPunch[1],uBodyPunch[2],uBodyPunch[3];
      qLArmPunch1[1],qLArmPunch1[2],qLArmPunch1[3]=qLArm[1],qLArm[2],qLArm[3];
      qRArmPunch1[1],qRArmPunch1[2],qRArmPunch1[3]=qRArm[1],qRArm[2],qRArm[3];
    end
  end
  if punchCount>0 then
    uBodyPunch=util.se2_interpolate(punchPh,uBodyPunch1,punchDef[punchCount][3]);	
    qLArm=util.se2_interpolate(punchPh,qLArmPunch1,punchDef[punchCount][4]);
    qRArm=util.se2_interpolate(punchPh,qRArmPunch1,punchDef[punchCount][5]);

--
    if punchCount==2 then
	x0=uBodyPunch1[1];
	p=kick.p;
	w=math.sqrt(9.8/0.295);
	x=(x0-p)/2*(math.exp(w*tPassed)+math.exp(-w*tPassed))+p;    
	uBodyPunch[1]=math.min(x,uBodyPunch[1]);
    end
--
--print("uBodyPunch:",uBodyPunch[1])
  end
  Body.set_larm_command(qLArm);
  Body.set_rarm_command(qRArm);

end

function exit()
end

function step_left_destination(vel, uLeft, uRight)

  --Discount for foot stance offsets

  local uLeft0 = util.pose_global(-vector.new(qLFootOffset),uLeft)
  local uRight0 = util.pose_global(-vector.new(qRFootOffset),uRight)

  local u0 = util.se2_interpolate(.5, uLeft0, uRight0);

  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel, u0);
  local u2 = util.pose_global(.5*vel, u1);
  local uLeftPredict = util.pose_global(qLFootOffset, u2);

  return limit_left(uLeftPredict);
end

function step_right_destination(vel, uLeft, uRight)

  --Discount for foot stance offsets
  local uLeft0 = util.pose_global(-vector.new(qLFootOffset),uLeft)
  local uRight0 = util.pose_global(-vector.new(qRFootOffset),uRight)

  local u0 = util.se2_interpolate(.5, uLeft, uRight);

  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel, u0);
  local u2 = util.pose_global(.5*vel, u1);
  local uRightPredict = util.pose_global(qRFootOffset, u2);
  return limit_right(uRightPredict);
end

function limit_left(uLeftOrg)
  -- Do not pidgeon toe, cross feet:
  local uLeftRight = util.pose_relative(uLeftOrg, uRight);
  uLeftRight[1] = math.min(math.max(uLeftRight[1], stanceLimitX[1]), stanceLimitX[2]);
  uLeftRight[2] = math.min(math.max(uLeftRight[2], stanceLimitY[1]), stanceLimitY[2]);
  uLeftRight[3] = math.min(math.max(uLeftRight[3], stanceLimitA[1]), stanceLimitA[2]);

  return util.pose_global(uLeftRight, uRight);
end

function limit_right(uRightOrg)
  -- Do not pidgeon toe, cross feet:
  local uRightLeft = util.pose_relative(uRightOrg, uLeft);
  uRightLeft[1] = math.min(math.max(uRightLeft[1], stanceLimitX[1]), stanceLimitX[2]);
  uRightLeft[2] = math.min(math.max(uRightLeft[2], -stanceLimitY[2]), -stanceLimitY[1]);
  uRightLeft[3] = math.min(math.max(uRightLeft[3], -stanceLimitA[2]), -stanceLimitA[1]);

  return util.pose_global(uRightLeft, uLeft);
end




function step_torso(uLeft, uRight)

  local uLeftSupport = util.pose_global({supportX, supportY, 0}, uLeft);
  local uRightSupport = util.pose_global({supportX, -supportY, 0}, uRight);

  --Discount for foot stance offsets
  local uLeftSupport0 = util.pose_global(-vector.new(qLFootOffset),uLeftSupport);
  local uRightSupport0 = util.pose_global(-vector.new(qRFootOffset),uRightSupport);

  return util.se2_interpolate(.5, uLeftSupport0, uRightSupport0);
end

function set_velocity(vx, vy, vz)
  --Filter the commanded speed
--[[
  vz= math.min(math.max(vz,velLimitA[1]),velLimitA[2]);
  local stepMag=math.sqrt(vx^2+vy^2);
  local magFactor=math.min(0.10,stepMag)/(stepMag+0.000001);
--]]

  magFactor = 1;
  velCommand[1]=vx*magFactor;
  velCommand[2]=vy*magFactor;
  velCommand[3]=vz;
end

function update_velocity()
  local velDiff={};
  velDiff[1]= math.min(math.max(velCommand[1]-velCurrent[1],
	-velDelta[1]),velDelta[1]);
  velDiff[2]= math.min(math.max(velCommand[2]-velCurrent[2],
	-velDelta[2]),velDelta[2]);
  velDiff[3]= math.min(math.max(velCommand[3]-velCurrent[3],
	-velDelta[3]),velDelta[3]);

  velCurrent[1] = math.min(math.max(velCurrent[1]+velDiff[1],
	velLimitX[1]),velLimitX[2]);
  velCurrent[2] = math.min(math.max(velCurrent[2]+velDiff[2],
	velLimitY[1]),velLimitY[2]);
  velCurrent[3] = math.min(math.max(velCurrent[3]+velDiff[3],
	velLimitA[1]),velLimitA[2]);

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
    iStep0 = -1;
    t0 = Body.get_time();
    initdone=false;
    initial_step=2;
  end
end

function stop()
  stopRequest = math.max(1,stopRequest);
--  stopRequest = 2;
end

function startPunch()
  t = Body.get_time();

  if punchCount ==0 then
    punchCount=1;
    punchStartTime=t;
  end
end


function stopAlign()
  stop()
end

function doWalkKickLeft()
  if walkKickRequest==0 then
    walkKickRequest = 1; 
    walkKickType = 0; --Start with left support 
  end
end

function doWalkKickRight()
  if walkKickRequest==0 then
    walkKickRequest = 1; 
    walkKickType = 1; --Start with right support
  end
end

--dummy function for NSL kick
function zero_velocity()
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

  com[3] = .5*(uLeft[3] + uRight[3]);

  --Discount for foot angle offsets
  com[3] = com[3] - (qLFootOffset[3]+qRFootOffset[3])/2;

  return com;
end

function foot_phase(ph)
  -- Computes relative x,z motion of foot during single support phase
  -- phSingle = 0: x=0, z=0, phSingle = 1: x=1,z=0
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local phSingleSkew = phSingle^0.8 - 0.17*phSingle*(1-phSingle);
  local xf = .5*(1-math.cos(math.pi*phSingleSkew));
  local zf = .5*(1-math.cos(2*math.pi*phSingleSkew));

  --hack: vertical takeoff and landing
--  factor1 = 0.2;
  factor1 = 0;
  factor2 = 0;
  phSingleSkew2 = math.max(
	math.min(1,
	(phSingleSkew-factor1)/(1-factor1-factor2)
	 ), 0);
  local xf = .5*(1-math.cos(math.pi*phSingleSkew2));

  --Check for walkkick step
  if walkKickRequest == 4 then 
    zf = zf * walkKickHeightFactor;
    if phSingle<0.5 then xf=0;
    end
  end

  return xf, zf;
end


function sensor_torso()

  imuAngle = Body.get_sensor_imuAngle();
  imuRoll = imuAngle[1];
  imuPitch = imuAngle[2];
  imuRoll = 0;

  if supportLeg == 0 then    -- Left support

    pTorsoSensor = Kinematics.torso_lleg(Body.get_lleg_position());
    pLegSensor = Kinematics.lleg_torso(Body.get_lleg_position());

    tTorso = Transform.trans(-footX,0,0);
    tTorso = tTorso * Transform.rotX(imuRoll);
    tTorso = tTorso * Transform.rotY(imuPitch);
    tAnkle = tTorso * Transform. trans(pLegSensor[1],pLegSensor[2],pLegSensor[3]);
    uTorsoLegSensor = tAnkle * vector.new({0,0,0,-1});

    torsoHeightSensor = uTorsoLegSensor[3];
    uTorsoYaw = .5*(uLeft[3] + uRight[3]-qLFootOffset[3]-qRFootOffset[3]);
    uTorsoLegSensor[3] = uLeft[3]-uTorsoYaw;
    uTorsoSensor = util.pose_global(uTorsoLegSensor,uLeft);

  else    -- Right support

    pTorsoSensor = Kinematics.torso_rleg(Body.get_rleg_position());
    pLegSensor = Kinematics.rleg_torso(Body.get_rleg_position());

    tTorso = Transform.trans(-footX,0,0);
    tTorso = tTorso * Transform.rotX(imuRoll);
    tTorso = tTorso * Transform.rotY(imuPitch);
    tAnkle = tTorso * Transform. trans(pLegSensor[1],pLegSensor[2],pLegSensor[3]);
    uTorsoLegSensor = tAnkle * vector.new({0,0,0,-1});

    torsoHeightSensor = uTorsoLegSensor[3];
    uTorsoYaw = .5*(uLeft[3] + uRight[3]-qLFootOffset[3]-qRFootOffset[3]);
    uTorsoLegSensor[3] = uRight[3]-uTorsoYaw;
    uTorsoSensor = util.pose_global(uTorsoLegSensor,uRight);

  end


  --[[
  print("pLegSensor:",pLegSensor[1],pLegSensor[2],pLegSensor[3],
	pLegSensor[4]*180/math.pi, 
	pLegSensor[5]*180/math.pi, 
	pLegSensor[6]*180/math.pi);

  
  print("pTorsoSensor:",pTorsoSensor[1],pTorsoSensor[2],pTorsoSensor[3],
	pTorsoSensor[4]*180/math.pi, 
	pTorsoSensor[5]*180/math.pi, 
	pTorsoSensor[6]*180/math.pi);
  --]]

  tSensorDelay = 0.00;
  uTheoretic = uTorsoShift + zmp_com(ph - tSensorDelay/tStep);
  uError = util.pose_relative(uTorsoSensor , uTheoretic);
--  print("uTorsoLegSensor:",unpack(uTorsoLegSensor))
--  print("torsoHeightSensor:",torsoHeightSensor)

--  print("uError:",uError[1],uError[2]);

  uTorso = zmp_com(ph);

--[[
--Hack
  if uError[1]<-0.02 then
    uTorso = util.pose_global(vector.new({0.02,0,0}),uTorso)
  end
--]]

--Hack
--[[
  uTorso = zmp_com(0);
  hipRollCompensation=0;
  --]]

end




entry();
