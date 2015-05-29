module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters for NewWalk

walk = {};

walk.testing = true;
----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.09,0.20};
walk.stanceLimitA={-0*math.pi/180,40*math.pi/180};

walk.velLimitX={-.04,.05};
walk.velLimitY={-.02,.02};
walk.velLimitA={-.4,.4};
walk.velDelta={0.02,0.02,0.15} 

--Foot overlap check variables
walk.footSizeX = {-0.04,0.08};
walk.stanceLimitMarginY = 0.035;
--walk.stanceLimitA ={-20*math.pi/180, 40*math.pi/180};

---------------------------------------------
-- Odometry values
--------------------------------------------
walk.odomScale = {0.79, 0.97567, 0.75}; --Old X: 0.782

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.315; 
walk.bodyTilt=0*math.pi/180; 
walk.footX= 0.0; 
walk.footY = 0.0500;
walk.supportX = 0.018;
walk.qLArm = math.pi/180*vector.new({105, 12, -85, -30});
walk.qRArm = math.pi/180*vector.new({105, -12, 85, 30});
walk.qLArmKick = math.pi/180*vector.new({105, 18, -85, -30});
walk.qRArmKick = math.pi/180*vector.new({105, -18, 85, 30});

walk.hardnessSupport = .7;
walk.hardnessSwing = .5;
walk.hardnessArm=.3;
---------------------------------------------
-- Gait parameters
---------------------------------------------
walk.tStep = 0.26;
walk.tZmp = 0.17;
walk.supportY = 0.002;
walk.stepHeight = 0.020;
walk.phSingle={0.02,0.98};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation = 1.5*math.pi/180;
walk.ankleMod = vector.new({-1,0})/0.12 * 0*math.pi/180; --({-1,0})/0.12 * 10*math.pi/180;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------

--ALPHA     : Changes HOW QUICKLY compensating torque is applied
--GAIN      : Changes HOW MUCH compensating torque is applied
--DEADBAND  : The range of values for which torque WILL NOT be applied 

walk.gyroFactor = 0.001; --In units of degrees per second

--Front to back compensation
walk.ankleImuParamX={0.11, -0.50*walk.gyroFactor,
        1*math.pi/180, 5*math.pi/180};
walk.kneeImuParamX={0.1, -0.3*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};

--Side to side compensation
walk.ankleImuParamY={0.22, -1.9*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};
walk.hipImuParamY={0.1, -0.3*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};

--Arm compensation
walk.armImuParamX={0.1, 0*walk.gyroFactor,
        1*math.pi/180, 5*math.pi/180};
walk.armImuParamY={0.1, 0*walk.gyroFactor,
        .5*math.pi/180, 5*math.pi/180};

--------------------------------------------
-- Support point modulation values
--------------------------------------------
walk.supportFront = 0.01; --Lean front when walking fast forward
walk.supportBack = -0.02; --Lean back when walking backward
walk.supportSideX = -0.01; --Lean back when sidestepping
walk.supportSideY = 0.02; --Lean sideways when sidestepping

--------------------------------------------
-- WalkKick parameters
--------------------------------------------
walk.walkKickDef={}

--tStep stepType supportLeg stepHeight SupportMod shiftFactor footPos1 footPos2


--[[
--Original walkkicks
walk.walkKickDef["FrontLeft"]={
  {0.30, 1, 0, 0.020 , {-0.02,0}, 0.6, {0.06,0,0} },
  {0.45, 2, 1, 0.035 , {-0.01,-0.01}, 0.5, {0.10,0,0}, {0.06,0,0} },
  {0.30, 1, 0, 0.020 , {0,0}, 0.5, {0.04,0,0} },
}
walk.walkKickDef["FrontRight"]={
  {0.30, 1, 1, 0.020 , {-0.02,0}, 0.4, {0.06,0,0} },
  {0.45, 2, 0, 0.035 , {-0.01,0.01}, 0.5,  {0.10,0,0}, {0.06,0,0} },
  {0.30, 1, 1, 0.020 , {0,0}, 0.5, {0.04,0,0} },
}
--]]


