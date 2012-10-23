module(..., package.seeall);
require('vector')

--Kick parameters

kick={};

--Imu feedback parameters, alpha / gain / deadband / max
gyroFactor=0.273 *math.pi/300/1024;  --For degree per second unit

--Kick stabilization vallues

kick.ankleImuParamX={0.6,0.2*gyroFactor, 0, 15*math.pi/180};
kick.kneeImuParamX={0.6,0.7*gyroFactor, 0, 15*math.pi/180};
kick.ankleImuParamY={0.9,0.7*gyroFactor, 0, 15*math.pi/180};
kick.hipImuParamY={0.9,0.3*gyroFactor, 0, 15*math.pi/180};
kick.armImuParamX={0.3,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
kick.armImuParamY={0.3,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--Kick arm pose
kick.qLArm=math.pi/180*vector.new({95,22,-135});
kick.qRArm=math.pi/180*vector.new({95,-22,-135});

kick.hardnessArm={1, 0.3 ,0.3};
kick.hardnessLeg=1;

--How much should we swing the arm? (smaller value = larger swing)
kick.armGain= 0.10; 

kick.bodyHeight = 0.295; --This should be the same as walk.bodyHeight
kick.hipRollCompensation = 5*math.pi/180;

kick.def={};

kick.def["kickForwardLeft"]={
   supportLeg = 1, --Right support
   def = {
     {1, 0.6, {-0.01,-0.050,0} , 0.303          }, --COM slide
     {2, 0.3, {-0.01,-0.055,0} , {-0.06,-0.02,0}, 0.05 , 0}, --Lifting
     {2, 0.1, {-0.03, -0.055,0} , {-0.06,0,0}, 0.10 , 40*math.pi/180},--Lifting
     {4, 0.2, {-0.03,-0.055,0} , {0.30,0,0},  0.07 , 0*math.pi/180}, --Kicking
     {2, 0.6, {-0.01,-0.055,0} , {-0.18,0.010,0}, 0, 0 }, --Landing
     {1, 0.6, {-0.00,-0.02, 0}},--COM slide
     {6, 0.6, {0.000, -0.01, 0}},--Stabilize
   },
};

kick.def["kickForwardRight"]={
  supportLeg = 0,
  def = {
    {1, 0.6, {-0.01 ,0.05,0},0.303}, --COM slide
    {3, 0.3, {-0.01 ,0.055,0} , {-0.06, 0.02, 0}, 0.05 , 0},
    {3, 0.1, {-0.03 ,0.055,0} , {-0.06, 0.0, 0}, 0.10 , 40*math.pi/180}, 
    {5, 0.2, {-0.03 ,0.055,0} , {0.30, 0, 0},  0.07 , 0*math.pi/180},--Kicking
    {3, 0.6, {-0.01 ,0.055,0} , {-0.18,-0.010,0}, 0, 0 }, --Landing
    {1, 0.6, {-0.00, 0.02, 0}},--COM slide
    {6, 0.6, {0.000, 0.01, 0}},--Stabilize
  },
}

kick.def["kickSideLeft"]={
  supportLeg = 1,
  def = {
    {1, 0.6, {-0.01,-0.05,0} , 0.299          }, --COM slide
    {2, 0.4, {-0.01,-0.05,0} , { 0,      0.04,  0.6}, 0.03 ,0*math.pi/180}, --Lifting
    {4, 0.2, {-0.01,-0.05,0} , { 0.06,  -0.16,  -0.9},  0.03 , 0*math.pi/180}, --Kicking
    {2, 0.4, {-0.01,-0.05,0} , {-0.15,  0.017,  0.3}, 0, 0 }, --Landing
    {6, 0.6, {0.00, 0.00, 0}},--Stabilize
  },
}

kick.def["kickSideRight"]={
  supportLeg = 0,
  def = {
    {1, 0.6, {-0.01,0.05,0}   ,0.299       }, --COM slide
    {3, 0.4, {-0.01,0.05,0} ,  {0, -0.04, -0.6}, 0.03 ,0*math.pi/180 }, --Lifting
    {5, 0.2, {-0.01,0.05,0} , {0.06,  0.16, 0.9},  0.03 , 0*math.pi/180}, --Kicking
    {3, 0.4, {-0.01,0.05,0} , {-0.15, -0.017,-0.3}, 0, 0 }, --Landing
    {6, 0.6, {0.00, 0.00, 0}},--Stabilize
 },
}


-------------------------------------------
--Slow frontkick for test localization
-------------------------------------------

--[[

kick.kickLeft={
  {1, 0.6, {-0.010 ,-0.050,0} , 0.303          }, --COM slide
  {2, 0.3, {-0.010 ,-0.055,0} , {-0.06,-0.02,0}, 0.04 , 0}, --Lifting
  {2, 0.1, {-0.030, -0.055,0} , {-0.06,0,0}, 0.03 , 0*math.pi/180 , 
    0*math.pi/180}, --Lifting
    {2, 0.3, {-0.030 ,-0.055,0} , {0.20,0,0},  0.03 , 
      -0*math.pi/180, -0*math.pi/180}, --Kicking
      {2, 0.6, {-0.010 ,-0.050,0} , {-0.08,0.010,0}, 0, 0 }, --Landing
  {1, 0.6, {-0.00 , -0.020, 0}},--COM slide
  {6, 0.6, {0.000, -0.010, 0},kick.bodyHeight},--Stabilize
}

kick.kickRight={
  {1, 0.6, {-0.010 ,0.050,0},0.303          }, --COM slide
  {3, 0.3, {-0.010 ,0.055,0} , {-0.06, 0.02, 0}, 0.03 , 0},
    {3, 0.1, {-0.030 ,0.055,0} , {-0.06, 0.0, 0}, 0.03 , 0*math.pi/180 , 
      0*math.pi/180}, 
    {3, 0.3, {-0.030 ,0.055,0} , {0.20, 0, 0},  0.03 , -0*math.pi/180, 
      -0*math.pi/180}, --Kicking
      {3, 0.6, {-0.010 ,0.050,0} , {-0.08,-0.010,0}, 0, 0 }, --Landing
  {1, 0.6, {-0.00, 0.020, 0}},--COM slide
  {6, 0.6, {0.000, 0.010, 0},kick.bodyHeight},--Stabilize
}

--]]

-- End slow frontkick


--Weaker sidekick (for obstacle)

kick.kickSlowSideLeft={
  {1, 0.6, {-0.010,-0.055,0} ,0.299          }, --COM slide
  {2, 0.4, {-0.020,-0.060,0} , { 0,  0.04,  0.6}, 0.03 ,0*math.pi/180}, --Lifting
  {2, 0.25, {-0.025,-0.065,0} , { 0.06,-0.18,-0.9},  0.03 ,0*math.pi/180},--Kicking
  {2, 0.4, {-0.020,-0.060,0} , {-0.15,  0.02, 0.3}, 0, 0 }, --Landing
  {6, 0.6, {0.00, 0.00, 0}},--Stabilize
}

kick.kickSlowSideRight={
  {1, 0.6, {-0.01,0.055,0}   ,0.299       }, --COM slide
  {3, 0.4, {-0.02,0.060,0} , {0, -0.04, -0.6}, 0.03 ,0*math.pi/180 }, --Lifting
  {3, 0.25, {-0.025,0.065,0} , {0.06,  0.18, 0.9},  0.03 , 0*math.pi/180}, --Kicking
  {3, 0.4, {-0.020,0.060,0} , {-0.15, -0.02,-0.3}, 0, 0 }, --Landing
  {6, 0.6, {0.00, 0.00, 0}},--Stabilize
}











kick.kickBackLeft={

  {1, 1.0, {-0.010,0,0} ,0.295, 20*math.pi/180         }, --Stabilize
  {1, 1.0, {-0,-0.065,0} ,0.305          }, --COM slide
  {2, 1, {-0,-0.075,0} , { 0,  -0.03,  0}, 0.08 ,0*math.pi/180 , 0*math.pi/180}, --Lifting
  {2, 1, {-0,-0.065,0} , { 0.18,  0,  0}, 0.08 ,-30*math.pi/180 , 0*math.pi/180}, --Lifting

  {2, 0.5, {-0,-0.065,0} , { -0.25,   0,  0}, 0.06, -30*math.pi/180, 0},


    {2, 0.6, {-0,-0.065,0} , {0.06,  0.030, 0}, 0, 0 }, --Landing
  {1, 0.6, {0.010, -0.020, 0},0.305,0},--COM slide
  {1, 0.6, {0.010, -0.020, 0},kick.bodyHeight},--Stabilize
}


kick.kickBackRight={
  {1, 0.6, {-0,0,0}          }, --Stabilize
  {1, 0.8, {-0,0.055,0}   ,0.305       }, --COM slide
  {3, 0.6, {-0,0.065,0} , {0, -0.03, 0}, 0.10 ,0*math.pi/180 , 0*math.pi/180}, --Lifting
  {3, 0.6, {-0,0.065,0} , {0.12, 0, 0}, 0.10 ,0*math.pi/180 , 0*math.pi/180}, --Lifting

  {3, 0.6, {-0,0.065,0} , {0.0, 0, 0}, 0.05 ,0*math.pi/180 , 0*math.pi/180}, --Lifting

  {3, 0.2, {-0,0.065,0} , {-0.09,  0.0, 0},  0.02 , 0*math.pi/180, 0*math.pi/180}, --Kicking
  {3, 0.6, {-0,0.065,0} , {-0.03, 0.030,0}, 0, 0 }, --Landing
  {1, 0.6, {0.010, 0.020, 0}},--COM slide
  {1, 0.6, {0.010, 0.020, 0},kick.bodyHeight},--Stabilize
}



kick.def["kickForwardLeft"]={
   supportLeg = 1, --Right support
   def = {
     {1, 0.9, {-0.01,-0.050,0} , 0.303,5*math.pi/180,10*math.pi/180          
}, --COM slide
     {2, 0.6, {-0.01,-0.055,0} , {-0.06,-0.02,0}, 0.05 , 0}, --Lifting
     {2, 0.1, {-0.03, -0.055,0} , {-0.06,0,0}, 0.05 , 
40*math.pi/180},--Lifting
     {4, 0.4, {-0.03,-0.055,0} , {0.30,0,0},  0.07 , -20*math.pi/180}, 
--Kicking
     {2, 0.6, {-0.01,-0.055,0} , {-0.18,0.010,0}, 0, 0 }, --Landing
     {1, 0.6, {-0.00,-0.02, 0},0.295,0,20*math.pi/180},--COM slide
     {6, 0.6, {0.000, -0.01, 0}},--Stabilize
   },
};




--WORKING
kick.def["kickForwardRight"]={
  supportLeg = 0,
  def = {
    {1, 0.9, {-0.01 ,0.05,0},0.303,-5*math.pi/180,10*math.pi/180}, 
--COM slide
    {3, 0.6, {-0.01 ,0.055,0} , {-0.06, 0.02, 0}, 0.05 , 0},
    {3, 0.1, {-0.03 ,0.055,0} , {-0.06, 0.0, 0}, 0.05 , 
40*math.pi/180}, 
    {5, 0.4, {-0.03 ,0.055,0} , {0.30, 0, 0},  0.07 
,-20*math.pi/180},--Kicking
    {3, 0.6, {-0.01 ,0.055,0} , {-0.18,-0.010,0}, 0, 0 }, --Landing
    {1, 0.6, {-0.00, 0.02, 0},0.295,0,20*math.pi/180},--COM slide
    {6, 0.6, {0.000, 0.01, 0}},--Stabilize
  },
}


