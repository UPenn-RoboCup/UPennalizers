module(..., package.seeall);
require('vector')

--Kick parameters

kick={};

--Imu feedback parameters, alpha / gain / deadband / max
gyroFactor=0.273*math.pi/180 *300/1024;  --For degree per second unit
kick.ankleImuParamX={0.6,0.3*gyroFactor, 0, 25*math.pi/180};
kick.kneeImuParamX={0.6,1.2*gyroFactor, 0, 25*math.pi/180};
kick.ankleImuParamY={0.9,0.7*gyroFactor, 0, 25*math.pi/180};
kick.hipImuParamY={0.9,0.3*gyroFactor, 0, 25*math.pi/180};
kick.armImuParamX={0.3,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
kick.armImuParamY={0.3,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--Less feedback values
kick.ankleImuParamX={0.6,0.3*gyroFactor, 0, 25*math.pi/180};
kick.kneeImuParamX={0.6,0.7*gyroFactor, 0, 25*math.pi/180};

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
-- {7, duration, torsoTarget, LArmTarget,RArmTarget, 
--       bodyHeightTarget, bodyRollTarget, bodyTiltTarget} -- General motion
-----------------------------------------------------------------------------

kick.def={};

kick.def["kickForwardLeft"]={
   supportLeg = 1, --Right support
   def = {
     {1, 0.6, {-0.01,-0.05,0} , 0.303          }, --COM slide
     {2, 0.3, {-0.01,-0.05,0} , {-0.06,-0.02,0}, 0.05 , 0}, --Lifting
     {2, 0.1, {-0.01, -0.05,0} , {-0.06,0,0}, 0.10 , 40*math.pi/180}, --Lifting
     {4, 0.2, {-0.01,-0.05,0} , {0.30,0,0},  0.07 , 0*math.pi/180}, --Kicking
     {2, 0.6, {-0.01,-0.05,0} , {-0.18,0.02,0}, 0, 0 }, --Landing
     {1, 0.6, {-0.00,-0.02, 0}},--COM slide
     {6, 0.6, {0.000, 0.0, 0}},--Stabilize
   },
};

kick.def["kickForwardRight"]={
  supportLeg = 0,
  def = {
    {1, 0.6, {-0.01 ,0.05,0},0.303}, --COM slide
    {3, 0.3, {-0.01 ,0.05,0} , {-0.06, 0.02, 0}, 0.05 , 0},
    {3, 0.1, {-0.01 ,0.05,0} , {-0.06, 0.0, 0}, 0.10 , 40*math.pi/180}, 
    {5, 0.2, {-0.01 ,0.05,0} , {0.30, 0, 0},  0.07 , 0*math.pi/180}, --Kicking
    {3, 0.6, {-0.01 ,0.05,0} , {-0.18,-0.02,0}, 0, 0 }, --Landing
    {1, 0.6, {-0.00, 0.02, 0}},--COM slide
    {6, 0.6, {0.000, 0.0, 0}},--Stabilize
  },
}






--Less powerful kick for webots

kick.def["kickForwardLeft"]={
   supportLeg = 1, --Right support
   def = {
     {1, 0.6, {-0.01,-0.05,0} , 0.303          }, --COM slide
     {2, 0.3, {-0.01,-0.05,0} , {-0.06,-0.02,0}, 0.05 , 0}, --Lifting
     {2, 0.1, {-0.01, -0.05,0} , {-0.06,0,0}, 0.10 , 40*math.pi/180}, --Lifting
     {4, 0.4, {-0.01,-0.05,0} , {0.30,0,0},  0.07 , 0*math.pi/180}, --Kicking
     {2, 0.6, {-0.01,-0.05,0} , {-0.18,0.02,0}, 0, 0 }, --Landing
     {1, 0.6, {-0.00,-0.02, 0}},--COM slide
     {6, 0.6, {0.000, 0.0, 0}},--Stabilize
   },
};

kick.def["kickForwardRight"]={
  supportLeg = 0,
  def = {
    {1, 0.6, {-0.01 ,0.05,0},0.303}, --COM slide
    {3, 0.3, {-0.01 ,0.05,0} , {-0.06, 0.02, 0}, 0.05 , 0},
    {3, 0.1, {-0.01 ,0.05,0} , {-0.06, 0.0, 0}, 0.10 , 40*math.pi/180}, 
    {5, 0.4, {-0.01 ,0.05,0} , {0.30, 0, 0},  0.07 , 0*math.pi/180}, --Kicking
    {3, 0.6, {-0.01 ,0.05,0} , {-0.18,-0.02,0}, 0, 0 }, --Landing
    {1, 0.6, {-0.00, 0.02, 0}},--COM slide
    {6, 0.6, {0.000, 0.0, 0}},--Stabilize
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

kick.def["PassForwardLeft"]={
   supportLeg = 1, --Right support
   def = {
     {1, 0.6, {-0.01,-0.05,0} , 0.303          }, --COM slide
     {2, 0.3, {-0.01,-0.05,0} , {-0.06,-0.02,0}, 0.05 , 0}, --Lifting
     {2, 0.1, {-0.01, -0.05,0} , {-0.06,0,0}, 0.05 , 40*math.pi/180}, --Lifting
     {2, 0.5, {-0.01,-0.05,0} , {0.30,0,0},  0.05 , 0*math.pi/180}, --Kicking
     {2, 0.6, {-0.01,-0.05,0} , {-0.18,0.02,0}, 0, 0 }, --Landing
     {1, 0.6, {-0.00,-0.02, 0}},--COM slide
     {6, 0.6, {0.000, 0.0, 0}},--Stabilize
   },
};

kick.def["PassForwardRight"]={
  supportLeg = 0,
  def = {
    {1, 0.6, {-0.01 ,0.05,0},0.303}, --COM slide
    {3, 0.3, {-0.01 ,0.05,0} , {-0.06, 0.02, 0}, 0.05 , 0},
    {3, 0.1, {-0.01 ,0.05,0} , {-0.06, 0.0, 0}, 0.05 , 40*math.pi/180}, 
    {3, 0.5, {-0.01 ,0.05,0} , {0.30, 0, 0},  0.05 , 0*math.pi/180}, --Kicking
    {3, 0.6, {-0.01 ,0.05,0} , {-0.18,-0.02,0}, 0, 0 }, --Landing
    {1, 0.6, {-0.00, 0.02, 0}},--COM slide
    {6, 0.6, {0.000, 0.0, 0}},--Stabilize
  },
}

kick.def["PassForwardLeft2"]={
   supportLeg = 1, --Right support
   def = {
     {1, 0.6, {-0.01,-0.05,0} , 0.303          }, --COM slide
     {2, 0.3, {-0.01,-0.05,0} , {-0.06,-0.02,0}, 0.05 , 0}, --Lifting
     {2, 0.1, {-0.01, -0.05,0} , {-0.06,0,0}, 0.05 , 40*math.pi/180}, --Lifting
     {2, 0.9, {-0.01,-0.05,0} , {0.30,0,0},  0.05 , 0*math.pi/180}, --Kicking
     {2, 0.6, {-0.01,-0.05,0} , {-0.18,0.02,0}, 0, 0 }, --Landing
     {1, 0.6, {-0.00,-0.02, 0}},--COM slide
     {6, 0.6, {0.000, 0.0, 0}},--Stabilize
   },
};

kick.def["PassForwardRight2"]={
  supportLeg = 0,
  def = {
    {1, 0.6, {-0.01 ,0.05,0},0.303}, --COM slide
    {3, 0.3, {-0.01 ,0.05,0} , {-0.06, 0.02, 0}, 0.05 , 0},
    {3, 0.1, {-0.01 ,0.05,0} , {-0.06, 0.0, 0}, 0.05 , 40*math.pi/180}, 
    {3, 0.9, {-0.01 ,0.05,0} , {0.30, 0, 0},  0.05 , 0*math.pi/180}, --Kicking
    {3, 0.6, {-0.01 ,0.05,0} , {-0.18,-0.02,0}, 0, 0 }, --Landing
    {1, 0.6, {-0.00, 0.02, 0}},--COM slide
    {6, 0.6, {0.000, 0.0, 0}},--Stabilize
  },
}










------------------------------------------------------
-- Upper body motion
-------------------------------------------------------

--Standard arm pose
qLArmA=math.pi/180*vector.new({135,22,-135});
qRArmA=math.pi/180*vector.new({135,-22,-135});

--Side Swing back
qLArmB=math.pi/180*vector.new({55,90,-135});
qRArmB=math.pi/180*vector.new({55,-90,-135});

--Side Swing forward
qLArmC=math.pi/180*vector.new({55,90,-75});
qRArmC=math.pi/180*vector.new({55,-90,-75});

--Uppercut forward
qLArmD=math.pi/180*vector.new({-20,5,-90});
qRArmD=math.pi/180*vector.new({-20,-5,-90});

kick.def["punchStraightleft"]={
  supportLeg = 1,
  def = {
    {7, 0.4, {-0.02,0,45*math.pi/180},qLArmB,qRArmA},
    {7, 0.2, {0.02,0,-60*math.pi/180},qLArmC,qRArmA},
    {7, 0.4, {0,0,0},qLArmA,qRArmA},
  }
}

kick.def["punchStraightRight"]={
  supportLeg = 0,
  def = {
    {7, 0.4, {-0.02,0,-45*math.pi/180},qLArmA,qRArmB},
    {7, 0.2, {0.02,0,60*math.pi/180},qLArmA,qRArmC},
    {7, 0.4, {0,0,0},0,0,0,qLArmA,qRArmA},
  }
}





--Pickup

--Standard arm pose
qLArmA=math.pi/180*vector.new({90,20,-40});
qRArmA=math.pi/180*vector.new({90,-20,-40});

--Gripper open
qLArmB=math.pi/180*vector.new({30,8,10});
qRArmB=math.pi/180*vector.new({30,-8,10});

--Gripper close
qLArmC=math.pi/180*vector.new({30,8,-25});
qRArmC=math.pi/180*vector.new({30,-8,-25});

--WindUp
qLArmD=math.pi/180*vector.new({-90,0,-90});
qRArmD=math.pi/180*vector.new({-90,0,-90});

--Throw
qLArmE=math.pi/180*vector.new({40,0,10});
qRArmE=math.pi/180*vector.new({40,0,10});

--Two-arm pickup testing 
--Arm open
qLArmF=math.pi/180*vector.new({30,8,0});
qRArmF=math.pi/180*vector.new({30,-8,0});

--Gripper close
qLArmG=math.pi/180*vector.new({30,-20,0});
qRArmG=math.pi/180*vector.new({30,20,0});

--PickupLeft
kick.def["pickupLeft"]={
  supportLeg = 1,
  def = {
    {7, 0.5, {0.05,0,-30*math.pi/180},qLArmB,qRArmA,0.295},
    {7, 0.5, {0.06,0,-30*math.pi/180},qLArmB,qRArmA,0.22,0,50*math.pi/180},
    {7, 0.2, {0.06,0,-30*math.pi/180},qLArmC,qRArmA},
    {7, 1.0, {0,0,0*math.pi/180},qLArmA,qRArmA,0.295,0,20*math.pi/180},
  }
}
kick.def["pickupRight"]={
  supportLeg = 1,
  def = {
    {7, 0.5, {0.05,0,30*math.pi/180},qLArmA,qRArmB,0.295,0,30*math.pi/180},
    {7, 1,0, {0.06,0,30*math.pi/180},qLArmA,qRArmB,0.22,0,50*math.pi/180},
    {7, 0.2, {0.06,0,30*math.pi/180},qLArmA,qRArmC},
    {7, 1.0, {0,0,0*math.pi/180},qLArmA,qRArmA,0.295,0,20*math.pi/180},
  }
}

--ThrowLeft
kick.def["throwLeft"]={
  supportLeg = 1,
  def = {
    {7, 0.7, {0.02,0,0*math.pi/180},qLArmD,qRArmA,0.25,0,-10*math.pi/180},
    {7, 0.2, {0.02,0,0*math.pi/180},qLArmE,qRArmA},
    {7, 1.0, {0,0,0*math.pi/180},qLArmA,qRArmA,0.295,0,20*math.pi/180},
  }
}
kick.def["throwRight"]={
  supportLeg = 1,
  def = {
    {7, 0.7, {0.02,0,0*math.pi/180},qLArmA,qRArmD,0.25,0,-10*math.pi/180},
    {7, 0.2, {0.02,0,0*math.pi/180},qLArmA,qRArmE},
    {7, 1.0, {0,0,0*math.pi/180},qLArmA,qRArmA,0.295,0,20*math.pi/180},
  }
}

--pickupCenter
kick.def["pickupCenter"]={
  supportLeg = 1,
  def = {
    {7, 0.5, {0.05,0,0*math.pi/180},qLArmF,qRArmF,0.295},
    {7, 0.5, {0.07,0,0*math.pi/180},qLArmF,qRArmF,0.20,0,50*math.pi/180},
    {7, 0.2, {0.07,0,0*math.pi/180},qLArmG,qRArmG},
    {7, 1.0, {0,0,0*math.pi/180},qLArmG,qRArmG,0.295,0,20*math.pi/180},
  }
}


--for testing
--[[
kick.def["kickForwardLeft"]=kick.def["pickupLeft"];
kick.def["kickForwardRight"]=kick.def["throwLeft"];
kick.def["kickForwardLeft"]=kick.def["pickupCenter"];
--]]
