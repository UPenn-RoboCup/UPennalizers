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

walk.velLimitX={-.06,.06};
walk.velLimitY={-.05,.05};
walk.velLimitA={-.4,.4};
walk.velDelta={0.15,0.01,0.15} 

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.325; 
walk.bodyTilt=0*math.pi/180; 
walk.footX= 0.0; 
walk.footY = 0.0500;
walk.supportX = 0.020;
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
walk.tStep = 0.30;
walk.tZmp = 0.17;
walk.supportY = -0.003;
walk.stepHeight = 0.014;
walk.phSingle={0.22,0.80};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation = 1.5*math.pi/180;
walk.ankleMod = vector.new({-1,0})/0.12 * 10*math.pi/180;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------
walk.gyroFactor = 0.001;

walk.ankleImuParamX={0.15, -0.40*walk.gyroFactor,
        1*math.pi/180, 5*math.pi/180};
walk.kneeImuParamX={0.1, -0.3*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};
walk.ankleImuParamY={0.18, -1.8*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};
walk.hipImuParamY={0.13, -0.6*walk.gyroFactor,
        .3*math.pi/180, 5*math.pi/180};

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

--tStep stepType supportLeg stepHeight
-- SupportMod shiftFactor footPos1 footPos2

walk.walkKickDef["FrontLeft"]={
  {0.50, 1, 0, 0.020 , {0,0}, 0.7, {0.06,0,0} },
  {0.50, 2, 1, 0.040 , {0.02,-0.01}, 0.5, {0.09,0,0}, {0.05,0,0} },
  {walk.tStep, 1, 0, 0.020 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["FrontRight"]={
  {0.50, 1, 1, 0.020 , {0,0}, 0.3, {0.06,0,0} },
  {0.50, 2, 0, 0.040 , {0.02,0.01}, 0.5,  {0.09,0,0}, {0.05,0,0} },
  {walk.tStep, 1, 1, 0.020 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["SideLeft"]={
  {0.50, 1, 1, 0.020 , {0,0}, 0.3, {0.04,0.04,0} },
  {0.50, 3, 0, 0.040 , {-0.01,0.01}, 0.5, {0.06,-0.05,0},{0.09,0.0,0}},
 {walk.tStep, 1, 1, 0.020 , {0,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.50, 1, 0, 0.020 , {0,0}, 0.7, {0.04,-0.04,0} },
  {0.50, 3, 1, 0.040 , {-0.01,-0.01},0.5, {0.06,0.05,0},{0.09,-0.0,0}},
  {walk.tStep, 1, 0, 0.020 , {0,0},0.5,  {0,0,0} },
}

walk.walkKickPh=0.5;

--------------------------------------------
-- Robot - specific calibration parameters
--------------------------------------------

walk.kickXComp = 0;
walk.supportCompL = {0,0,0};
walk.supportCompR = {0,0,0};
