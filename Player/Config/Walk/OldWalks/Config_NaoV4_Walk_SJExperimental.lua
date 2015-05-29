module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters for NewWalk

RAD = math.pi/180;

walk = {};

walk.testing = true;
----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.09,0.20};
walk.stanceLimitA={-0*math.pi/180,40*math.pi/180};

--Max forwards/backwards speed
walk.velLimitX={-.05,.08};
--Max left/right speed
walk.velLimitY={-.03,.03};
--Max angular rotation speed
walk.velLimitA={-.4,.4};
walk.velDelta={0.02,0.02,0.15} 

---------------------------------------------
-- Odometry values
--------------------------------------------
walk.odomScale = {1.09, .92, .84}; --1.06, 1.20, .95  

----------------------------------------------
-- Stance parameters
---------------------------------------------
--Stand up taller; height given in meters
walk.bodyHeight = 0.315; 
walk.bodyTilt=0*math.pi/180; 
walk.footX= 0.0; 
--Width of the stance; meters
walk.footY = 0.0500; --Old 0.0450 
--How far behind the torso the ankle joints are positioned
walk.supportX = 0.023; 
walk.qLArm = math.pi/180*vector.new({105, 12, -85, -30});
walk.qRArm = math.pi/180*vector.new({105, -12, 85, 30});
walk.qLArmKick = math.pi/180*vector.new({105, 18, -85, -30});
walk.qRArmKick = math.pi/180*vector.new({105, -18, 85, 30});

walk.hardnessSupport = .7;
walk.hardnessSwing = .5;
walk.hardnessArm=.3;
---------------------------------------------
-- Gait parameters
---------------------------------------------
--Time between steps.
walk.tStep = 0.29; 
--Natural frequency of the inverted pendulum, determined experimentally (based on sqrt(g/L)
walk.tZmp = 0.17; 
--How far from the center of the foot the center of mass is positioned during step
walk.supportY = -0.005; 
--Larger height, higher step; height given in meters
walk.stepHeight = 0.017; 
walk.phSingle={0.02,0.98};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
--Moves the torso back to vertical as the robot walks.
walk.hipRollCompensation = 1.5*math.pi/180;
--walk.ankleMod = vector.new({-1,0})/0.12 * 3*math.pi/180;
walk.ankleMod = vector.new({0,0})/0.12 * 3*math.pi/180;

walk.spreadComp = 0.015;




--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------

--ALPHA alters how quickly the torque is applied in response to perturbation
--GAIN alters how much toque is applied in response to perturbation
--DEADBAND defines the range of values that will not be considered as perturbation

--Gyro claibration constant
walk.gyroFactor = 0.001;

--walk.ankleImuParamX={0.11, -0.50*walk.gyroFactor, 1*RAD, 5*RAD};
--walk.kneeImuParamX={0.1, -0.3*walk.gyroFactor,  .5*RAD, 5*RAD};
walk.ankleImuParamX={0.11, -0.50*walk.gyroFactor, 2*RAD, 5*RAD};
walk.kneeImuParamX={0.1, -0.3*walk.gyroFactor,  2*RAD, 5*RAD};

walk.ankleImuParamY={0.22, -1.9*walk.gyroFactor,.5*RAD, 5*RAD};
walk.hipImuParamY={0.1, -0.3*walk.gyroFactor, .5*RAD, 5*RAD};

walk.armImuParamX={0.1, 0*walk.gyroFactor, 1*RAD, 5*RAD};
walk.armImuParamY={0.1, 0*walk.gyroFactor,.5*RAD, 5*RAD};



--------------------------------------------
-- Support point modulation values
--------------------------------------------

walk.velFastForward = 0.05;
walk.velFastTurn = 0.15;

walk.supportFront = -0.01; --Lean back when walking fast forward
walk.supportFront2 = 0.01; --Lean front when accelerating forward

walk.supportFront = 0; --Lean back when walking fast forward
walk.supportFront2 = 0.01; --Lean front when accelerating forward


walk.supportBack = -0.0; --Lean back when walking backward
--walk.supportSideX = -0.01; --Lean back when sidestepping
walk.supportSideX = -0.005; --Lean back when sidestepping
walk.supportSideY = 0.02; --Lean sideways when sidestepping


walk.supportSideY = 0.03; --Lean sideways when sidestepping



walk.supportTurn = 0.02; --Lean front when turning
walk.turnCompThreshold = 0.1;
walk.turnComp = 0.003; --Lean front when turning



--------------------------------------------
-- WalkKick parameters
--------------------------------------------
walk.walkKickDef={}

--tStep stepType supportLeg stepHeight SupportMod shiftFactor footPos1 footPos2

walk.walkKickDef["FrontLeft"]={
  {0.35, 1, 0, 0.020 , {0,-0.02}, 0.7, {0.06,0,0} },
  {0.55, 2, 1, 0.060 , {0.02,-0.02}, 0.5, {0.12,0,0}, {0.06,0,0} },
  {0.40, 1, 0, 0.020 , {0.01,0}, 0.5, {0.03,0,0} },
}
walk.walkKickDef["FrontRight"]={
  {0.35, 1, 1, 0.020 , {0,0.02}, 0.3, {0.06,0,0} },
  {0.55, 2, 0, 0.060 , {0.02,0.02}, 0.5,  {0.12,0,0}, {0.06,0,0} },
  {0.40, 1, 1, 0.020 , {0.01,0}, 0.5, {0.03,0,0} },
}

walk.walkKickDef["SideLeft"]={
  {0.30, 1, 1, 0.020 , {0,0.02}, 0.3, {0.04,0.04,0} },
  {0.35, 3, 0, 0.040 , {-0.00,0.01}, 0.5, {0.06,-0.05,0},{0.09,0.0,0}},
 {walk.tStep, 1, 1, 0.020 , {0,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.30, 1, 0, 0.020 , {0,-0.02}, 0.7, {0.04,-0.04,0} },
  {0.35, 3, 1, 0.040 , {-0.00,-0.01},0.5, {0.06,0.05,0},{0.09,-0.0,0}},
  {walk.tStep, 1, 0, 0.020 , {0,0},0.5,  {0,0,0} },
}

walk.walkKickPh1=0.2; --wait a bit
walk.walkKickPh2=0.6; --kick and wait
walk.walkKickPh3=0.9; --return back



walk.walkKickVel = {0.03, 0.04} --step / kick / follow 
walk.walkKickSupportMod = {{-0.03,0},{-0.03,0}}
walk.walkKickHeightFactor = 1.5;
--walk.tStepWalkKick = 0.35;  --Leave as default for now

walk.sideKickVel1 = {0.04,0.04,0};
walk.sideKickVel2 = {0.09,0.05,0};
walk.sideKickVel3 = {0.09,-0.02,0};
walk.sideKickSupportMod = {{0,0},{0,0}};
walk.tStepSideKick = 0.70;


--------------------------------------------
-- Robot - specific calibration parameters
--------------------------------------------

walk.kickXComp = 0;
walk.supportCompL = {0,0,0};
walk.supportCompR = {0,0,0};

--Shift torso a bit to front when kicking
walk.kickXComp = -0.01;

walk.ankleCompL = 0;
walk.ankleCompR = 0;


walk.supportY = 0.005; 
