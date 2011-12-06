module(..., package.seeall);
require('vector')
require 'unix'

-- Walk Parameters

walk = {};

--walk.tStep = 0.40;
walk.tStep = 0.44;

--natural frequency of the inverted pendulum, determined experimentally (based on sqrt(g/l)
walk.tZmp = 0.17;

--Larger height makes the bot stand up taller (in m)
walk.bodyHeight = 0.30;

--Larger height makes the step higher from the ground (in m)
--walk.stepHeight = 0.016;
walk.stepHeight = 0.020;


--Width of the stance
walk.footY = 0.0475;

--How far behind the torso the ankle joints are positioned
walk.supportX = 0.016;

--How far from the center of the foot the center of mass is positioned during step
walk.supportY = 0.025;

--Moves the torso back to the vertical position
walk.hipRollCompensation = 0*math.pi/180;
walk.hipPitchCompensation = 0;
walk.anklePitchCompensation = -0*math.pi/180;
walk.anklePitchComp= {0,0};


--SJ: for generic mini-hubo model
--------------------------------------------
walk.hipRollCompensation = 5*math.pi/180;
walk.supportX = -0.02;
walk.footY=0.04;
walk.tStep = 0.50;
walk.supportY = 0.035;
--------------------------------------------

--Torso feedback
walk.tSensorDelay = 0.035;
walk.torsoSensorGainX=0.0;
walk.torsoSensorGainY=0.01;

--Single support phase ratio
walk.phSingle = {0.16,0.84};

--Max Step in x, y, z--
walk.maxX = {-.06, .06};
walk.maxY = {-.045, .045};
walk.maxZ = {-.3, .3};

walk.fsr_threshold = 0.3;
walk.tDelayBalance = .6;

--Gyro stabilization parameters

--Put zero gyro values here
walk.gyro0={-1944,-1694};

--Gyro calibration constant
walk.gyroFactor = 0.0;  --For degree per second unit

walk.ankleImuParamX={0.15, -0.40*walk.gyroFactor, 
	1*math.pi/180, 5*math.pi/180};
walk.kneeImuParamX={0.1, -0.3*walk.gyroFactor, 
	.5*math.pi/180, 5*math.pi/180};
walk.ankleImuParamY={0.2, -2.7*walk.gyroFactor, 
	.5*math.pi/180, 5*math.pi/180};
walk.hipImuParamY={0.1, -0.3*walk.gyroFactor, 
	.5*math.pi/180, 5*math.pi/180};

--Amount of time to walk in place after standing/kicking--
walk.delay = 2;

walk.imuOn = true;
walk.fsrOn = true;
walk.jointFeedbackOn = false;

-- Added for kinematic support across robots
walk.qLArm = math.pi/180*vector.new({105, 12, -85, -30});
walk.qRArm = math.pi/180*vector.new({105, -12, 85, 30});	

-----------------------------------------------------
--These parameters are only used in new walk engine
----------------------------------------------------

walk.bodyTilt = 0*math.pi/180;
walk.footX = 0;

walk.stanceLimitX = {-0.10, 0.10};
walk.stanceLimitY = {0.07, 0.20};
walk.stanceLimitA = {-20*math.pi/180,30*math.pi/180};
walk.velLimitX = {-.06, .08};
walk.velLimitY = {-.045, .045};
walk.velLimitA = {-.4, .4};

--Max acceleration per step
walk.velDelta={0.06,0.06,0.6} 

--Arm and leg hardness during walking
walk.hardnessArm = vector.new({.3,.3,.1});
walk.hardnessLeg = vector.new({1,1,1,1,1,1});

walk.torsoImuParamX = {-0, 0.01, 0.04};
walk.torsoImuParamY = {-0, 0.01, 0.04};

--Arm stabilization gains
walk.armImuParamX = {0,-2*walk.gyroFactor, 5*math.pi/180, 45*math.pi/180};
walk.armImuParamY = {0,-2*walk.gyroFactor, 5*math.pi/180, 20*math.pi/180};

--Support point modulation parameters
walk.supportXfactor0 = 0;
walk.supportXfactor1 = 0; --support shift factor during walking backwards
walk.supportXfactor2 = 0; --base support X shift during walking backwards
walk.supportXfactor3 = 0; --support X shift during sidestepping
walk.supportYfactor1 = 0; --support Y shift during sidestepping
walk.headPitchFactor=0; --support X shift according to head angle

--Flex compensation Parameters
walk.hipRollCompensation = 3*math.pi/180;
walk.hipPitchCompensation = -0*math.pi/180;
walk.kneePitchCompensation = 0*math.pi/180;
walk.anklePitchCompensation = 0*math.pi/180;
walk.anklePitchComp= {0,0};
walk.ankleFactor=0;

--Ankle pitch modulation parameters during walking
walk.ankleMod=vector.new({0,0})/0.12 * 10*math.pi/180; 
walk.ankleMod2= 0;
walk.hipPitchCompensation2 = 0;

--Torso vertical movement parameters
walk.phBodyZ={0.3,0.7}
walk.bodyModZ={0,0,0}-- zero movement

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
