module(..., package.seeall);
require('vector')

platform = {};
platform.name = 'darwinop'

-- Device Interface Libraries
dev = {};
dev.body = 'DarwinOPBody'; 
dev.camera = 'darwinCam';
dev.kinematics = 'DarwinOPKinematics';
--dev.comm='NSLComm';
dev.comm='NullComm';
dev.monitor_comm = 'NSLMonitorCommWired';
dev.game_control='NSLGameControl';
dev.walk='NaoWalk';
dev.kick='NaoKick';
--[[
dev.walk='NSLWalk';
dev.kick='NSLKick';
--]]

-- keyframe files
km = {};
km.standup_front = 'km_OP_StandupFromFront.lua';
km.standup_back = 'km_OP_StandupFromBack.lua';

--Sitting parameters
sit={};
sit.bodyHeight=0.18+0.05; --Fixed with new kinematics
sit.bodyHeight=0.17+0.05; --Fixed with new kinematics
sit.supportX=-0.020;
sit.supportX=-0.010;

sit.bodyTilt=5*math.pi/180;

sit.dpLimit=vector.new({.1,.01,.03,.1,.3,.1});
sit.dpLimit=vector.new({.1,.01,.06,.1,.3,.1});--Faster sit

--Standing parameters
stance={};
stance.dpLimit=vector.new({.04, .03, .04, .4, .4, .4});
stance.dpLimit=vector.new({.04, .03, .07, .4, .4, .4});--Faster standup

--Servo parameters

servo={}

servo.type = 1; --1 for CM730, 0 for seeeduino
servo.pid = 0; --old version of rx28M
servo.syncread= 0; 

servo.idMap={
	19,20,		--Head
	2,4,6,		--LArm
	8,10,12,14,16,18,--LLeg
	7,9,11,13,15,17,--RLeg
	1,3,5,		--RArm
--	21, 		--Aux servo
	}

servo.dirReverse={
	2,	--Head
	4,	--LArm
	6,7,8,9,--LLeg
	12,13,16,--RLeg
	18,19,20,--RArm
	}

servo.steps=vector.new({
	1024,1024,
	1024,1024,1024,
	1024,1024,1024,1024,1024,1024,
	1024,1024,1024,1024,1024,1024,
	1024,1024,1024,
	1024,		--For aux
	});

servo.posZero={
	512,512,
	205,665,819,
	512,512,512,512,512,512,
	512,512,512,512,512,512,
	819,358,205,
	512,		--For aux
	}

servo.moveRange=vector.new({
	300,300,
	300,300,300,
	300,300,300,300,300,300,
	300,300,300,300,300,300,
	300,300,300,
	300,		--For aux
	})*math.pi/180;

--Measured IMU bias parameters

gyro={};
gyro.rpy={3,2,1}	--axis remap, rotation in x,y,z
acc={};
acc.xyz={2,1,3};	--axis remap

angle={};
angle.gMax = 1.3;
angle.gMin= 0.7;
angle.accFactor=0.2;

gyro.sensitivity=vector.new({1,1,1})/0.273 -- Spec, 0.0008 V/dps  / (1.5/512) V/step 
gyro.zero=vector.new({512,512,512});

--Those biases can be measured using test_imu.lua
acc.sensitivity=vector.new({1,-1,-1})/110; --Measured value
acc.zero=vector.new({512,512,512}); --Measured value




-- Head Parameters

head = {};
head.camOffsetZ = 0.37;
--head.pitchMin = -35*math.pi/180;
head.pitchMin = -55*math.pi/180;
head.pitchMax = 68*math.pi/180;
head.yawMin = -90*math.pi/180;
head.yawMax = 90*math.pi/180;

head.cameraPos = {{0.034, 0.0, 0.0332}} --OP, spec value, may need to be recalibrated
head.cameraAngle = {{0.0, 40*math.pi/180, 0.0}}; --Default value for production OP
head.neckZ=0.0765; --From CoM to neck joint 
head.neckX=0.013; --From CoM to neck joint
head.bodyTilt = 0;

