module(..., package.seeall);
require('vector')

--Kick parameters

kick={}

--Encoder feedback parameters, alpha/gain

kick.tSensorDelay = 0.10;
--Disabled 
kick.torsoSensorParamX={1-math.exp(-.010/0.2), 0} 
kick.torsoSensorParamY={1-math.exp(-.010/0.2), 0}

--Imu feedback parameters, alpha / gain / deadband / max

gyroFactor=0.273*math.pi/180 *300/1024;  --For degree per second unit
gyroFactor=0.00;

kick.ankleImuParamX={0.1, -0.3*gyroFactor, 
	1*math.pi/180, 5*math.pi/180};
kick.kneeImuParamX={0.1, -0.4*gyroFactor, 
	.5*math.pi/180, 5*math.pi/180};
kick.ankleImuParamY={0.1, -0.7*gyroFactor, 
	.5*math.pi/180, 5*math.pi/180};
kick.hipImuParamY={0.1, -0.3*gyroFactor, 
	.5*math.pi/180, 5*math.pi/180};

--Disabled for nao
kick.armImuParamX={0,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
kick.armImuParamY={0,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--Kick arm pose

kick.qLArm = math.pi/180*vector.new({110, 12, -0, -40});
kick.qRArm = math.pi/180*vector.new({110, -12, 0, 40});	
kick.armGain= 0.20; --How much shoud we swing the arm? (smaller value = larger swing)

--Kick support bias

kick.supportCompL = vector.new({0, 0, 0}); 
kick.supportCompR = vector.new({0, 0, 0} ); 

kick.kickLeft={
        {1, .6, {0,0,0}          }, --Stabilize
        {1, 0.6, {0,-0.13,0}          }, --COM slide
	{2, 0.3, {0,-0.13,0} , {-0,-0,0}, 0.15 , 0*math.pi/180},--Lifting
	{2, 0.3, {0,-0.13,0} , {-0.20,-0.07,0}, 0.15 , 20*math.pi/180},--Lifting
        {2, 0.3, {0,-0.13,0} , {0.55,0,0},  0.15 , -10*math.pi/180},--Kicking
--        {4, 0.3, {0,-0.13,0} , {0.55,0,0},  0.15 , -10*math.pi/180},--Kicking
	{2, 0.6, {0,-0.13,0} , {-0.36,0.07,0}, 0, 0 }, --Landing
	{1, 0.6, {0.00,-0.0, 0}},--COM slide
	{1, 0.6, {0.00,-0.0, 0}},--Stabilize
	}

kick.kickRight={
        {1, .6, {0,0,0}          }, --Stabilize
        {1, 0.6, {0,0.13,0}          }, --COM slide
	{3, 0.3, {0,0.13,0} , {-0.0,0,0}, 0.15 , 0*math.pi/180}, --Lifting
	{3, 0.3, {0,0.13,0} , {-0.20,0.07,0}, 0.15 , 20*math.pi/180}, --Lifting
        {3, 0.3, {0,0.13,0} , {0.55,0,0},  0.15 , -10*math.pi/180}, --Kicking
--        {5, 0.3, {0,0.13,0} , {0.55,0,0},  0.15 , -10*math.pi/180}, --Kicking
	{3, 0.6, {0,0.13,0} , {-0.36,-0.07,0}, 0, 0 }, --Landing
	{1, 0.6, {0.00, 0.0, 0}},--COM slide
	{1, 0.6, {0.00, 0.0, 0}},--Stabilize
	}

