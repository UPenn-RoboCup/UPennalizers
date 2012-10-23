module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters for NewWalk

walk = {};

----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.09,0.20};
walk.stanceLimitA={-0*math.pi/180,40*math.pi/180};

walk.velLimitX={-.06,.06};
walk.velLimitY={-.045,.045};
walk.velLimitA={-.3,.3};
walk.velDelta={0.03,0.015,0.15} 

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.31; 
walk.bodyTilt=0*math.pi/180; 
walk.footX= 0.0; 
walk.footY = 0.0475;
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
walk.tStep = 0.36;
walk.tZmp = 0.17;
walk.supportY = 0.003;
walk.stepHeight = 0.018;
walk.phSingle={0.16,0.84};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation = 0*math.pi/180;
walk.ankleMod = vector.new({-1,0})/0.12 * 10*math.pi/180;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------
walk.gyroFactor = 0.001;

walk.ankleImuParamX={0.15, -0.40*walk.gyroFactor,1*math.pi/180, 5*math.pi/180};
walk.kneeImuParamX={0.1, -0.3*walk.gyroFactor, .5*math.pi/180, 5*math.pi/180};
walk.ankleImuParamY={0.2, -0.7*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180};
walk.hipImuParamY={0.1, -0.3*walk.gyroFactor, .5*math.pi/180, 5*math.pi/180};
walk.armImuParamX={0.1, 0*walk.gyroFactor, 1*math.pi/180, 5*math.pi/180};
walk.armImuParamY={0.1, 0*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180};

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
walk.walkKickVel = {0.03, 0.08} --step / kick / follow 
walk.walkKickSupportMod = {{-0.03,0},{-0.03,0}}
walk.walkKickHeightFactor = 3.0;

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



--FOR NEW NAO

walk.tStep = 0.35;
walk.hipRollCompensation = 1.5*math.pi/180;
walk.supportY = 0.010;

walk.velLimitX={-.06,.08};
walk.velLimitY={-.04,.04};
walk.velLimitA={-.4,.4};
walk.velDelta={0.03,0.015,0.15}





--FOR SLOW and STABLE walk
walk.tStep = 0.48;
walk.hipRollCompensation = 3*math.pi/180;
walk.phSingle={0.2,0.8};
walk.supportY= 0.005;
walk.velLimitY={-.03,.03};

