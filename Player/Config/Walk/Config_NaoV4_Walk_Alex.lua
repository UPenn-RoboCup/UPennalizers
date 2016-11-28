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

walk.velLimitX={-.04,.06};
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
walk.odomScale={1,1,1};

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.320; 
walk.bodyTilt=1*math.pi/180; 
walk.footX= 0.0; 
walk.footY = 0.05;
walk.qLArm = math.pi/180*vector.new({67,-12,82,-88});
walk.qRArm = math.pi/180*vector.new({67,12,-82,88});
walk.qLArmKick = math.pi/180*vector.new({67,-12,82,-88});
walk.qRArmKick = math.pi/180*vector.new({67,12,-82,88});

walk.hardnessSupport = 0.7;
walk.hardnessSwing = 0.4;
walk.hardnessArm= 0.3;
---------------------------------------------
-- Gait parameters
---------------------------------------------
walk.tStep = 0.280;
walk.tZmp = 0.18;
walk.supportX = 0.01;
walk.supportY = 0.02;
walk.stepHeight = 0.015;
walk.phSingle={0.02,0.98};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation =0.04; 
walk.ankleMod = vector.new({-1,0})/0.12 * 0*math.pi/180; --({-1,0})/0.12 * 10*math.pi/180;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------

--ALPHA     : Changes HOW QUICKLY compensating torque is applied
--GAIN      : Changes HOW MUCH compensating torque is applied
--DEADBAND  : The range of values for which torque WILL NOT be applied 

walk.gyroFactor = 0.001; --In units of degrees per second

--Front to back compensation
walk.ankleImuParamX={0.1, -0.50*walk.gyroFactor,1*math.pi/180, 5*math.pi/180}
walk.kneeImuParamX={0.1, -0.4*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180}

--Side to side compensation
walk.ankleImuParamY={0.2, -1.9*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180}
walk.hipImuParamY={0.1, -0.3*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180}

--Arm compensation
walk.armImuParamX={0.1, 0*walk.gyroFactor,1*math.pi/180, 5*math.pi/180}
walk.armImuParamY={0.1, 0*walk.gyroFactor,.5*math.pi/180, 5*math.pi/180}

--------------------------------------------
-- Support point modulation values
--------------------------------------------
walk.supportFront = 0.00; --Lean front when walking fast forward
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

walk.filename = "Walk_2015" --which walk engine file should be used
walk.supportModYInitial = -0.025

--experimental
walk.use_velocity_smoothing = true
walk.velocity_smoothing_factor = 1.5
