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
--gyroFactor=0.000;

kick.ankleImuParamX={0.1, -0.3*gyroFactor, 1*math.pi/180, 5*math.pi/180};
kick.kneeImuParamX={0.1, -0.4*gyroFactor, .5*math.pi/180, 5*math.pi/180};
kick.ankleImuParamY={0.1, -0.7*gyroFactor,.5*math.pi/180, 5*math.pi/180};
kick.hipImuParamY={0.1, -0.3*gyroFactor, .5*math.pi/180, 5*math.pi/180};

--Disabled for nao
kick.armImuParamX={0,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
kick.armImuParamY={0,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--Kick arm pose

kick.qLArm = math.pi/180*vector.new({105, 12, -85, -30});
kick.qRArm = math.pi/180*vector.new({105, -12, 85, 30});

kick.qLArm = math.pi/180*vector.new({105, 20, -85, -30});
kick.qRArm = math.pi/180*vector.new({105, -20, 85, 30});
kick.armGain= 0.20; --How much shoud we swing the arm? (smaller value = larger swing)

kick.hardnessArm = 0.3;
kick.hardnessLeg = 1;
kick.hipRollCompensation = 3*math.pi/180;

--Kick support bias

kick.supportCompL = vector.new({0, 0, 0}); 
kick.supportCompR = vector.new({0, 0, 0} ); 

kick.def={};




kick.def["kickForwardLeft"]={
   supportLeg = 1, --Right support
   def = {
     {1, 0.4, {0,0,0} , 0.32, 0         }, --stabilize
     {1, 0.6, {-0.02,-0.06,0} , 0.33, 7*math.pi/180         }, --COM slide
     {2, 0.3, {-0.02,-0.07,0} , {-0.06,-0.01,0}, 0.05 , 0}, --Lifting
     {2, 0.2, {-0.02, -0.07,0} , {-0.06,0,0}, 0.05 , 10*math.pi/180}, --Lifting
     {2, 0.2, {-0.02,-0.07,0} , {0.22,0,0},  0.03 , -10*math.pi/180}, --Kicking
     {2, 0.3, {-0.02,-0.07,0} , {0,0,0},  0.04 , 0*math.pi/180}, --Kicking
     {2, 0.3, {-0.02,-0.07,0} , {0,0,0},  0.04 , 0*math.pi/180}, --Stabilize
     {2, 0.8, {-0.00,-0.06,0} , {-0.10,0.020,0}, 0, 0 }, --Landing
     {1, 0.6, {-0.00,-0.02, 0}},--COM slide
     {6, 0.6, {0.000, -0.0, 0}},--Stabilize
   },
};


kick.def["kickForwardRight"]={
  supportLeg = 0,
  def = {
    {1, 0.4, {0,0,0} , 0.32, 0         }, --stabilize
    {1, 0.6, {-0.02 ,0.06,0},0.33 , -7*math.pi/180}, --COM slide
    {3, 0.3, {-0.02 ,0.07,0} , {-0.06, 0.01, 0}, 0.05 , 0},
    {3, 0.2, {-0.02 ,0.07,0} , {-0.06, 0.0, 0}, 0.05 , 10*math.pi/180}, 
    {3, 0.2, {-0.02 ,0.07,0} , {0.22, 0, 0},  0.03 , -10*math.pi/180},--Kicking
    {3, 0.3, {-0.02 ,0.07,0} , {0, 0, 0},  0.04 , 0*math.pi/180}, --Kicking
    {3, 0.3, {-0.02 ,0.07,0} , {0, 0, 0},  0.04 ,0*math.pi/180},--Stabilize
    {3, 0.8, {-0.00 ,0.06,0} , {-0.10,-0.020,0}, 0, 0 }, --Landing
    {1, 0.6, {-0.00, 0.02, 0}},--COM slide
    {6, 0.6, {0.000, 0.0, 0}},--Stabilize
  },
}



--NEW KICK

kick.hipRollCompensation = 4*math.pi/180;

kick.def["kickForwardLeft"]={
   supportLeg = 1, --Right support
   def = {
     {1, 0.4, {0,0,0} , 0.32, 0         }, --stabilize
     {1, 0.6, {-0.02,-0.06,0} , 0.33, 7*math.pi/180         }, --COM slide
     {2, 0.3, {-0.02,-0.07,0} , {-0.06,-0.01,0}, 0.05 , 0}, --Lifting
     {2, 0.2, {-0.02, -0.07,0} , {-0.06,0,0}, 0.05 , 10*math.pi/180}, --Lifting
     {2, 0.2, {-0.02,-0.07,0} , {0.22,0,0},  0.04 , -10*math.pi/180}, --Kicking
     {2, 0.3, {-0.02,-0.07,0} , {0,0,0},  0.05 , 0*math.pi/180}, --Kicking
     {2, 0.3, {-0.02,-0.07,0} , {0,0,0},  0.05 , 5*math.pi/180}, --Stabilize
     {2, 0.8, {-0.00,-0.06,0} , {-0.10,0.020,0}, 0, 0 }, --Landing
     {1, 0.6, {-0.00,-0.02, 0}},--COM slide
     {6, 0.6, {0.000, -0.0, 0}},--Stabilize
   },
};


kick.def["kickForwardRight"]={
  supportLeg = 0,
  def = {
    {1, 0.4, {0,0,0} , 0.32, 0         }, --stabilize
    {1, 0.6, {-0.02 ,0.06,0},0.33 , -7*math.pi/180}, --COM slide
    {3, 0.3, {-0.02 ,0.07,0} , {-0.06, 0.01, 0}, 0.05 , 0},
    {3, 0.2, {-0.02 ,0.07,0} , {-0.06, 0.0, 0}, 0.05 , 10*math.pi/180}, 
    {3, 0.2, {-0.02 ,0.07,0} , {0.22, 0, 0},  0.04 , -10*math.pi/180},--Kicking
    {3, 0.3, {-0.02 ,0.07,0} , {0, 0, 0},  0.05 , 0*math.pi/180}, --Kicking
    {3, 0.3, {-0.02 ,0.07,0} , {0, 0, 0},  0.05 , 5*math.pi/180},--Stabilize
    {3, 0.8, {-0.00 ,0.06,0} , {-0.10,-0.020,0}, 0, 0 }, --Landing
    {1, 0.6, {-0.00, 0.02, 0}},--COM slide
    {6, 0.6, {0.000, 0.0, 0}},--Stabilize
  },
}




--[[
kick.def["kickSideLeft"]={
  supportLeg = 1,
  def = {
    {1, 0.6, {-0.01,-0.05,0} , 0.32          }, --COM slide
    {2, 0.4, {-0.01,-0.05,0} , { 0,      0.04,  0.6}, 0.03 ,0*math.pi/180}, --Lifting
    {4, 0.2, {-0.01,-0.05,0} , { 0.06,  -0.16,  -0.9},  0.03 , 0*math.pi/180}, --Kicking
    {2, 0.4, {-0.01,-0.05,0} , {-0.15,  0.017,  0.3}, 0, 0 }, --Landing
    {6, 0.6, {0.00, 0.00, 0}},--Stabilize
  },
}

kick.def["kickSideRight"]={
  supportLeg = 0,
  def = {
    {1, 0.6, {-0.01,0.05,0}   ,0.32       }, --COM slide
    {3, 0.4, {-0.01,0.05,0} ,  {0, -0.04, -0.6}, 0.03 ,0*math.pi/180 }, --Lifting
    {5, 0.2, {-0.01,0.05,0} , {0.06,  0.16, 0.9},  0.03 , 0*math.pi/180}, --Kicking
    {3, 0.4, {-0.01,0.05,0} , {-0.15, -0.017,-0.3}, 0, 0 }, --Landing
    {6, 0.6, {0.00, 0.00, 0}},--Stabilize
 },
}
--]]
