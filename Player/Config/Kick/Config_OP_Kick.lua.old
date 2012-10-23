module(..., package.seeall);
require('vector')

--Kick parameters

kick={};

--Encoder feedback parameters, alpha/gain

kick.tSensorDelay = 0.10;
--Disabled for OP
kick.torsoSensorParamX={1-math.exp(-.010/0.2), 0} 
kick.torsoSensorParamY={1-math.exp(-.010/0.2), 0}

--Imu feedback parameters, alpha / gain / deadband / max

gyroFactor=0.273*math.pi/180 *300/1024;  --For degree per second unit
--gyroFactor=0; --Zero feedback testing

kick.ankleImuParamX={0.6,-0.444*gyroFactor, 0, 15*math.pi/180};
kick.ankleImuParamY={0.6,-0.4*gyroFactor, 0, 15*math.pi/180};
kick.kneeImuParamX={0.6,-0.148*gyroFactor, 0, 15*math.pi/180};
kick.hipImuParamY={0.6,-0.2*gyroFactor, 0, 15*math.pi/180};

--Robotis feedback values

kick.ankleImuParamX={0.6,-0.75*gyroFactor, 0, 15*math.pi/180};
--kick.ankleImuParamY={0.6,-1.5*gyroFactor, 0, 15*math.pi/180};
kick.kneeImuParamX={0.6,-0.25*gyroFactor, 0, 15*math.pi/180};
--kick.hipImuParamY={0.6,0.75*gyroFactor, 0, 15*math.pi/180};

--Arm feedback values

