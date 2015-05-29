module(..., package.seeall);
require('vector')
require 'unix'
-- Walk Parameters

walk = {};

walk.waist = 38 * math.pi/180;

----------------------------------------------
-- Stance parameters
---------------------------------------------

--walk.bodyTilt = 9*math.pi/180; 
--walk.bodyTilt = 7*math.pi/180;
--walk.bodyTilt = 6*math.pi/180;
--walk.bodyTilt = 5*math.pi/180; 
--walk.bodyTilt = 3*math.pi/180; 
--walk.bodyTilt = 1*math.pi/180;
--walk.bodyTilt = 0*math.pi/180; 

walk.bodyTilt = -45*math.pi/180; 
walk.bodyTilt = -40*math.pi/180; 
walk.bodyTilt = -35*math.pi/180; 
--walk.bodyTilt = -33*math.pi/180; 
--walk.bodyTilt = -32*math.pi/180; 
walk.bodyTilt = -30*math.pi/180; 
walk.bodyTilt = -31*math.pi/180; 

--walk.bodyHeight = .485;
--walk.bodyHeight = .48; -- GOOD
--walk.bodyHeight = .472;
--walk.bodyHeight = .47;
--walk.bodyHeight = .46;
--walk.bodyHeight = .45;
--walk.bodyHeight = .44;

--walk.bodyHeight = .42;
walk.bodyHeight = .44;

--walk.footX = -0.08; -- Falls forwards
--walk.footX = -0.04; -- Falls forwards
--walk.footX = -0.02;
--walk.footX = -0.01;
--walk.footX = -0.005;

--walk.footX = 0.00; -- GOOD
--walk.footX = 0.002;
--walk.footX = 0.01;
--walk.footX = 0.02;

walk.footX = 0.03;

walk.footX = 0.04; -- Falls backwards
--walk.footX = 0.045; -- Falls backwards
--walk.footX = 0.05; -- Falls backwards

--walk.footY = 0.04; -- Tight together
--walk.footY = 0.045; -- Tight together
--walk.footY = 0.05;
walk.footY = 0.06;

--walk.footY = 0.08;
--walk.footY = 0.07;

--walk.supportX = 0.01;  -- Steps forwards more
--walk.supportX = 0.0;  -- Steps forwards more

-- here
--walk.supportX = -0.010;
walk.supportX = -0.008;
walk.supportX = -0.006;

--walk.supportX = -0.015;
--walk.supportX = -0.020;
--walk.supportX = -0.030;
--walk.supportX = -0.050; -- Steps backwards more when stepping in place

--walk.supportY = 0.010; -- MORE SWING side to side
--walk.supportY = 0.005;
--walk.supportY = 0.0;
walk.supportY = -0.01;
--walk.supportY = -0.02; -- Yes
--walk.supportY = -0.03;
--walk.supportY = -0.04; -- LESS swing side to side

walk.qLArm=math.pi/180*vector.new({78, 20, 0.0, -0});
walk.qRArm=math.pi/180*vector.new({78, -20, 0.0, 0});

walk.hardnessSupport = 1;
walk.hardnessSwing = .75;
walk.hardnessSwing = 1;
walk.hardnessArm = 0.2;

---------------------------------------------
-- Gait parameters
---------------------------------------------
--walk.tStep = 1.75;
--walk.tStep = 1.5;
--walk.tStep = 1;
--walk.tStep = .8;
--walk.tStep = 0.75;
--walk.tStep = .65;
--walk.tStep = .6;
--walk.tStep = .5;
--walk.tStep = .45; -- GOOD

--walk.tStep = .42;
--walk.tStep = .4;
--walk.tStep = .35;

walk.tStep = .3;
walk.tStep = .28;
walk.tStep = .35;
walk.tStep = .25;


--walk.tZmp = 0.167; -- TODO: what is this value??
--walk.tZmp = 0.2338; -- multiply old value by 1.4 says SJ
walk.tZmp = 0.24;
--walk.tZmp = 0.28;
--walk.tZmp = 0.32;
--walk.tZmp = 0.34;

--walk.stepHeight = 0;
--walk.stepHeight = 0.02;

walk.stepHeight = 0.03;
walk.stepHeight = 0.025;
walk.stepHeight = 0.02;

--walk.stepHeight = 0.04;

--walk.stepHeight = 0.05;
walk.stepHeight = 0.03;
--walk.stepHeight = 0.04;

--walk.phSingle={0.45,0.55};
--walk.phSingle={0.4,0.6};
--walk.phSingle={0.35,0.65};
--walk.phSingle={0.3,0.7};

--walk.phSingle={0.2,0.8}; -- Best

walk.phSingle={0.15,0.85};
walk.phSingle={0.1,0.9};
walk.phSingle={0.2,0.8};


----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.07,0.20};
walk.stanceLimitA={0*math.pi/180,30*math.pi/180};
walk.velLimitX={-.02,.05};
walk.velLimitY={-.04,.04};
walk.velLimitA={-.6,.6};
walk.velDelta={0.005,0.005,0.2} 

--------------------------------------------
-- Compensation parameters
--------------------------------------------
--walk.hipRollCompensation = 4*math.pi/180;
walk.hipRollCompensation = 0*math.pi/180;

