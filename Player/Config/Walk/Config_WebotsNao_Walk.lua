module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters for NewWalk

walk = {};

walk.filename = 'Walk_2016'

walk.testing = true;
----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.09,0.20};
walk.stanceLimitA={-0*math.pi/180,40*math.pi/180};

walk.velLimitX={-.04,.05};
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
walk.odomScale = {0.79, 0.97567, 0.75}; --Old X: 0.782

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.315; 
walk.bodyTilt=0*math.pi/180; 
walk.footX= 0.0; 
walk.footY = 0.0500;
walk.supportX = 0.018;
--walk.qLArm = math.pi/180*vector.new({105, 12, -85, -30});
--walk.qRArm = math.pi/180*vector.new({105, -12, 85, 30});
--New streamlined arm pose
walk.qLArm = vector.new({67,-12,82,-88})*math.pi/180
walk.qRArm = vector.new({67,12,-82,88})*math.pi/180


walk.hardnessSupport = .7;
walk.hardnessSwing = .5;
walk.hardnessArm=.3;
---------------------------------------------
-- Gait parameters
---------------------------------------------
walk.tStep = 0.26;
walk.tZmp = 0.17;
walk.supportY = 0.002;
walk.stepHeight = 0.020;
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

walk.PIDX = {0,0,-0.08}
walk.filterX = {0.1, 1.5*math.pi/180,8*math.pi/180}
walk.PIDVelX = 10*math.pi/180

walk.PIDY = {0,0,-0.025}
walk.filterY = {0.1, 1.5*math.pi/180,8*math.pi/180}
walk.PIDVelY = 10*math.pi/180

--------------------------------------------
-- Support point modulation values
--------------------------------------------
walk.supportFront = 0.01; --Lean front when walking fast forward
walk.supportBack = -0.02; --Lean back when walking backward
walk.supportSideX = -0.01; --Lean back when sidestepping
walk.supportSideY = 0.02; --Lean sideways when sidestepping


walk.frontComp = 0
walk.velFastForward = 0.04


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

--Testing
--walk.velDelta={0.01,0.01,0.15} 

--walk.velLimitX={-.04,.06};
walk.velLimitY={-.03,.03};


walk.hipRollCompensation = 0*math.pi/180;


walk.tStep = 0.5 --FOR IK testing!
--walk.tStep = 2 --FOR IK testing!

walk.stanceLimitX={-0.20,0.20};
walk.velDelta={0.05,0.02,0.15} 





walk.bodyHeight = 0.315; --marginal
walk.tStep = 0.5 --FOR IK testing!

--walk.phSingle={0.2,0.8};

walk.heeltoe_angles={3*math.pi/180, 20*math.pi/180}
walk.heeltoe_vel_min = 0.06
walk.velLimitX={-0.10,0.15}



--stretched knee, fast walk
walk.tStep = 0.26;
walk.bodyHeight = 0.32; 
walk.heeltoe_angles={3*math.pi/180, 10*math.pi/180}
walk.heeltoe_vel_min = 0.06