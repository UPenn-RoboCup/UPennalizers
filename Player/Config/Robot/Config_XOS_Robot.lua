module(..., package.seeall);
require('vector')
require 'unix'

-- Get the robot name for custom parameters
local robotName = unix.gethostname();

--Sitting parameters
sit={};
sit.bodyHeight=0.17+0.05; --Fixed with new kinematics
sit.supportX=-0.010;
sit.bodyTilt=5*math.pi/180;
sit.dpLimit=vector.new({.1,.01,.06,.1,.3,.1});


--Standing parameters
stance={};
stance.dpLimit=vector.new({.04, .03, .04, .4, .4, .4});
stance.dpLimit=vector.new({.04, .03, .07, .4, .4, .4});--Faster standup

stance.footXSit = -0.05;
stance.bodyTiltSit = -5*math.pi/180;
stance.bodyHeightSit = 0.18;
stance.qLArmSit = math.pi/180*vector.new({140,8,-40});
stance.qRArmSit = math.pi/180*vector.new({140,-8,-40});
stance.dpLimitSit=vector.new({.03,.01,.06,.1,.3,.3});

--Init angle for start-up
stance.initangle = vector.new( { 
  -0.6, -108.5,
  72.9, 1.8, 0.0, -0.3,
  -0.6, -1.0, 0.9, 2.9, -0.3, -0.9,
  0.9, -0.4, -0.0, 1.2, 1.2, 2.9,
  51.6, 0.3, 0.0, 5.6,
  0.0,
}) * math.pi/180;
stance.standangle = vector.new( {
  -1.8, -110.9,
  68.8, 13.5, 0.0, -19.9,
  -8.8, 5.8, 14.1, -1.9, -7.0, -5.6,
  -8.8, -10.1, 15.2, 2.7, -2.6, 11.7,
  65.6, -5.9, 0.0, 17.3,
  29.0,
}) * math.pi/180;


--Servo parameters
servo={}

servo.idMap = {
  20,21, --Head
  2,4,22,6, --Larm
  8,10,12,14,16,18, --LLeg
  7,9,11,13,15,17, --RLegs
  1,3,23,5, --RArm
  19, --Waist
};

nJoint = #servo.idMap;

servo.dirReverse = {
  --  2,-- Head Pitch
  7, -- Left hip yaw
  11,12, -- LAnkle Roll
  13, -- Right hip yaw
  15,16, -- RLeg
  18, -- RAnkle rolls
  19, --RArm
  23
};

-- Pippy has reverse pitch and waist direction
if( robotName=='pippy' ) then
  servo.dirReverse = {
    2,-- Head Pitch
    7, -- Left hip yaw
    11,12, -- LAnkle Roll
    13, -- Right hip yaw
    15,16, -- RLeg
    18, -- RAnkle rolls
    19, --RArm
    --23
  };
end


--Robot-specific firmware version handling
servo.pid = 0; --old firmware default
servo.armBias = {0,0,0,0,0,0}; --in degree
servo.syncread = 1;
--servo.syncread = 0;


if servo.pid ==0 then -- For old firmware with 12-bit precision
  print(robotName.." has 12-bit firmware")
  servo.steps = {
    1024,1024,
    1024,4096,1024,4096,
    1024,4096,4096,4096,4096,4096,
    1024,4096,4096,4096,4096,4096,
    1024,4096,1024,4096,
    4096,
  }
  servo.moveRange = vector.new({
    300,300,
    300,251,300,251,
    300,251,251,251,251,251,
    300,251,251,251,251,251,
    300,251,300,251,
    251,
  })*math.pi/180;

  --New zero values (for all-106 new legs and waist)
  servo.posZero={
    512,512,
    512,2048,512,2048,
    512,1612,1682,2063,2026,2054,
    512,2420,2420,2011,1817,2441,
    512,2048,512,2048,
    2432, --For waist
  }






else -- For new, PID firmware with 14-bit precision
  print(robotName.." has 14-bit firmware")
  servo.steps=vector.ones(nJoint)*4096;
  servo.posZero={
    2048,2048, --Head
    1024,2560,3072, --LArm
    2048,2048,2048,2048,2048,2048, --LLeg
    2048,2048,2048,2048,2048,2048, --RLeg
    3072,1536,1024, --RArm
  };
  servo.moveRange=vector.ones(nJoint)*360*math.pi/180;
end

-- NEW --------------------
-- Use fancy calibration
local robotName = unix.gethostname();
require('calibration');
if calibration.cal and calibration.cal[robotName] then
  --[[
  if calibration.cal[robotName].pid then
  servo.pid = calibration.cal[robotName].pid;
  end
  --]]
  if calibration.cal[robotName].armBias then
    servo.armBias = calibration.cal[robotName].armBias;
  end 
end
---------------------------

--Measured IMU bias parameters

gyro={};
gyro.rpy={1,2,3}; --axis remap, rotation in x,y,z
acc={};
acc.xyz={1,2,3};  --axis remap

angle={};
angle.gMax = 1.3;
angle.gMin= 0.7;
angle.accFactor=0.2;

-- http://www.sparkfun.com/products/9431
-- XOS Spec, .00333 V/dps / (3.3/1024 V/value)
-- 1.0333090909 value/dps
gyro.zero=vector.new({505,500,502});
gyro.sensitivity=vector.new({1,-1,1}) / 1.0333090909

--Those biases can be measured using test_imu.lua
acc.sensitivity=vector.new({-1,-1,-1}) / 133; --Measured value
acc.zero=vector.new({665,647,664}); --Measured value

-- Head Parameters
head = {};
head.camOffsetZ = 0.9;
head.pitchMin = -20*math.pi/180;
head.pitchMax = 70*math.pi/180;
head.yawMin = -60*math.pi/180;
head.yawMax = 60*math.pi/180;

head.neckZ = 0.37; --From CoM to neck joint 
head.neckX = 0.010; --From CoM to neck joint

-- Found somewhere...
--head.linkParam = {1.0242,-0.6363};

-- From last year SVN
head.linkParam={0.6309, -0.0251}    --linkage transform from servo to headangle, y=ax+b
head.invlinkParam={1.5839,0.0397}   --linkage transform from headangle to servo, y=ax+b
head.cameraPos = {{0.06, 0.0, 0.06}}
head.cameraAngle = {{0.0, 0*45*math.pi/180, 0.0}}
