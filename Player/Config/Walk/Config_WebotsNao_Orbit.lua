module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters for NewWalk

walk = {};

----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.09,0.20};
walk.stanceLimitA={0*math.pi/180,40*math.pi/180};
walk.velLimitX={-.06,.07};
walk.velLimitY={-.035,.035};
walk.velLimitA={-.4,.4};
walk.velDelta={0.03,0.015,0.15} 

walk.footSizeX = {-0.04, 0.08};
walk.stanceLimitMarginY = 0.015;

--Now enable pigeon foot 
walk.stanceLimitA={-20*math.pi/180,40*math.pi/180};

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.30; 
walk.bodyTilt=0*math.pi/180; 
walk.footX= 0.0; 
walk.footY = 0.0475;
walk.supportX = 0.016;
walk.supportY = 0.025;
walk.qLArm = math.pi/180*vector.new({105, 12, -85, -30});
walk.qRArm = math.pi/180*vector.new({105, -12, 85, 30});
walk.qLArmKick = math.pi/180*vector.new({105, 12, -85, -30});
walk.qRArmKick = math.pi/180*vector.new({105, -12, 85, 30});

walk.hardnessSupport = .7;
walk.hardnessSwing = .5;
walk.hardnessArm=.3;

---------------------------------------------
-- Gait parameters
---------------------------------------------
walk.tStep = 0.50;
walk.tZmp = 0.17;
walk.stepHeight = 0.018;
walk.phSingle={0.4,0.96};

---------------------------------------------
-- Odometry values
--------------------------------------------
walk.odomScale = {.95, 1.0, .75}; --1.06, 1.20, .95  

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation = 3*math.pi/180;
walk.ankleMod = vector.new({-1,0})*3*math.pi/180;


--------------------------------------------
--Webots FIX
--walk.tStep = 0.48;
walk.supportX = 0.010;
walk.supportY = 0.035;
--walk.phSingle={0.2,0.8};
walk.velLimitY={-.05,.05};
-------------------------------------------

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
walk.walkKickDef={}

--tStep stepType supportLeg stepHeight 
-- SupportMod shiftFactor footPos1 footPos2

walk.walkKickDef["FrontLeft"]={
  {0.60, 1, 0, 0.020 , {0,0}, 0.7, {0.06,0,0} },
  {0.60, 2, 1, 0.040 , {0.02,-0.01}, 0.5, {0.10,0,0}, {0.06,0,0} },
  {walk.tStep, 1, 0, 0.020 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["FrontRight"]={
  {0.60, 1, 1, 0.020 , {0,0}, 0.3, {0.06,0,0} },
  {0.60, 2, 0, 0.040 , {0.02,0.01}, 0.5,  {0.10,0,0}, {0.06,0,0} },
  {walk.tStep, 1, 1, 0.020 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["SideLeft"]={
  {0.60, 1, 1, 0.020 , {0,0}, 0.3, {0.04,0.04,0} },
  {0.60, 3, 0, 0.040 , {-0.01,0.01}, 0.5, {0.06,-0.05,0},{0.09,0.01,0}},
 {walk.tStep, 1, 1, 0.020 , {0,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.60, 1, 0, 0.020 , {0,0}, 0.7, {0.04,-0.04,0} },
  {0.60, 3, 1, 0.040 , {-0.01,-0.01},0.5, {0.06,0.05,0},{0.09,-0.01,0}},
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
