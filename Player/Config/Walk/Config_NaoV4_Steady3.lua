module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters for NewWalk

walk = {};

walk.testing = true;
----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.09,0.20};
walk.stanceLimitA={-0*math.pi/180,40*math.pi/180};

walk.velLimitX={-.06,.07};
walk.velLimitY={-.03,.03};
walk.velLimitA={-.4,.4};
walk.velDelta={0.15,0.01,0.15} 

---------------------------------------------
-- Odometry values
--------------------------------------------
walk.odomScale = {.98, .92, .74}; --1.06, 1.20, .95  

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.310; 
walk.bodyTilt=0*math.pi/180; 
walk.footX= 0.0; 
walk.footY = 0.0550;
walk.supportX = 0.018;
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
walk.tStep = 0.43;
walk.tZmp = 0.17;
walk.supportY = 0.002;
walk.stepHeight = 0.020;
walk.phSingle={0.18,0.82};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation = 1.5*math.pi/180;
walk.ankleMod = vector.new({-1,0})/0.12 * 10*math.pi/180;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------
walk.gyroFactor = 0.001;

walk.ankleImuParamX={0.11, -0.50*walk.gyroFactor,
        1*math.pi/180, 5*math.pi/180};
walk.kneeImuParamX={0.11, -0.5*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};
walk.ankleImuParamY={0.32, -2.65*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};
walk.hipImuParamY={0.1, -0.3*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};

walk.armImuParamX={0.1, 0*walk.gyroFactor,
        1*math.pi/180, 5*math.pi/180};
walk.armImuParamY={0.1, 0*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};

--------------------------------------------
-- Support point modulation values
--------------------------------------------
walk.supportFront = 0.01; --Lean front when walking fast forward
walk.supportBack = -0.02; --Lean back when walking backward
walk.supportSideX = -0.01; --Lean back when sidestepping
walk.supportSideY = 0.02; --Lean sideways when sidestepping

--------------------------------------------
-- WalkKick parameters
--------------------------------------------
walk.walkKickDef={}

--tStep stepType supportLeg stepHeight SupportMod shiftFactor footPos1 footPos2

walk.walkKickDef["FrontLeft"]={
  {0.30, 1, 0, 0.020 , {0,0}, 0.7, {0.06,0,0} },
  {0.35, 1, 1, 0.040 , {0.0,-0.01}, 0.5, {0.12,0,0}, {0.07,0,0} },
  {walk.tStep, 1, 0, 0.020 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["FrontRight"]={
  {0.30, 1, 1, 0.020 , {0,0}, 0.3, {0.06,0,0} },
  {0.35, 1, 0, 0.040 , {0.0,0.01}, 0.5,  {0.12,0,0}, {0.07,0,0} },
  {walk.tStep, 1, 1, 0.020 , {0,0}, 0.5, {0,0,0} },
}

walk.walkKickDef["SideLeft"]={
  {0.30, 1, 1, 0.020 , {0,0}, 0.4, {0.04,0.04,0} },
  {0.35, 3, 0, 0.040 , {-0.00,0.01}, 0.5, {0.06,-0.05,0},{0.09,0.01,0}},
 {walk.tStep, 1, 1, 0.020 , {0,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.30, 1, 0, 0.020 , {0,0}, 0.6, {0.04,-0.04,0} },
  {0.35, 3, 1, 0.040 , {-0.00,-0.01},0.5, {0.06,0.05,0},{0.09,-0.01,0}},
  {walk.tStep, 1, 0, 0.020 , {0,0},0.5,  {0,0,0} },
}

walk.walkKickPh=0.5;


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
