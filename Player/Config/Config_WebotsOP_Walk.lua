module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters

walk = {};

----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.16,0.16};
walk.stanceLimitY={0.07,0.20};
walk.stanceLimitA={-10*math.pi/180,30*math.pi/180};
walk.velLimitX={-.04,.08};
walk.velLimitY={-.03,.03};
walk.velLimitA={-.3,.3};
walk.velDelta={0.02,0.02,0.15} 

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.295; 
walk.bodyTilt=20*math.pi/180; 
walk.footX= -0.0; 
walk.footY = 0.0375;
walk.supportX = 0;
walk.supportY = 0.025;
walk.qLArm=math.pi/180*vector.new({90,8,-40});
walk.qRArm=math.pi/180*vector.new({90,-8,-40});

walk.hardnessSupport = 1;
walk.hardnessSwing = 1;
walk.hardnessArm=.3;
---------------------------------------------
-- Gait parameters
---------------------------------------------
walk.tStep = 0.50;
walk.tZmp = 0.165;
walk.stepHeight = 0.025;
walk.phSingle={0.2,0.8};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation = 3*math.pi/180;
walk.ankleMod = vector.new({-1,0})/0.12 * 10*math.pi/180;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------
gyroFactor = 0.273*math.pi/180 * 300 / 1024; --dps to rad/s conversion

--Disabled for webots
--gyroFactor = 0;

walk.ankleImuParamX={1,-0.75*gyroFactor, 2*math.pi/180, 10*math.pi/180};
walk.kneeImuParamX={1,-1.5*gyroFactor, 2*math.pi/180, 10*math.pi/180};
walk.ankleImuParamY={1,-1*gyroFactor, 2*math.pi/180, 10*math.pi/180};
walk.hipImuParamY={1,-1*gyroFactor, 2*math.pi/180, 10*math.pi/180};
walk.armImuParamX={0.3,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
walk.armImuParamY={0.3,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--------------------------------------------
-- WalkKick parameters
--------------------------------------------
walk.walkKickVel = {0.06, 0.14} --step / kick / follow 
walk.walkKickSupportMod = {{0,0},{0,0}}
walk.walkKickHeightFactor = 1.5;

walk.walkKickHeightFactor = 2.5;

--------------------------------------------
-- Robot - specific calibration parameters
--------------------------------------------

walk.kickXComp = 0;
walk.supportCompL = {0,0,0};
walk.supportCompR = {0,0,0};

