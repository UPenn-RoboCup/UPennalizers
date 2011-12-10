module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters

walk = {};

walk.qLArm=math.pi/180*vector.new({90,8,-40});
walk.qRArm=math.pi/180*vector.new({90,-8,-40});

walk.hardnessArm=vector.new({.4,.2,.2});
walk.hardnessLeg=vector.new({1,1,1,1,1,1});

-- Stance and velocity limit values
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.07,0.20};
walk.stanceLimitA={-10*math.pi/180,30*math.pi/180};
walk.velLimitX={-.04,.07};
walk.velLimitY={-.03,.03};
walk.velLimitA={-.3,.3};
walk.rotlimit1=1.5;
walk.rotlimit2=1;
walk.velocityModX=0;

--Max acceleration per step
walk.velDelta={0.02,0.02,0.15} 

-------------------------
--Stance parameters
-------------------------

walk.bodyHeight = 0.295; --Using new corrected IK
walk.footX= -0.020; 
walk.footY = 0.0375;
walk.bodyTilt=20*math.pi/180; --Commanded tilt angle
walk.bodyTiltActual=20*math.pi/180;--Actual body tilt angle considering flex

--------------------------------------------
--Default Gait parameters
---------------------------------------------
walk.tStep = 0.40;
walk.tZmp = 0.165;
walk.stepHeight = 0.045;
walk.phSingle={0.2,0.8};

--Support movement parameters
walk.supportX=0;
walk.supportY = 0.025;

--SJ: Parameters used in HMC challenge (slow but alot more stable)
-----------------------------------------------
walk.tStep = 0.50;
walk.supportY = 0.030;
walk.qLArm=math.pi/180*vector.new({90,5,-40});
walk.qRArm=math.pi/180*vector.new({90,-5,-40});
walk.velLimitX={-.06,.10};
walk.velLimitY={-.04,.04};
------------------------------------------------


walk.supportY = 0.020;



walk.supportXfactor0 = 0;
walk.supportXfactor1 = 0; --support shift factor during walking backwards
walk.supportXfactor2 = 0; --base support X shift during walking backwards
walk.supportXfactor3 = 0; --support X shift during sidestepping
walk.supportYfactor1 = 0; --support Y shift during sidestepping
walk.headPitchFactor=0; --support X shift according to head angle

-----------------------
--SJ: For NSLWalk in webots
walk.footX= -0.017; 
walk.supportXfactor0 = -0.02; --support X shift for fast walking forward
-----------------------

------------------------------------------
--SJ: for EKwalk
--[[
walk.supportX=0.00;
walk.tZmp = 0.160;
walk.supportY = 0.020;
walk.footY = 0.04;
walk.bodyTilt=15*math.pi/180; --Commanded tilt angle
walk.bodyHeight = 0.31; --For Kick
walk.velLimitX={-.06,.12};
walk.stanceLimitX={-0.16,0.16};
--]]
-------------------------------------------



--Flex compensation Parameters
walk.hipRollCompensation = 3*math.pi/180;
walk.hipPitchCompensation = -0*math.pi/180;
walk.kneePitchCompensation = 0*math.pi/180;
walk.anklePitchCompensation = 0*math.pi/180;
walk.anklePitchComp= {0,0};
walk.ankleFactor=0;

--walk.hipPitchCompensation2 = -4*math.pi/180; --Hip pitch modulation for walk backwards
--walk.ankleMod=vector.new({-1,0.5})/0.12 * 10*math.pi/180; --Ankle pitch modulation for walking
--walk.ankleMod2= -1/0.12 * 15*math.pi/180; --Ankle pitch 

walk.ankleMod=vector.new({0,0})/0.12 * 10*math.pi/180; --Ankle pitch modulation for walking backwards
walk.ankleMod2= 0;
walk.hipPitchCompensation2 = 0;

--Torso vertical movement (like robotis walk)
walk.phBodyZ={0.3,0.7}
walk.bodyModZ={0,0,0}-- zero movement

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

--Imu feedback parameters, alpha / gain / deadband / max

----------------------------------------------------------------
--Robot-specific fine tuning parameters 
---------------------------------------------------------------
walk.supportCompL=vector.new({0,0,0}); 
walk.supportCompR=vector.new({0,0,0}); 
walk.footXComp = 0.0; 
walk.footYComp = 0.0; 
walk.supportYComp = 0.0;
walk.kickXComp=0;		--X compensation for stationary kick
walk.walkKickFrontComp=0;	--X compensation for walkkick
walk.walkKickSideComp={0,0};	--XY compensation for walk sidekick

walk.cameraAngle={{0,40*math.pi/180,0}}; --Moved to here

--Encoder feedback parameters, alpha/gain
walk.tSensorDelay = 0.10;
walk.torsoSensorParamX={1-math.exp(-.010/0.2), 0} 
walk.torsoSensorParamY={1-math.exp(-.010/0.2), 0}

