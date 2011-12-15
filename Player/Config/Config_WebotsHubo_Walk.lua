module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters

walk = {};

----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.60,0.60};
walk.stanceLimitY={0.16,0.60};
walk.stanceLimitA={-10*math.pi/180,30*math.pi/180};
walk.velLimitX={-.20,.40};
walk.velLimitY={-.15,.15};
walk.velLimitA={-.3,.3};
walk.velDelta={0.10,0.10,0.15} 

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.90; 
walk.bodyTilt=10*math.pi/180; 
walk.footX= 0.01; 
walk.footY = 0.10;
walk.supportX = 0;
walk.supportY = 0.0;
walk.qLArm = math.pi/180*vector.new({110, 12, -0, -40});
walk.qRArm = math.pi/180*vector.new({110, -12, 0, 40});
walk.hardnessSupport = .7;
walk.hardnessSwing = 0.5;
walk.hardnessArm=.3;
---------------------------------------------
-- Gait parameters
---------------------------------------------
walk.tStep = 1.0;
walk.tZmp = 0.25;
walk.stepHeight = 0.13;
walk.phSingle={0.1,0.9};
walk.phZmp={0.1,0.9};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation = 0*math.pi/180;
walk.ankleMod = vector.new({-1,0})/0.12 * 10*math.pi/180;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------
gyroFactor = 0.273*math.pi/180 * 300 / 1024; --dps to rad/s conversion
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

--------------------------------------------
-- Robot - specific calibration parameters
--------------------------------------------

walk.kickXComp = 0;
walk.supportCompL = {0,0,0};
walk.supportCompR = {0,0,0};

--[[
walk.tStep = 0.8;
walk.tZmp = 0.25;
walk.supportY = -0.03;
walk.footY = 0.09;
walk.stepHeight = 0.13;
walk.hardnessSupport = .7;
walk.hardnessSwing = 0.2;
--]]




walk.velLimitA={-.6,.6};
walk.stanceLimitA={-10*math.pi/180,45*math.pi/180};
walk.hipRollCompensation = 1*math.pi/180;

--walk.phZmp={0.05,0.95};

--Fast walking test
gyroFactor = gyroFactor * 0.5;
walk.tStep = 0.7;
walk.velLimitY={-.10,.10};
walk.supportY = -0.01;
walk.tZmp = 0.20;
walk.supportX = -0.01;
