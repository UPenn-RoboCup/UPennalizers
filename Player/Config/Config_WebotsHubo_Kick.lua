module(..., package.seeall);
require('vector')

--New kick parameters for NewKick

kick={};

--Imu feedback parameters, alpha / gain / deadband / max
gyroFactor=0.273*math.pi/180 *300/1024;  --For degree per second unit
gyroFactor = 0; --disable stabilization for now
kick.ankleImuParamX={0.6,-0.3*gyroFactor, 0, 25*math.pi/180};
kick.kneeImuParamX={0.6,-1.2*gyroFactor, 0, 25*math.pi/180};
kick.ankleImuParamY={0.9,-0.7*gyroFactor, 0, 25*math.pi/180};
kick.hipImuParamY={0.9,-0.3*gyroFactor, 0, 25*math.pi/180};
kick.armImuParamX={0.3,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
kick.armImuParamY={0.3,-10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--Kick arm pose
kick.qLArm = math.pi/180*vector.new({110, 12, -0, -40});
kick.qRArm = math.pi/180*vector.new({110, -12, 0, 40});
--How much should we swing the arm? (smaller value = larger swing)
kick.armGain= 0.10; 

--Stiffness
kick.hardnessArm=.3;
kick.hardnessLeg=1;

kick.def={};

kick.def["kickForwardLeft"]={
   supportLeg = 1, --Right support
   def = {
        {1, .6, {0,0,0}          }, --Stabilize
        {1, 0.6, {0,-0.13,0}          }, --COM slide
        {2, 0.3, {0,-0.13,0} , {-0,-0,0}, 0.15 , 0*math.pi/180},--Lifting
        {2, 0.3, {0,-0.13,0} , {-0.20,-0.07,0}, 0.15 , 20*math.pi/180},--Lifting
        {2, 0.3, {0,-0.13,0} , {0.55,0,0},  0.15 , -10*math.pi/180},--Kicking
        {2, 0.6, {0,-0.13,0} , {-0.36,0.07,0}, 0, 0 }, --Landing
        {1, 0.6, {0.00,-0.0, 0}},--COM slide
        {6, 0.6, {0.00,-0.0, 0}},--Stabilize
   },
};

kick.def["kickForwardRight"]={
  supportLeg = 0,
  def = {
        {1, .6, {0,0,0}          }, --Stabilize
        {1, 0.6, {0,0.13,0}          }, --COM slide
        {3, 0.3, {0,0.13,0} , {-0.0,0,0}, 0.15 , 0*math.pi/180}, --Lifting
        {3, 0.3, {0,0.13,0} , {-0.20,0.07,0}, 0.15 , 20*math.pi/180}, --Lifting
        {3, 0.3, {0,0.13,0} , {0.55,0,0},  0.15 , -10*math.pi/180}, --Kicking
        {3, 0.6, {0,0.13,0} , {-0.36,-0.07,0}, 0, 0 }, --Landing
        {1, 0.6, {0.00, 0.0, 0}},--COM slide
        {6, 0.6, {0.00, 0.0, 0}},--Stabilize
  },
}
