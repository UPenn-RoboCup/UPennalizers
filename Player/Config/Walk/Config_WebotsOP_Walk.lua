module(..., package.seeall); require('vector')
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

walk.velXHigh = 0.10;
walk.velDeltaXHigh = 0.005;

walk.vaFactor = 0.6;


walk.footSizeX = {-0.05, 0.05};
walk.stanceLimitMarginY = 0.015;

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.295; 
walk.bodyTilt=20*math.pi/180; 
walk.footX= -0.0; 
walk.footY = 0.0375;
walk.supportX = 0;
walk.supportY = 0.025;
walk.qLArm=math.pi/180*vector.new({90,2,-40});
walk.qRArm=math.pi/180*vector.new({90,-2,-40});
walk.qLArmKick=math.pi/180*vector.new({90,15,-40});
walk.qRArmKick=math.pi/180*vector.new({90,-15,-40});

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
walk.ankleMod = vector.new({-1,0})*2*math.pi/180;
walk.spreadComp = 0.02;
walk.turnComp = 0.01;
walk.turnCompThreshold = 0.15;


--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------
gyroFactor = 0.273*math.pi/180 * 300 / 1024; --dps to rad/s conversion

--Disabled for webots
--gyroFactor = 0;

walk.ankleImuParamX={1,0.75*gyroFactor, 2*math.pi/180, 10*math.pi/180};
walk.kneeImuParamX={1,1.5*gyroFactor, 2*math.pi/180, 10*math.pi/180};
walk.ankleImuParamY={1,1*gyroFactor, 2*math.pi/180, 10*math.pi/180};
walk.hipImuParamY={1,1*gyroFactor, 2*math.pi/180, 10*math.pi/180};
walk.armImuParamX={0.3,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
walk.armImuParamY={0.3,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--------------------------------------------
-- WalkKick parameters
--------------------------------------------
walk.walkKickDef={}

--tStep stepType supportLeg stepHeight 
-- SupportMod shiftFactor footPos1 footPos2

walk.walkKickDef["FrontLeft"]={
  {0.60, 1, 0, 0.035 , {0,0}, 0.7, {0.06,0,0} },
  {0.60, 2, 1, 0.07 , {0.02,-0.02}, 0.5, {0.09,0,0}, {0.06,0,0} },
  {walk.tStep, 1, 0, 0.035 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["FrontRight"]={
  {0.60, 1, 1, 0.035 , {0,0}, 0.3, {0.06,0,0} },
  {0.60, 2, 0, 0.07 , {0.02,0.02}, 0.5,  {0.09,0,0}, {0.06,0,0} },
  {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["SideLeft"]={
  {0.60, 1, 1, 0.035 , {0,0}, 0.3, {0.04,0.04,0} },
  {0.60, 3, 0, 0.07 , {-0.01,0.01}, 0.5, {0.06,-0.05,0},{0.09,0.01,0}},
 {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.60, 1, 0, 0.035 , {0,0}, 0.7, {0.04,-0.04,0} },
  {0.60, 3, 1, 0.07 , {-0.01,-0.01},0.5, {0.06,0.05,0},{0.09,-0.01,0}},
  {walk.tStep, 1, 0, 0.035 , {0,0},0.5,  {0,0,0} },
}



--Close-range walkkick (step back and then walkkick)
walk.walkKickDef["FrontLeft2"]={
  {0.60, 1, 0, 0.035 , {0,0}, 0.7, {0.06,0,0} },
  {0.60, 2, 1, 0.07 , {0.02,-0.02}, 0.5, {0.09,0,0}, {0.06,0,0} },
  {walk.tStep, 1, 0, 0.035 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["FrontRight2"]={
  {0.60, 1, 1, 0.035 , {0,0}, 0.3, {0.06,0,0} },
  {0.60, 2, 0, 0.07 , {0.02,0.02}, 0.5,  {0.09,0,0}, {0.06,0,0} },
  {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0,0,0} },
}

--New walking sidekick
walk.walkKickDef["SideLeft"]={
  {0.60, 1, 1, 0.035 , {0,0}, 0.3, {0,0.04,10*math.pi/180} },
  {0.60, 3, 0, 0.07 , {-0.01,0.01}, 0.5, {0.06,-0.05,-20*math.pi/180},
	{0.09,0.01,0}},
 {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.60, 1, 0, 0.035 , {0,0}, 0.7, {0,-0.04,-10*math.pi/180} },
  {0.60, 3, 1, 0.07 , {-0.01,-0.01},0.5, 
	{0.06,0.05,20*math.pi/180},{0.09,-0.01,0}},
  {walk.tStep, 1, 0, 0.035 , {0,0},0.5,  {0,0,0} },
}








--Weaker walkkick to test behavior

walk.walkKickDef["FrontLeft"]={
  {0.60, 1, 0, 0.035 , {0,0}, 0.7, {0.05,0,0} },
  {0.60, 2, 1, 0.07 , {0.02,-0.02}, 0.5, {0.05,0,0}, {0.03,0,0} },
  {walk.tStep, 1, 0, 0.035 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["FrontRight"]={
  {0.60, 1, 1, 0.035 , {0,0}, 0.3, {0.05,0,0} },
  {0.60, 2, 0, 0.07 , {0.02,0.02}, 0.5,  {0.05,0,0}, {0.03,0,0} },
  {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0,0,0} },
}

--New walking sidekick
walk.walkKickDef["SideLeft"]={
  {0.60, 1, 1, 0.035 , {0,0}, 0.3, {0,0.04,10*math.pi/180} },
  {0.90, 3, 0, 0.035 , {-0.01,0.01}, 0.5, {0.06,-0.05,-20*math.pi/180},
	{0.09,0.01,0}},
 {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.60, 1, 0, 0.035 , {0,0}, 0.7, {0,-0.04,-10*math.pi/180} },
  {0.90, 3, 1, 0.035 , {-0.01,-0.01},0.5, 
	{0.06,0.05,20*math.pi/180},{0.09,-0.01,0}},
  {walk.tStep, 1, 0, 0.035 , {0,0},0.5,  {0,0,0} },
}




walk.walkKickPh=0.5;

--------------------------------------------
-- Robot - specific calibration parameters
--------------------------------------------

walk.kickXComp = 0;
walk.supportCompL = {0,0,0};
walk.supportCompR = {0,0,0};

walk.footHeight = 0.0355;
walk.legLength = 0.093+0.093;
walk.hipOffsetX = 0.008;
walk.hipOffsetY = 0.037;
walk.hipOffsetZ = 0.096;

--[[
--Faster turning test
walk.stanceLimitA={-20*math.pi/180,45*math.pi/180};
walk.velLimitA={-.6,.6};
--]]


------------------------------------------------
-- Upper body motion keyframes
-----------------------------------------------
-- tDuration qLArm qRArm bodyRot
walk.motionDef={};

walk.motionDef["hurray"]={
 {1.0,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.4,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
	{-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {0.4,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.4,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
	{-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {0.4,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.4,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
	{-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {1.0,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
	{90*math.pi/180, -8*math.pi/180,-40*math.pi/180}}
} 

--pointing up
walk.motionDef["hurray"]={
 {1.0,{-40*math.pi/180, 50*math.pi/180, 0*math.pi/180},
	{160*math.pi/180,-60*math.pi/180,-90*math.pi/180},
	{20*math.pi/180,20*math.pi/180,-20*math.pi/180}},

 {3.0,{-40*math.pi/180, 50*math.pi/180, 0*math.pi/180},
	{160*math.pi/180,-60*math.pi/180,-90*math.pi/180},
	{20*math.pi/180,20*math.pi/180,-20*math.pi/180}},

 {1.0,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
	{90*math.pi/180, -8*math.pi/180,-40*math.pi/180},
	{0,20*math.pi/180,0}}
} 


--Two arm punching up
walk.motionDef["hurray"]={
 {0.5,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},

 {0.2, {40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {0.2,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.2,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.2,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},

 {0.2, {40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {0.2,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.2,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.2,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
	{40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},

 {0.5,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
	{90*math.pi/180, -8*math.pi/180,-40*math.pi/180}}
} 




--Two arm side swing
walk.motionDef["hurray"]={
 {0.5,{90*math.pi/180, 90*math.pi/180, -40*math.pi/180},
	{90*math.pi/180,-90*math.pi/180,-40*math.pi/180},
	{0*math.pi/180,20*math.pi/180,-20*math.pi/180}},

 {0.5,{90*math.pi/180, 90*math.pi/180, -40*math.pi/180},
	{90*math.pi/180,-90*math.pi/180,-40*math.pi/180},
	{0*math.pi/180,20*math.pi/180,20*math.pi/180}},

 {0.5,{90*math.pi/180, 90*math.pi/180, -40*math.pi/180},
	{90*math.pi/180,-90*math.pi/180,-40*math.pi/180},
	{0*math.pi/180,20*math.pi/180,-20*math.pi/180}},

 {0.5,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
	{90*math.pi/180, -8*math.pi/180,-40*math.pi/180},
	{0*math.pi/180,20*math.pi/180,0*math.pi/180}}
} 






--One-Two Punching
walk.motionDef["hurray"]={
 {0.2,{90*math.pi/180, 40*math.pi/180, -160*math.pi/180},
	{90*math.pi/180,-40*math.pi/180,-160*math.pi/180},
	{0*math.pi/180,20*math.pi/180,0*math.pi/180}},

 {0.2,{90*math.pi/180, 30*math.pi/180, -160*math.pi/180},
	{90*math.pi/180,-30*math.pi/180,-160*math.pi/180},
	{0*math.pi/180,20*math.pi/180,20*math.pi/180}},
 {0.2,{90*math.pi/180, 30*math.pi/180, -160*math.pi/180},
	{90*math.pi/180,-30*math.pi/180,-160*math.pi/180},
	{0*math.pi/180,20*math.pi/180,20*math.pi/180}},

 --right jab
 {0.2,{90*math.pi/180, 30*math.pi/180, -160*math.pi/180},
	{-20*math.pi/180,-30*math.pi/180,0*math.pi/180},
	{0*math.pi/180,20*math.pi/180,20*math.pi/180}},

--left straignt
 {0.3,{-20*math.pi/180, 20*math.pi/180, 0*math.pi/180},
	{90*math.pi/180,-40*math.pi/180,-160*math.pi/180},
	{0*math.pi/180,20*math.pi/180,-30*math.pi/180}},

--retract
 {0.2,{90*math.pi/180, 40*math.pi/180, -160*math.pi/180},
	{90*math.pi/180,-40*math.pi/180,-160*math.pi/180},
	{0*math.pi/180,20*math.pi/180,-30*math.pi/180}},
 {0.3,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
	{90*math.pi/180, -8*math.pi/180,-40*math.pi/180},
	{0*math.pi/180,20*math.pi/180,0*math.pi/180}}
} 


