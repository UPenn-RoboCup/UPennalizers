module(..., package.seeall);

---------------------------------------------
-- Automatically generated calibration data
---------------------------------------------
cal={}

--Initial values for each robots

cal["betty"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 0,
  armBias={0,0,0,0,0,0},
  pid = 1,
};

cal["linus"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 0,
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["lucy"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 0,
  armBias=vector.new({0,-10,10,0,0,26})*math.pi/180, 
  pid = 1, --NEW FIRMWARE
};

cal["scarface"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 0,
  armBias={0,0,0,0,0,0},
  pid = 1,
};

cal["felix"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 4*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["hokie"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,10*math.pi/180,0,0,-6*math.pi/180,0},
  pid = 1, --NEW FIRMWARE
};

cal["jiminy"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 4*math.pi/180;
  armBias={0,6*math.pi/180,0,
           0,-4*math.pi/180,0},
  pid = 1, --NEW FIRMWARE
};

cal["sally"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 0;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};





















cal["darwin1"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["darwin2"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["darwin3"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["darwin4"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["darwin5"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["darwin6"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["darwin7"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 4*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["darwin8"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["darwin9"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};

cal["darwin10"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchBiasComp = 0*math.pi/180;
  armBias={0,0,0,0,0,0},
  pid = 1, --NEW FIRMWARE
};



------------------------------------------------------------
--Auto-appended calibration settings
------------------------------------------------------------
--Cleaned up on 06/28/2012 @ GRASP

-- Updated date: Mon Jun 18 21:12:59 2012
cal["lucy"].servoBias={19,4,10,0,21,-13,-15,7,-20,2,-21,-4,};
cal["lucy"].footXComp=-0.003;
cal["lucy"].kickXComp=0.000;

-- Updated date: Tue Jun 19 09:42:59 2012
cal["sally"].servoBias={-33,-22,-6,0,29,-8,0,0,-4,0,0,0,};
cal["sally"].footXComp=0.005;
cal["sally"].kickXComp=0.005;

-- Updated date: Tue Jun 19 11:39:30 2012
cal["linus"].servoBias={21,-16,37,-13,-14,-3,-31,-4,-30,10,0,16,};
cal["linus"].footXComp=0.003;
cal["linus"].kickXComp=0.005;

-- Updated date: Wed Jun 20 17:21:03 2012
cal["hokie"].servoBias={0,-5,-17,-13,-1,-26,0,2,34,-17,-20,5,};
cal["hokie"].footXComp=0.002;
cal["hokie"].kickXComp=0.000;

-- Updated date: Wed Jun 20 18:11:31 2012
cal["felix"].servoBias={12,-2,37,-31,7,-7,-6,30,-33,7,3,20,};
cal["felix"].footXComp=0.003;
cal["felix"].kickXComp=0.005;

-- Updated date: Thu Jun 21 16:57:53 2012
cal["betty"].servoBias={8,-10,21,-77,29,-11,-5,6,-31,-16,-34,6,};
cal["betty"].footXComp=0.000;
cal["betty"].kickXComp=0.000;

-- Updated date: Fri Jun 22 12:33:40 2012
cal["scarface"].servoBias={0,0,-1,20,-1,3,-14,0,0,-8,20,-24,};
cal["scarface"].footXComp=0.003;
cal["scarface"].kickXComp=0.005;

-- Updated date: Fri Jun 22 23:36:53 2012
cal["jiminy"].servoBias={15,0,41,12,-22,4,-20,0,-23,-8,18,-8,};
cal["jiminy"].footXComp=0.009;
cal["jiminy"].kickXComp=0.000;

-- Updated date: Sat Jun 23 08:52:33 2012
cal["linus"].servoBias={21,-16,37,-13,-8,-3,-31,-4,-30,10,0,16,};
cal["linus"].footXComp=0.003;
cal["linus"].kickXComp=0.005;

-- Updated date: Sat Jun 23 08:07:03 2012
cal["betty"].servoBias={8,-10,21,-67,29,-11,-5,6,-31,-24,-34,6,};
cal["betty"].footXComp=0.006;
cal["betty"].kickXComp=0.000;

-- Updated date: Fri Jun 22 11:51:21 2012
cal["sally"].servoBias={-33,-22,-6,0,29,-8,0,0,-4,0,0,0,};
cal["sally"].footXComp=0.005;
cal["sally"].kickXComp=0.000;
