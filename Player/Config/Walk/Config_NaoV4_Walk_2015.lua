module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters for NewWalk

walk = {};

walk.filename = "Walk_2015" --which walk engine file should be used

walk.obscheck = true;
walk.testing = true;
----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.09,0.20};
walk.stanceLimitA={-0*math.pi/180,40*math.pi/180};

walk.velLimitX={-.04,.06}; --from -0.04, 0.08
walk.velLimitY={-.02,.02};
walk.velLimitA={-.4,.4};
walk.velDelta={0.02,0.02,0.15} 


--Foot overlap check variables
walk.footSizeX = {-0.04,0.08};
walk.stanceLimitMarginY = 0.035;
--walk.stanceLimitA ={-20*math.pi/180, 40*math.pi/180};

---------------------------------------------
-- Odometry values
--------------------------------------------
walk.odomScale = {1.1, 0.97567, 0.75}; --Old X: 0.782

local robotName = unix.gethostname();
if (robotName == "ticktock") or (robotName == "dickens") or (robotName == "ruffio") then
	walk.odomScale = {1.1, 0.979567, 1.0};
end
----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.30; --from 0.30
walk.bodyTilt=2*math.pi/180; 
walk.footX= 0.0; 
walk.footY = 0.04500;
walk.supportX = 0.018;
walk.qLArm = math.pi/180*vector.new({67,-12,82,-88});
walk.qRArm = math.pi/180*vector.new({67,12,-82,88});

walk.lArmSwing = math.pi/180*13;
walk.rArmSwing = math.pi/180*13; 
walk.lArmDefault = math.pi/180*80;
walk.rArmDefault = math.pi/180*80;

walk.qLArmKick = math.pi/180*vector.new({105, 18, -85, -30});
walk.qRArmKick = math.pi/180*vector.new({105, -18, 85, 30});

walk.hardnessSupport = .66;
walk.hardnessSwing = .46;
walk.hardnessArm=.3;
---------------------------------------------
-- Gait parameters
---------------------------------------------
walk.tStep = 0.245; 
walk.tZmp = 0.18;
walk.supportY = 0.002;
walk.stepHeight=0.023; 
walk.phSingle={0.02,0.98};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation = 1.5*math.pi/180;
walk.ankleMod = vector.new({-1,0})/0.12 * 0*math.pi/180; --({-1,0})/0.12 * 10*math.pi/180;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------

--ALPHA     : Changes HOW QUICKLY compensating torque is applied
--GAIN      : Changes HOW MUCH compensating torque is applied
--DEADBAND  : The range of values for which torque WILL NOT be applied 

walk.gyroFactor = 0.001; --In units of degrees per second

--Front to back compensation
walk.ankleImuParamX={0.11, -0.50*walk.gyroFactor,1*math.pi/180, 5*math.pi/180}
walk.kneeImuParamX={0.1, -0.3*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180}

--Side to side compensation
walk.ankleImuParamY={0.22, -1.9*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180}
walk.hipImuParamY={0.1, -0.3*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180}

--Arm compensation
walk.armImuParamX={0.1, 0*walk.gyroFactor,1*math.pi/180, 5*math.pi/180}
walk.armImuParamY={0.1, 0*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180}

--------------------------------------------
-- Support point modulation values
--------------------------------------------
walk.supportFront = 0.01; --Lean front when walking fast forward
walk.supportBack = -0.02; --Lean back when walking backward
walk.supportSideX = -0.01; --Lean back when sidestepping
walk.supportSideY = 0.02; --Lean sideways when sidestepping

walk.frontComp = 0
walk.velFastForward = 0.04

--------------------------------------------
-- Robot - specific calibration parameters
--------------------------------------------

walk.kickXComp = 0;
walk.supportCompL = {0,0,0};
walk.supportCompR = {0,0,0};

--Shift torso a bit to front when kicking
walk.kickXComp = -0.01;

walk.zmp_type = 1
walk.phSingleRatio = walk.phSingle[1]*2
walk.LHipOffset,walk.RHipOffset,walk.LAnkleOffset,walk.RAnkleOffset = 0,0,0,0

--ADDED ROBOT-SPECIFIC CALIBRATION
local robotName=unix.gethostname();
require('calibration')
if calibration.cal and calibration.cal[robotName] then
  for i,j in pairs(calibration.cal[robotName]) do
  walk[i] = j
  print(string.format("Parameter %s:%f loaded for %s",
    i,j,robotName))
  end
end