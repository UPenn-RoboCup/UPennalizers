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
gyroFactor=0.001; --Rough value for nao
gyroFactor=0.000; --Zero out gyroFactor

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

kick.qLArm = math.pi/180*vector.new({105, 12, -85, -30});
kick.qRArm = math.pi/180*vector.new({105, -12, 85, 30});

kick.qLArm = math.pi/180*vector.new({105, 20, -85, -30});
kick.qRArm = math.pi/180*vector.new({105, -20, 85, 30});
kick.armGain= 0.20; --How much shoud we swing the arm? (smaller value = larger swing)

--Kick support bias

kick.supportCompL = vector.new({0, 0, 0}); 
kick.supportCompR = vector.new({0, 0, 0} ); 

kick.kickLeft={
        {1, .6, {0,0,0}          }, --Stabilize
        {1, 0.6, {0,-0.06,0}          }, --COM slide
	{2, 0.3, {0,-0.06,0} , {-0.07,-0.03,0}, 0.07 , 20*math.pi/180},--Lifting
        {4, 0.3, {0,-0.06,0} , {0.20,0,0},  0.04 , -10*math.pi/180},--Kicking
	{2, 0.6, {0,-0.06,0} , {-0.13,0.03,0}, 0, 0 }, --Landing
	{1, 0.6, {0.00,-0.0, 0}},--COM slide
	{1, 0.6, {0.00,-0.0, 0}},--Stabilize
	}

kick.kickRight={
        {1, .6, {0,0,0}          }, --Stabilize
        {1, 0.6, {0,0.060,0}          }, --COM slide
	{3, 0.3, {0,0.060,0} , {-0.07,0.03,0}, 0.07 , 20*math.pi/180}, --Lifting
        {5, 0.3, {0,0.060,0} , {0.20,0,0},  0.04 , -10*math.pi/180}, --Kicking
	{3, 0.6, {0,0.060,0} , {-0.13,-0.03,0}, 0, 0 }, --Landing
	{1, 0.6, {0.00, 0.0, 0}},--COM slide
	{1, 0.6, {0.00, 0.0, 0}},--Stabilize
	}

kick.kickSideLeft={
        {1, 1, {0,0,0}          }, --Stabilize
        {1, 0.6, {0,-0.06,0}          }, --COM slide
	{2, 0.6, {0,-0.06,0} , {-0.07,-0.03,0}, 0.07 , 20*math.pi/180},--Lifting
        {4, 0.3, {0,-0.06,0} , {0.20,0,0},  0.04 , -10*math.pi/180},--Kicking
	{2, 0.6, {0,-0.06,0} , {-0.07,0.030,0}, 0, 0 }, --Landing
	{1, 0.6, {0.03,0, 0}},--COM slide
	{1, 0.6, {0.03,0, 0}},--Stabilize
	}

kick.kickSideRight={
        {1, 1, {0,0,0}          }, --Stabilize
        {1, 0.6, {0,0.060,0}          }, --COM slide
	{3, 0.6, {0,0.060,0} , {-0.07,0.03,0}, 0.07 , 20*math.pi/180}, --Lifting
        {5, 0.3, {0,0.060,0} , {0.20,0,0},  0.04 , -10*math.pi/180}, --Kicking
	{3, 0.6, {0,0.060,0} , {-0.07,-0.030,0}, 0, 0 }, --Landing
	{1, 0.6, {0.03, 0, 0}},--COM slide
	{1, 0.6, {0.03, 0, 0}},--Stabilize
	}
