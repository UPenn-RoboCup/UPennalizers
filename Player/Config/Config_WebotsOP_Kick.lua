module(..., package.seeall);
require('vector')

--Kick parameters

kick={};

--Imu feedback parameters, alpha / gain / deadband / max
gyroFactor=0.273*math.pi/180 *300/1024;  --For degree per second unit
kick.ankleImuParamX={0.6,-0.3*gyroFactor, 0, 25*math.pi/180};
kick.kneeImuParamX={0.6,-1.2*gyroFactor, 0, 25*math.pi/180};
kick.ankleImuParamY={0.9,-0.7*gyroFactor, 0, 25*math.pi/180};
kick.hipImuParamY={0.9,-0.3*gyroFactor, 0, 25*math.pi/180};
kick.armImuParamX={0.3,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
kick.armImuParamY={0.3,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--Less feedback values
kick.ankleImuParamX={0.6,-0.3*gyroFactor, 0, 25*math.pi/180};
kick.kneeImuParamX={0.6,-0.7*gyroFactor, 0, 25*math.pi/180};

--Kick arm pose
kick.qLArm=math.pi/180*vector.new({95,22,-135});
kick.qRArm=math.pi/180*vector.new({95,-22,-135});

kick.hardnessArm={1, 0.3 ,0.3};
kick.hardnessLeg=1;

--How much should we swing the arm? (smaller value = larger swing)
kick.armGain= 0.10; 


-----------------------------------------------------------------------------
-- Kick definitions
-- {1, duration, torsoTarget, bodyHeightTarget, bodyRollTarget} - COM slide
-- {2, duration, torsoTarget, relFootXYA, footHeight, footPitch} - LF move
-- {3, duration, torsoTarget, relFootXYA, footHeight, footPitch} - RF move
-- {4, duration, torsoTarget, relFootXYA, footHeight, footPitch} - LF kick
-- {5, duration, torsoTarget, relFootXYA, footHeight, footPitch} - RF kick
-- {6, duration, torsoTarget} -- Return to walk stance
-----------------------------------------------------------------------------

kick.def={};

kick.def["kickForwardLeft"]={
   supportLeg = 1, --Right support
   def = {
     {1, 0.6, {-0.01,-0.05,0} , 0.303          }, --COM slide
     {2, 0.3, {-0.01,-0.05,0} , {-0.06,-0.02,0}, 0.05 , 0}, --Lifting
     {2, 0.1, {-0.01, -0.05,0} , {-0.06,0,0}, 0.10 , 40*math.pi/180}, --Lifting
     {4, 0.2, {-0.01,-0.05,0} , {0.30,0,0},  0.07 , 0*math.pi/180}, --Kicking
     {2, 0.6, {-0.01,-0.05,0} , {-0.18,0.010,0}, 0, 0 }, --Landing
     {1, 0.6, {-0.00,-0.02, 0}},--COM slide
     {6, 0.6, {0.000, -0.01, 0}},--Stabilize
   },
};

kick.def["kickForwardRight"]={
  supportLeg = 0,
  def = {
    {1, 0.6, {-0.01 ,0.05,0},0.303}, --COM slide
    {3, 0.3, {-0.01 ,0.05,0} , {-0.06, 0.02, 0}, 0.05 , 0},
    {3, 0.1, {-0.01 ,0.05,0} , {-0.06, 0.0, 0}, 0.10 , 40*math.pi/180}, 
    {5, 0.2, {-0.01 ,0.05,0} , {0.30, 0, 0},  0.07 , 0*math.pi/180}, --Kicking
    {3, 0.6, {-0.01 ,0.05,0} , {-0.18,-0.010,0}, 0, 0 }, --Landing
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