walk.ankleMod = vector.new({-1,0})/0.12 * 10*math.pi/180 * 0;
--walk.toeTipCompensation = -0.1;
walk.toeTipCompensation = 0;
--walk.toeTipCompensation = -5*math.pi/180;
--walk.toeTipCompensation = -3*math.pi/180;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------
gyroFactor = 0;
--gyroFactor = 0.273*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = 0.18*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = 0.1*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = -0.13*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = -0.15*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = -0.2*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = 0.16*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = 0.14*math.pi/180 * 300 / 1024; --dps to rad/s conversion

--gyroFactor = 0.12*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = 0.115*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = 0.1*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = 0.08*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = 0.05*math.pi/180 * 300 / 1024; --dps to rad/s conversion
--gyroFactor = -0.05*math.pi/180 * 300 / 1024; --dps to rad/s conversion
gyroFactor = -0.1*math.pi/180 * 300 / 1024; --dps to rad/s conversion

walk.ankleImuParamX={0.9,-0.3*gyroFactor, 0, 25*math.pi/180};
walk.kneeImuParamX={0.9,-1.2*gyroFactor, 0, 25*math.pi/180};
walk.ankleImuParamY={0.9,-0.7*gyroFactor, 0, 25*math.pi/180};
walk.hipImuParamY={0.9,-0.3*gyroFactor, 0, 25*math.pi/180};
walk.armImuParamX={0.3,-30*gyroFactor, 20*math.pi/180, 45*math.pi/180};
walk.armImuParamY={0.3,-30*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--------------------------------------------
-- Support point modulation values
--------------------------------------------
walk.velFastForward = 0.04;
walk.supportFront = 0.03; --Lean front when walking fast forward
walk.supportFront2 = 0.03; --Lean front when walking fast forward
walk.supportBack = -0.05; --Lean back when walking backward
walk.supportSide = 0.01; --Lean sideways when sidestepping

--------------------------------------------
-- WalkKick parameters
--------------------------------------------
walk.walkKickDef={}

--tStep stepType supportLeg stepHeight
-- SupportMod shiftFactor footPos1 footPos2

walk.walkKickDef["FrontLeft"]={
  {0.30, 1, 0, 0.05 , {0,0}, 0.7, {0.06,0,0} },
  {0.30, 2, 1, 0.1 , {0.02,-0.02}, 0.5, {0.09,0,0}, {0.06,0,0} },
  {walk.tStep, 1, 0, 0.035 , {0,0}, 0.5, {0.04,0,0} },
}

walk.walkKickDef["FrontLeft"]={
  {0.30, 1, 0, 0.05 , {0,0}, 0.7, {0.02,0,0} },
  {0.30, 2, 1, 0.1 , {0.02,-0.02}, 0.5, {0.04,0,0}, {0.02,0,0} },
  {walk.tStep, 1, 0, 0.035 , {0,0}, 0.5, {0,0,0} },
}

walk.walkKickDef["FrontRight"]={
  {0.30, 1, 1, 0.05 , {0,0}, 0.3, {0.06,0,0} },
  {0.30, 2, 0, 0.1 , {0.02,0.02}, 0.5,  {0.09,0,0}, {0.06,0,0} },
  {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0.04,0,0} },
}

walk.walkKickDef["SideLeft"]={
  {0.30, 1, 1, 0.035 , {0,0}, 0.4, {0.04,0.04,0} },
  {0.35, 3, 0, 0.07 , {-0.01,0.01}, 0.5, {0.06,-0.05,0},{0.09,0.0,0}},
  {0.25, 1, 1, 0.035 , {0,0}, 0.5, {0,0,0} },
}

walk.walkKickDef["SideRight"]={
  {0.30, 1, 0, 0.035 , {0,0}, 0.6, {0.04,-0.04,0} },
  {0.35, 3, 1, 0.07 , {-0.01,-0.01},0.5, {0.06,0.05,0},{0.09,-0.0,0}},
  {0.25, 1, 0, 0.035 , {0,0},0.5,  {0,0,0} },
}

walk.walkKickPh=0.5;
--Fall detection angle... OP requires large angle
walk.fallAngle = 50*math.pi/180;

--------------------------------------------
-- Robot - specific calibration parameters
--------------------------------------------

walk.kickXComp = 0;
walk.supportCompL = {0,0,0};
walk.supportCompR = {0,0,0};
walk.servoBias={0,0,0,0,0,0,   0,0,0,0,0,0};

walk.footXComp = 0;
walk.footYComp = 0;
walk.headPitch = 0 * math.pi / 180; --Pitch angle offset of OP 
walk.headPitchComp = 0;

local robotName = unix.gethostname();
local robotID = 23;

--Load robot specific calibration value
require('calibration');
if calibration.cal and calibration.cal[robotName] then
  walk.servoBias = calibration.cal[robotName].servoBias;
print("Servo Bias: ",unpack(walk.servoBias))
  walk.footXComp = calibration.cal[robotName].footXComp;
  walk.kickXComp = calibration.cal[robotName].kickXComp;
  walk.kickYComp = calibration.cal[robotName].kickYComp;
  walk.headPitchBiasComp = calibration.cal[robotName].headPitchBiasComp;
  print(robotName.." walk parameters loaded")
end
unix.usleep(1e6);

--Apply robot specific compensation to default values
walk.footX = walk.footX + walk.footXComp;
walk.footY = walk.footY + walk.footYComp;
walk.headPitch = walk.headPitch + walk.headPitchComp;

