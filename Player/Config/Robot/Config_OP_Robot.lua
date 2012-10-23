module(..., package.seeall);
require('vector')
require('unix')

--Sit/stand stance parameters
stance={};

stance.footXSit = -0.05;
stance.bodyTiltSit = -5*math.pi/180;
stance.bodyHeightSit = 0.18;
stance.qLArmSit = math.pi/180*vector.new({140,8,-40});
stance.qRArmSit = math.pi/180*vector.new({140,-8,-40});
stance.dpLimitSit=vector.new({.03,.01,.06,.1,.3,.3});

--This makes correct sideways dive
stance.bodyHeightDive= 0.25;
stance.bodyTiltDive= 0;

--stance.bodyHeightDive= 0.28;
stance.dpLimitDive=vector.new({.06,.06,.09,.9,.9,.9});

--Same stance as walking, with zero tilt
stance.bodyHeightDive= 0.295;
stance.bodyTiltDive= 0*math.pi/180;
stance.dpLimitDive=vector.new({.06,.06,.06,.7,.7,.7});

stance.bodyTiltStance=20*math.pi/180; --bodyInitial bodyTilt, 0 for webots
stance.dpLimitStance=vector.new({.04, .03, .07, .4, .4, .4});

--Sit final value
stance.initangle = vector.new({
  0,0,
  105, 30, -45,
--  0,  -2, -16, 110, -119, 2, 
--  0, 2, -16, 110, -119, -2,

  0,  -2, -26, 110, -119, 2, 
  0, 2, -26, 110, -119, -2,

  105, -30, -45,
})*math.pi/180;


-- Head Parameters
head = {};
head.camOffsetZ = 0.37;
head.pitchMin = -55*math.pi/180;
head.pitchMax = 68*math.pi/180;
head.yawMin = -90*math.pi/180;
head.yawMax = 90*math.pi/180;
head.cameraPos = {{0.034, 0.0, 0.0332}} --OP, spec value, may need to be recalibrated
head.cameraAngle = {{0.0,0}}; -- We set it zero here
head.neckZ=0.0765; --From CoM to neck joint 
head.neckX=0.013; --From CoM to neck joint

--IMU bias/sensitivity parameters
gyro={};
gyro.rpy={3,2,1}	--axis remap, rotation in x,y,z
acc={};
acc.xyz={2,1,3};	--axis remap

angle={};
angle.gMax = 1.2;  
angle.gMin= 0.8;
angle.accFactor=0.2;

-- Spec, 0.0008 V/dps  / (1.5/512) V/step 
-- Output unit:degree per sec
gyro.sensitivity=vector.new({1,-1,-1})/0.273 
gyro.zero=vector.new({512,512,512});

--Those biases can be measured using test_imu.lua
acc.sensitivity=vector.new({1,-1,-1})/128; --Spec
acc.zero=vector.new({512,512,512}); --Spec

--Servo parameters
servo={}
servo.idMap={
  19,20,		--Head
  2,4,6,		--LArm
  8,10,12,14,16,18,--LLeg
  7,9,11,13,15,17,--RLeg
  1,3,5,		--RArm
}
servo.dirReverse={
  2,	--Head
  4,	--LArm
  6,7,8,9,--LLeg
  12,13,16,--RLeg
  18,19,20,--RArm
}

----------------------------------------------
--Robot-specific firmware version handling
----------------------------------------------
servo.armBias = {0,0,0,0,0,0}; --in degree
servo.pid =1;  --Default new firmware
local robotName = unix.gethostname();
require('calibration');
if calibration.cal and calibration.cal[robotName] then
  if calibration.cal[robotName].pid then
    servo.pid = calibration.cal[robotName].pid;
  end
  if calibration.cal[robotName].armBias then
    servo.armBias = calibration.cal[robotName].armBias;
  end
end
-----------------------------------------------

nJoint = #servo.idMap;
if servo.pid ==0 then -- For old firmware with 12-bit precision
  print(robotName.." has 12-bit firmware")
  servo.steps=vector.ones(nJoint)*1024;
  servo.moveRange=vector.ones(nJoint)*300*math.pi/180;
  servo.posZero={
    512,512,
    205,665,819,
    512,512,512,512,512,512,
    512,512,512,512,512,512,
    819,358,205,
    --		512,		--For aux
  }
  -- SLOPE parameters
  servo.slope_param={
    32,	--Regular slope
    16,	--Kick slope
  };

else -- For new, PID firmware with 14-bit precision
  print(robotName.." has 14-bit firmware")
  servo.steps=vector.ones(nJoint)*4096;
  servo.posZero={
    2048,2048, --Head
    1024,2560,3072, --LArm
    2048,2048,2048,2048,2048,2048, --LLeg
    2048,2048,2048,2048,2048,2048, --RLeg
    3072,1536,1024, --RArm
    --          512, -- For aux
  };

  -- PID Parameters
  servo.pid_param={
    --Regular PID gain
    {32,0,4},
    --Kick PID gain
    {64,0,4},
  };

  servo.moveRange=vector.ones(nJoint)*360*math.pi/180;
  --[[ For aux
  servo.moveRange[21] = 300;
  servo.steps[21] = 1024;
  --]]
end