kick.armImuParamX={0.3,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
kick.armImuParamY={0.3,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};


--New feedback values
kick.ankleImuParamY={0.9,-0.7*gyroFactor, 0, 25*math.pi/180};
kick.hipImuParamY={0.9,-0.3*gyroFactor, 0, 25*math.pi/180};

kick.ankleImuParamX={0.6,-0.3*gyroFactor, 0, 25*math.pi/180};
kick.kneeImuParamX={0.6,-1.2*gyroFactor, 0, 25*math.pi/180};
kick.armImuParamY={0.3,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};


--Less feedback values
kick.ankleImuParamX={0.6,-0.3*gyroFactor, 0, 25*math.pi/180};
kick.kneeImuParamX={0.6,-0.7*gyroFactor, 0, 25*math.pi/180};



--Kick arm pose
--[[
kick.qLArm=math.pi/180*vector.new({95,30,-135});
kick.qRArm=math.pi/180*vector.new({95,-30,-135});
--]]
kick.qLArm2=math.pi/180*vector.new({95,22,-135});
kick.qRArm2=math.pi/180*vector.new({95,-22,-135});

kick.hardnessArm={1, 0.3 ,0.3};
kick.hardnessLeg=1;

kick.bodyHeight=0.295;

kick.armGain= 0.20; --How much should we swing the arm? (smaller value = larger swing)

--Kick support bias

kick.supportCompL = vector.new({0, 0, 0}); 
kick.supportCompR = vector.new({0, 0, 0} );

kick.kickLeft={
  {1, 0.6, {-0.010 ,-0.050,0} , 0.303          }, --COM slide
  {2, 0.3, {-0.010 ,-0.055,0} , {-0.06,-0.02,0}, 0.05 , 0}, --Lifting
  {2, 0.1, {-0.030, -0.055,0} , {-0.06,0,0}, 0.10 , 40*math.pi/180 , 40*math.pi/180}, --Lifting
  {4, 0.2, {-0.030 ,-0.055,0} , {0.30,0,0},  0.07 , 0*math.pi/180, -40*math.pi/180}, --Kicking
  {2, 0.6, {-0.010 ,-0.050,0} , {-0.18,0.010,0}, 0, 0 }, --Landing
  {1, 0.6, {-0.00 , -0.020, 0}},--COM slide
  {6, 0.6, {0.000, -0.010, 0},kick.bodyHeight},--Stabilize
}


kick.kickRight={
  {1, 0.6, {-0.010 ,0.050,0},0.303          }, --COM slide
  {3, 0.3, {-0.010 ,0.055,0} , {-0.06, 0.02, 0}, 0.05 , 0},
    {3, 0.1, {-0.030 ,0.055,0} , {-0.06, 0.0, 0}, 0.10 , 40*math.pi/180 , 40*math.pi/180}, 
    {5, 0.2, {-0.030 ,0.055,0} , {0.30, 0, 0},  0.07 , 0*math.pi/180, -40*math.pi/180}, --Kicking
  {3, 0.6, {-0.010 ,0.050,0} , {-0.18,-0.010,0}, 0, 0 }, --Landing
  {1, 0.6, {-0.00, 0.020, 0}},--COM slide
  {6, 0.6, {0.000, 0.010, 0},kick.bodyHeight},--Stabilize
}

--stronger kick
--[[

kick.kickLeft={
  {1, 0.6, {-0.010 ,-0.050,0} , 0.303          }, --COM slide
  {2, 0.3, {-0.010 ,-0.055,0} , {-0.06,-0.02,0}, 0.05 , 0}, --Lifting
  {2, 0.1, {-0.030, -0.055,0} , {-0.06,0,0}, 0.10 , 30*math.pi/180 , 60*math.pi/180}, --Lifting
  {4, 0.2, {-0.030 ,-0.055,0} , {0.30,0,0},  0.10 , 
    -30*math.pi/180, -30*math.pi/180}, --Kicking
    {2, 0.6, {-0.010 ,-0.050,0} , {-0.18,0.010,0}, 0, 0 }, --Landing
  {1, 0.6, {-0.00 , -0.020, 0}},--COM slide
  {6, 0.6, {0.000, -0.010, 0},kick.bodyHeight},--Stabilize
}

kick.kickRight={
  {1, 0.6, {-0.010 ,0.050,0},0.303          }, --COM slide
  {3, 0.3, {-0.010 ,0.055,0} , {-0.06, 0.02, 0}, 0.05 , 0},
    {3, 0.1, {-0.030 ,0.055,0} , {-0.06, 0.0, 0}, 0.10 , 30*math.pi/180 , 60*math.pi/180}, 
    {5, 0.2, {-0.030 ,0.055,0} , {0.30, 0, 0},  0.10 , -30*math.pi/180, -30*math.pi/180}, --Kicking
  {3, 0.6, {-0.010 ,0.050,0} , {-0.18,-0.010,0}, 0, 0 }, --Landing
  {1, 0.6, {-0.00, 0.020, 0}},--COM slide
  {6, 0.6, {0.000, 0.010, 0},kick.bodyHeight},--Stabilize
}
--]]

local robotName = unix.gethostname();
print("Hi all, I'm "..robotName)
--if( robotName=='felix' ) then


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

--Side kick

kick.kickSideLeft={
  {1, 0.6, {-0.010,-0.050,0} ,0.299          }, --COM slide
  {2, 0.4, {-0.020,-0.055,0} , { 0,  0.02,  0.6}, 0.03 ,0*math.pi/180}, --Lifting
  {4, 0.2, {-0.020,-0.050,0} , { 0.06,  -0.14,  -0.9},  0.03 , 0*math.pi/180}, --Kicking
  {2, 0.4, {-0.020,-0.045,0} , {-0.15,  0.017, 0.3}, 0, 0 }, --Landing
  {6, 0.6, {0.00, 0.00, 0}},--Stabilize
}

kick.kickSideRight={
  {1, 0.6, {-0.01,0.050,0}   ,0.299       }, --COM slide
  {3, 0.4, {-0.02,0.055,0} , {0, -0.02, -0.6}, 0.03 ,0*math.pi/180 }, --Lifting
  {5, 0.2, {-0.020,0.050,0} , {0.06,  0.14, 0.9},  0.03 , 0*math.pi/180}, --Kicking
  {3, 0.4, {-0.020,0.045,0} , {-0.15, -0.017,-0.3}, 0, 0 }, --Landing
  {6, 0.6, {0.00, 0.00, 0}},--Stabilize
}

--Slightly longer swing


kick.kickSideLeft={
  {1, 0.6, {-0.010,-0.050,0} ,0.299          }, --COM slide
  {2, 0.4, {-0.020,-0.055,0} , { 0,  0.04,  0.6}, 0.03 ,0*math.pi/180}, --Lifting
  {4, 0.2, {-0.020,-0.050,0} , { 0.06,  -0.16,  -0.9},  0.03 , 0*math.pi/180}, --Kicking
  {2, 0.4, {-0.020,-0.045,0} , {-0.15,  0.017, 0.3}, 0, 0 }, --Landing
  {6, 0.6, {0.00, 0.00, 0}},--Stabilize
}

kick.kickSideRight={
  {1, 0.6, {-0.01,0.050,0}   ,0.299       }, --COM slide
  {3, 0.4, {-0.02,0.055,0} , {0, -0.04, -0.6}, 0.03 ,0*math.pi/180 }, --Lifting
  {5, 0.2, {-0.020,0.050,0} , {0.06,  0.16, 0.9},  0.03 , 0*math.pi/180}, --Kicking
  {3, 0.4, {-0.020,0.045,0} , {-0.15, -0.017,-0.3}, 0, 0 }, --Landing
  {6, 0.6, {0.00, 0.00, 0}},--Stabilize
}



--Weaker sidekick (for obstacle)

  kick.kickSlowSideLeft={
    {1, 0.6, {-0.010,-0.055,0} ,0.299          }, --COM slide
    {2, 0.4, {-0.020,-0.060,0} , { 0,  0.04,  0.6}, 0.03 ,0*math.pi/180}, --Lifting
    {2, 0.25, {-0.025,-0.065,0} , { 0.06,-0.17,-0.9},  0.03 ,0*math.pi/180},--Kicking
    {2, 0.4, {-0.020,-0.060,0} , {-0.15,  0.02, 0.3}, 0, 0 }, --Landing
    {6, 0.6, {0.00, 0.00, 0}},--Stabilize
  }

kick.kickSlowSideRight={
  {1, 0.6, {-0.01,0.055,0}   ,0.299       }, --COM slide
  {3, 0.4, {-0.02,0.060,0} , {0, -0.04, -0.6}, 0.03 ,0*math.pi/180 }, --Lifting
  {3, 0.25, {-0.025,0.065,0} , {0.06,  0.17, 0.9},  0.03 , 0*math.pi/180}, --Kicking
  {3, 0.4, {-0.020,0.060,0} , {-0.15, -0.02,-0.3}, 0, 0 }, --Landing
  {6, 0.6, {0.00, 0.00, 0}},--Stabilize
}

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


-- Dodging moves
kick.avoidLeft={
  {1, .4,    {0,-0.060,0}  ,20*math.pi/180}, --COM slide
  {2, .8,    {0,-0.080,0}, {0,0.040,0}, 0.09, 0*math.pi/180 , 30*math.pi/180}, --Lifting
  {4, 2,     {0,-0.080,0}, {0,0.0,0},  0.08, 0*math.pi/180 , 30*math.pi/180}, --Kicking
  {2, 1,     {0,-0.080,0}, {0,-0.04,0},  0,    0     ,30*math.pi/180        }, --Landing
  --  {6, 0.7,     {0,-0.020,0} ,0.24  }, --Sitting
  {6, 0.7,     {0,0.000,0} ,0.23  }, --Sitting
  --[[
  {1, 1,    {0,-0.020,0}  ,0*math.pi/180}, --Torso tilt
  {6, 0.7,     {0,0.0,0} , kick.bodyHeight }, --Standing
  {1, 0.5,   {0,0, 0}      ,0},--Stabilize
  --]]
}

kick.avoidRight={
  {6, .4,     {0,0.060,0} ,0.26  }, --Sit down a bit
  {3, .8,    {0,0.080,0}, {0,-0.050,0}, 0.09, 0*math.pi/180 , -30*math.pi/180}, --Lifting
  {5, 2,     {0,0.080,0}, {0,0.0,0},  0.08, 0*math.pi/180 , -30*math.pi/180}, --Kicking
  {3, 1,     {0,0.080,0}, {0,0.05,0},  0,    0     ,-30*math.pi/180        }, --Landing
  --  {6, 0.7,     {0,0.040,0} ,0.23  }, --Sitting
  {6, 0.7,     {0,0.000,0} ,0.23  }, --Sitting

  --[[
  {1, 1,    {0,0.020,0}  ,0*math.pi/180}, --Torso tilt
  {6, 0.7,     {0,0.0,0} , kick.bodyHeight }, --Standing
  {1, 0.5,   {0,0, 0}      ,0},--Stabilize
  --]]
}

--[[
kick.avoidLeft={
  --        {1, .2,    {0,-0.050,0}  ,20*math.pi/180}, --COM slide
    --      {2, .4,    {0,-0.080,0}, {0,0.040,0}, 0.09, 0*math.pi/180 , 30*math.pi/180}, --Lifting
    --    {4, 2,     {0,-0.080,0}, {0,0.0,0},  0.08, 0*math.pi/180 , 30*math.pi/180}, --Kicking
    --  {2, 1,     {0,-0.020,0}, {0,-0.04,0},  0,    0     ,0        }, --Landing

    {1, .2,    {0,-0.060,0}  ,20*math.pi/180}, --COM slide
  {2, .4,    {0,-0.080,0}, {0,0.040,0}, 0.09, 0*math.pi/180 , 30*math.pi/180}, --Lifting
  {4, 2,     {0,-0.080,0}, {0,0.0,0},  0.08, 0*math.pi/180 , 30*math.pi/180}, --Kicking
  {2, 1,     {0,-0.020,0}, {0,-0.04,0},  0,    0     ,0        }, --Landing
  {1, .5,   {0,0, 0}      ,20*math.pi/180},--COM slide

  --        {1, .2,    {0,-0.060,0}  ,20*math.pi/180}, --COM slide
    --        {2, .4,    {0,-0.080,0}, {0,0.040,0}, 0.09, 0*math.pi/180 , 30*math.pi/180}, --Lifting
    --        {4, 2,     {0,-0.080,0}, {0,0.0,0},  0.08, 0*math.pi/180 , 30*math.pi/180}, --Kicking
    --        {2, 1,     {0,-0.020,0}, {0,-0.04,0},  0,    0     ,0        }, --Landing

    --{1, 0.5,   {0,0, 0}      ,0},--COM slide
    --        {1, 0.5,   {0,0, 0}      ,0},--Stabilize
}
--]]

--[[
kick.avoidRight={
  --        {1, 0.45, {0,0.055,0}                                           }, --COM slide
    --        {3, 0.4,  {0,0.055,0} , {0,0.03,0},    0.08,  0*math.pi/180  }, --Lifting
    --        {5, 2,    {0,0.055,0} , {0,0,0},       0.08,  0*math.pi/180 }, --Kicking
    --        {3, 1,    {0,0.055,0} , {0,-0.03,0}, 0,     0              }, --Landing

    {1, 0.025, {0,0,0}         ,0                                     }, --Stabilize
  {1, 0.45, {0,0.055,0}        ,0                                   }, --COM slide
  {3, 0.4,  {0,0.055,0} , {0,0.03,0},    0.08,  0*math.pi/180  ,0}, --Lifting
  {5, 2,    {0,0.055,0} , {0,0,0},       0.08,  0*math.pi/180 ,0}, --Kicking
  {3, 1,    {0,0.055,0} , {0,-0.03,0}, 0,     0              ,0}, --Landing

  {1, 0.5,  {0, 0, 0},0},--COM slide
  {1, 0.5,  {0, 0, 0},0},--Stabilize
}
--]]

kick.avoidLeft={
  {1, .2,  {0,-0.075,0}, 20*math.pi/180 }, --COM slide
  {2, .4,  {0,-0.080,0}, {0,0.040,0},   0.1, 0*math.pi/180, 30*math.pi/180}, --Lifting
  {4, 2,   {0,-0.080,0}, {0,0.0,0},     0.1, 0*math.pi/180, 30*math.pi/180}, --Kicking
  {2, 1,   {0,-0.020,0}, {0,-0.04,0},   0,   0            , 0        }, --Landing
  {1, .5,  {0, 0, 0},    20*math.pi/180},--COM slide
  {6, 1,   {0, 0, 0},    kick.bodyHeight},--Stabilize
}

kick.avoidRight={
  {1, 0.45, {0,0.055,0},   20*math.pi/180                                   }, --COM slide
  {3, 0.4,  {0,0.055,0} , {0,0.03,0},    0.1,  0*math.pi/180  ,0}, --Lifting
  {5, 2,    {0,0.055,0} , {0,0,0},       0.1,  0*math.pi/180 ,0}, --Kicking
  {3, 1,    {0,0.055,0} , {0,-0.03,0}, 0,     0              ,0}, --Landing
  {1, .5,   {0,0, 0}      ,20*math.pi/180},--COM slide
  {6, 0.6,  {0.0, 0.0, 0},kick.bodyHeight},--Stabilize
}