--Temporary tuned-down walkkick
walk.walkKickDef["FrontLeft"]={
  {0.30, 1, 0, 0.020 , {-0.02,0}, 0.6, {0.04,0,0} },
  {0.45, 2, 1, 0.045 , {-0.01,-0.01}, 0.5, {0.08,0,0}, {0.04,0,0} },
  {0.30, 1, 0, 0.020 , {0,0}, 0.5, {0.0,0,0} },
}
walk.walkKickDef["FrontRight"]={
  {0.30, 1, 1, 0.020 , {-0.02,0}, 0.4, {0.04,0,0} },
  {0.45, 2, 0, 0.045 , {-0.01,0.01}, 0.5,  {0.08,0,0}, {0.04,0,0} },
  {0.30, 1, 1, 0.020 , {0,0}, 0.5, {0.0,0,0} },
}











walk.walkKickDef["SideLeft"]={
  {0.30, 1, 1, 0.025 , {0,0}, 0.4, {0.0,0.04,10*math.pi/180} },
  {0.35, 3, 0, 0.040 , {0.01,0.01}, 0.5,  
		{0.06,-0.05,-20*math.pi/180},{0.09,0.005,10*math.pi/180}},
  {0.35, 1, 1, 0.025 , {0.01,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.30, 1, 0, 0.025 , {0,0}, 0.6, {0.0,-0.04,-10*math.pi/180} },
  {0.35, 3, 1, 0.040 , {0.01,-0.01},0.5,   
		{0.06,0.05,20*math.pi/180},{0.09,-0.005,-10*math.pi/180}},
  {0.35, 1, 0, 0.025 , {0.01,0},0.5,  {0,0,0} },
}


walk.walkKickPh=0.5;

--------------------------------------------
-- Robot - specific calibration parameters
--------------------------------------------

walk.kickXComp = 0;
walk.supportCompL = {0,0,0};
walk.supportCompR = {0,0,0};

--Shift torso a bit to front when kicking
walk.kickXComp = -0.01;







--ZMP-preview step definitions
zmpstep = {};

zmpstep.bodyHeight = walk.bodyHeight;
zmpstep.bodyTilt = walk.bodyTilt;
zmpstep.tZmp = walk.tZmp;

zmpstep.stepHeight = walk.stepHeight;
zmpstep.phSingle=walk.phSingle;
zmpstep.hipRollCompensation = walk.hipRollCompensation;
zmpstep.supportX = walk.supportX;
zmpstep.supportY = 0.0;


zmpstep.motionDef={};


zmpstep.motionDef["nonstop_kick_left"]={
  support_start = 0, --Left support
  stepDef={
    {2, {0,0,0},   {0,0},0.20}, --DS step
    {0, {0.06,0,0},{0,0},0.36}, --LS step
    {2, {0,0,0},   {0,-0.02},0.20}, --DS step

    {1, {-0.060,-0.02,0}    ,{0.01,-0.01},0.2,1}, --RS step, lifting
    {1, {0.22,0,0}     ,{-0.01,-0.02},0.1,5}, --RS step  kicking
    {1, {0,0,0}     ,{-0.01,-0.025},0.35,5}, --RS step  waiting
    {1, {-0.06,0.02,0} ,{-0.01,-0.01},0.2,3}, --RS step  returning
    {1, {0.0,0.0,0}      ,{0.01,-0.0},0.2,4}, --RS step  landing

    {2, {0,0,0},   {0,0},0.10}, --DS step
    {0, {0.06,0,0},{0,0},0.26}, --LS step
---------------------------------------------
    {1, {0,0,0},{0,0},0.26,9}, --RS step
    {0, {0,0,0},{0,0},0.26}, --RS step
  },
  support_end = 1, --should be followed by RS step
}

zmpstep.motionDef["nonstop_kick_right"]={
  support_start = 1, --Right support
  stepDef={
    {2, {0,0,0},{0,0},0.20}, --DS step
    {1, {0.06,0.0,0},{0,0},0.36}, --RS step
    {2, {0,0,0},{0,0.02},0.20}, --DS step

    {0, {-0.06,0.02,0}      ,{0.01,0.01},0.2,1}, --LS step, lifting
    {0, {0.22,0,0}      ,{-0.01,0.02},0.1,5}, --LS step  kicking
    {0, {0,0,0}         ,{-0.01,0.025},0.35,5}, --LS step  waiting
    {0, {-0.06,-0.02,0}  ,{-0.01,0.01},0.2,3}, --LS step  returning
    {0, {0.0,0,0}       ,{0.01,0.0},0.2,4}, --LS step  landing

    {2, {0,0,0},{0,0},0.10}, --DS step
    {1, {0.06,0.0,0},{0,0},0.26}, --RS step
---------------------------------------------
    {0, {0.00,0,0},{0,0},0.26,9}, --LS step
    {1, {0.00,0,0},{0,0},0.26}, --RS step
  },
  support_end = 0, --should be followed by LS step
}

zmpstep.kickHeight = 0.10;
zmpstep.kickHeight = 0.08;
zmpstep.kickAngle0 = 10*math.pi/180;
zmpstep.kickAngle1 = -10*math.pi/180;


zmpstep.params = true;
zmpstep.param_k1_px={-820.347751,-308.304742,-34.224553}
zmpstep.param_a={
  {1.000000,0.010000,0.000050},
  {0.000000,1.000000,0.010000},
  {0.000000,0.000000,1.000000},
}
zmpstep.param_b={0.000000,0.000050,0.010000,0.010000}

zmpstep.param_k1={
    194.394360,124.167569,72.242030,34.132865,6.438235,
    -13.421231,-27.400379,-36.979884,-43.280466,-47.149639,
    -49.227601,-49.997274,-49.822312,-48.975960,-47.662962,
    -46.036199,-44.209316,-42.266304,-40.268770,-38.261453,
    -36.276404,-34.336156,-32.456119,-30.646402,-28.913182,
    -27.259743,-25.687257,-24.195373,-22.782661,-21.446940,
    -20.185529,-18.995427,-17.873452,-16.816337,-15.820804,
    -14.883617,-14.001614,-13.171736,-12.391039,-11.656708,
    -10.966057,-10.316538,-9.705730,-9.131346,-8.591223,
    -8.083323,-7.605720,-7.156605,-6.734269,-6.337109,
    -5.963615,-5.612365,-5.282025,-4.971341,-4.679131,
    -4.404288,-4.145770,-3.902597,-3.673851,-3.458666,
    -3.256230,-3.065781,-2.886601,-2.718016,-2.559394,
    -2.410139,-2.269693,-2.137529,-2.013155,-1.896106,
    -1.785946,-1.682266,-1.584679,-1.492824,-1.406360,
    -1.324967,-1.248345,-1.176211,-1.108297,-1.044356,
    -0.984150,-0.927460,-0.874076,-0.823805,-0.776460,
    -0.731870,-0.689871,-0.650310,-0.613042,-0.577933,
    -0.544855,-0.513686,-0.484313,-0.456631,-0.430538,
    -0.405940,-0.382747,-0.360875,-0.340245,-0.320781,
    -0.302414,-0.285076,-0.268703,-0.253237,-0.238621,
    -0.224801,-0.211726,-0.199349,-0.187623,-0.176506,
    -0.165954,-0.155930,-0.146396,-0.137314,-0.128652,
    -0.120375,-0.112453,-0.104854,-0.097550,-0.090513,
    -0.083715,-0.077132,-0.070740,-0.064516,-0.058441,
    -0.052495,-0.046665,-0.040940,-0.035313,-0.029785,
    -0.024367,-0.019080,-0.013960,-0.009066,-0.004482,
    -0.000328,0.003226,0.005950,0.007528,0.007534,
    0.005398,0.000358,-0.008605,-0.022840,-0.044140,
    -0.074877,-0.118188,-0.178222,-0.260452,-0.372105,
    }
