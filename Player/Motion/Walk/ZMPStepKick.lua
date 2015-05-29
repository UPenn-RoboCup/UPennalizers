module(..., package.seeall);

------------------------------------------------
-- This function uses ZMP preview algorithm
-- To make robot a number of pre-defined steps
-- 2013/2 SJ
------------------------------------------------

require('Body')
require('Kinematics')
require('Config');
require('vector')
require('mcm')
require('unix')
require('util')

local matrix = require('matrix_zmp')

--Stance parameters
bodyHeight1 = Config.zmpstep.bodyHeight;
bodyHeight0 = Config.walk.bodyHeight;
bodyHeight = Config.walk.bodyHeight;

bodyTilt=Config.zmpstep.bodyTilt or 0;

footX = Config.walk.footX or 0;
footY = Config.walk.footY;

qLArm=Config.walk.qLArm;
qRArm=Config.walk.qRArm;
qLArm0={qLArm[1],qLArm[2]};
qRArm0={qRArm[1],qRArm[2]};
hardnessSupport = Config.walk.hardnessSupport or 0.7;
hardnessSwing = Config.walk.hardnessSwing or 0.5;
hardnessArm = Config.walk.hardnessArm or 0.2;

--Gait parameters
tZmp = Config.zmpstep.tZmp;
supportX = Config.zmpstep.supportX;
supportY = Config.zmpstep.supportY;
stepHeight = Config.zmpstep.stepHeight;
ph1Single = Config.zmpstep.phSingle[1];
ph2Single = Config.zmpstep.phSingle[2];

kickHeight = Config.zmpstep.kickHeight or 0.07;
kickAngle0 = Config.zmpstep.kickAngle0 or 20*math.pi/180;
kickAngle1 = Config.zmpstep.kickAngle1 or 0;


--Compensation parameters
hipRollCompensation = Config.zmpstep.hipRollCompensation;

--Gyro stabilization parameters
ankleImuParamX = Config.walk.ankleImuParamX;
ankleImuParamY = Config.walk.ankleImuParamY;
kneeImuParamX = Config.walk.kneeImuParamX;
hipImuParamY = Config.walk.hipImuParamY;
armImuParamX = Config.walk.armImuParamX;
armImuParamY = Config.walk.armImuParamY;

----------------------------------------------------------
-- Walk state variables
----------------------------------------------------------

uTorso = vector.new({0, 0, 0});
uLeft = vector.new({-supportX, footY, 0});
uRight = vector.new({-supportX, -footY, 0});

--Future positions (for preview control)
uTorsoF = vector.new({0, 0, 0});
uLeftF = vector.new({-supportX, footY, 0});
uRightF = vector.new({-supportX, -footY, 0});
uSupportF = vector.new({0,0,0});

supportLegF = 2; --DS

pLLeg = vector.new({-supportX, footY, 0, 0,0,0});
pRLeg = vector.new({-supportX, -footY, 0, 0,0,0});
pTorso = vector.new({supportX, 0, bodyHeight, 0,bodyTilt,0});

--Gyro stabilization variables
ankleShift = vector.new({0, 0});
kneeShift = 0;
hipShift = vector.new({0,0});
armShift = vector.new({0, 0});

active = false;
t0 = Body.get_time();
t1 = Body.get_time();
ph = 1;

--ZMP preview parameters
timeStep = 0.010; --40ms
tPreview = 1.50; --preview interval, 1000ms
xdot_initial = {0,0};

nPreview = tPreview / timeStep; 
r_q = 10^-6; --balacing parameter for optimization
preload_num = nPreview-1;

--Zmp preview variables
x={}
zmpx={};zmpy={};
uLeftTargets={};
uRightTargets={};
supportLegs={};
zaLefts={};
zaRights={};
zmpMods={}
phs={};
stepTypes={};

motionDef = Config.zmpstep.motionDef;
stepdef_current={}
uLeftI=vector.new({-supportX,footY,0});
uRightI=vector.new({-supportX,-footY,0});
uTorsoI=uTorso;
step_queue_count = 0;
step_queue_t0 = 0;
support_end = 0;

initial_update_needed = true;

function set_kick_type(kickname)
print("kick name:",kickname)
  stepdef_current = motionDef[kickname].stepDef;
  support_start = motionDef[kickname].support_start;
  support_end = motionDef[kickname].support_end;
  return support_start, support_end;
end

------------------------------------------------------

--Stepdef definition
--{
--   Supportfoot relstep zmpmod duration steptype
--}
--Step queue definition
--{
-- {uLeft, uRight, supportLeg, duration, zaLeft, zaRight, zmp_mod steptype}
--}


function generate_step_queue(stepdef)
  local step_queue = {};

  local uLeft=vector.new({uLeftI[1],uLeftI[2],uLeftI[3]});
  local uRight=vector.new({uRightI[1],uRightI[2],uRightI[3]});

  local zaLeft=vector.new({0,0});
  local zaRight=vector.new({0,0});

  for i=1, #stepdef do
    local supportLeg = stepdef[i][1];
    if supportLeg==0 then --LS
      uRight= util.pose_global(stepdef[i][2],uRight);
--      zaRight = zaRight + vector.new(stepdef[i][3]);
    elseif supportLeg==1 then
      uLeft= util.pose_global(stepdef[i][2],uLeft);
--      zaLeft = zaLeft + vector.new(stepdef[i][3]);
    elseif supportLeg ==2 then --DS
      --Body height change
--      zaRight = zaRight - vector.new(stepdef[i][3]);
--      zaLeft = zaLeft - vector.new(stepdef[i][3]);
    end
    step_queue[i]={};
    step_queue[i][1]= {uLeft[1],uLeft[2],uLeft[3]};
    step_queue[i][2]= {uRight[1],uRight[2],uRight[3]};
    step_queue[i][3] = supportLeg;
    step_queue[i][4]= stepdef[i][4]; --duration
    step_queue[i][5]= {zaLeft[1],zaLeft[2]};
    step_queue[i][6]= {zaRight[1],zaRight[2]};
    step_queue[i][7]= stepdef[i][3]; --zmp MOD
    step_queue[i][8]= stepdef[i][5] or 0; --step type
  end
  return step_queue;
end

function load_step_queue(steptype)
end

----------------------------------------------------------
-- End initialization 
----------------------------------------------------------

function precompute()
  ------------------------------------
  --We only need following parameters
  -- param_k1_px : 1x3
  -- param_k1 : 1xnPreview 
  -- param_a : 3x3
  -- param_b : 4x1

  if Config.zmpstep.params then
    param_k1_px = matrix:new({Config.zmpstep.param_k1_px});
    param_k1 = matrix:new({Config.zmpstep.param_k1});
    param_a = matrix:new(Config.zmpstep.param_a);
    param_b = matrix.transpose(matrix:new({Config.zmpstep.param_b}));

   print("param_k1_px:",matrix.size(param_k1_px))
   print("param_k1:",matrix.size(param_k1))
   print("param_a:",matrix.size(param_a))
   print("param_b:",matrix.size(param_b))

  else
    px={};pu0={};pu={};
    for i=1, nPreview do
      px[i]={1, i*timeStep, i*i*timeStep*timeStep/2 - tZmp*tZmp};
      pu0[i]=(1+3*(i-1)+3*(i-1)^2)/6 *timeStep^3 - timeStep*tZmp*tZmp;
      pu[i]={};
      for j=1, nPreview do pu[i][j]=0; end
      for j0=1,i do
        j = i+1-j0;
        pu[i][j]=pu0[i-j+1];
      end
    end
    param_pu = matrix:new(pu)
    param_px = matrix:new(px)
    param_pu_trans = matrix.transpose(param_pu);
    param_a=matrix {{1,timeStep,timeStep^2/2},{0,1,timeStep},{0,0,1}};
    param_b=matrix.transpose({{timeStep^3/6, timeStep^2/2, timeStep,timeStep}}) ;
    param_eye = matrix:new(nPreview,"I");
    param_k=-matrix.invert(
        (param_pu_trans * param_pu) + (r_q*param_eye)
        )* param_pu_trans ;
    k1={};
    k1[1]={};
    for i=1,nPreview do k1[1][i]=param_k[1][i];end
    param_k1 = matrix:new(k1);
    param_k1_px = param_k1 * param_px;

  -- param_k1_px : 1x3
  -- param_k1 : 1xnPreview 
  -- param_a : 3x3
  -- param_b : 4x1

   --print out zmp preview params
--   outfile=assert(io.open("zmpparams.lua","a+")); 
   outfile=assert(io.open("zmpparams.lua","w")); 
   data=''
   data=data..string.format("zmpstep.params = true;\n")
   data=data..string.format("zmpstep.param_k1_px={%f,%f,%f}\n",
     param_k1_px[1][1],param_k1_px[1][2],param_k1_px[1][3]);
   data=data..string.format("zmpstep.param_a={\n");
   for i=1,3 do
     data=data..string.format("  {%f,%f,%f},\n",
	param_a[i][1],param_a[i][2],param_a[i][3]);
   end
   data=data..string.format("}\n");
   data=data..string.format("zmpstep.param_b={%f,%f,%f,%f}\n",
     param_b[1][1],param_b[2][1],param_b[3][1],param_b[4][1]);
   data=data..string.format("zmpstep.param_k1={\n    ");
   
   for i=1,nPreview do
     data=data..string.format("%f,",param_k1[1][i]);
     if i%5==0 then 	data=data.."\n    " ;end
   end
   data=data..string.format("}\n");
   outfile:write(data);
   outfile:flush();
   outfile:close();
 end
end

function init_switch(uL,uR,uT,comdot)	
  uLeftI = uL;
  uRightI = uR;
  uTorsoI = uT;
  xdot_initial = comdot;
end

function stance_reset()
  --Quick hack: reset uTorso 
  --TODO: integrated odometry handling at Motion.lua


  --Clear current position variables
--  uTorso = {0,0,0};
--  uLeft = util.pose_global(vector.new({-supportX, footY, 0}),uTorso);
--  uRight = util.pose_global(vector.new({-supportX, -footY, 0}),uTorso);

  uLeft=vector.new({uLeftI[1],uLeftI[2],uLeftI[3]});
  uRight=vector.new({uRightI[1],uRightI[2],uRightI[3]});
  uTorso=vector.new({uTorsoI[1],uTorsoI[2],uTorsoI[3]});

  uLeft1, uLeft2 = uLeft, uLeft;
  uRight1, uRight2 = uRight, uRight;
  zaLeft1,zaRight1 = {0,0},{0,0};
  zaLeft0,zaRight0 = {0,0},{0,0};
  uSupport = uTorso;

  --Clear future trajectory variable
  uLeftF, uLeftF = uLeft, uLeft;
  uRightF, uRightF = uRight, uRight;
  supportLegF = 0;

  --Clear trajectory queue
  x=matrix:new{{uTorso[1],uTorso[2]},{0,0},{0,0}};
  for i=1,nPreview do
     zmpx[i]=uTorso[1];
     zmpy[i]=uTorso[2]; 
     supportLegs[i]=2; --double support
     uLeftTargets[i]={uLeft[1],uLeft[2],uLeft[3]};
     uRightTargets[i]={uRight[1],uRight[2],uRight[3]};
     zaLefts[i]={0,0};
     zaRights[i]={0,0};
     phs[i]= 0;
     stepTypes[i] = 0;
  end

  --reset step queue count
  step_queue_t0 = Body.get_time();
  step_queue_count = 0;
  ph = 1;

  bodyHeight = bodyHeight0; --Start from walking body height

  --Preload ZMP array to instantly switch from reactive walking
  step_queue = generate_step_queue(stepdef_current);
  preload_zmp_array();
  x[2][1] = xdot_initial[1];
  x[2][2] = xdot_initial[2];
end


--outfile = assert(io.open("walktraj2.txt","wb"));


function entry()
  print ("step entry")
  --SJ: now we always assume that we start walking with feet together
  --Because joint readings are not always available with darwins
  stance_reset();

  --Place arms in appropriate position at sides
  Body.set_larm_command(qLArm);
  Body.set_larm_hardness(hardnessArm);
  Body.set_rarm_command(qRArm);
  Body.set_rarm_hardness(hardnessArm);

  active = true; --Automatically start stepping
  initial_update_needed = true;

  --Init varables
  tStateUpdate = Body.get_time();  --last discrete update time
  t = Body.get_time();  	   --actual time
  torso0 = vector.new({uTorso[1],uTorso[2]});
  torso1 = vector.new({uTorso[1],uTorso[2]});

  mcm.set_walk_isStepping(1);


end

function preload_zmp_array()
  t = Body.get_time();
  time_offset = 0;
  for i=1,preload_num do
    t=t+timeStep;
    update_zmp_array(t);
    time_offset = time_offset+timeStep;
  end
end



function update_zmp_array(t)
  local new_step = false;
  if step_queue_count== 0 then
    step_queue_t0 = t;
    new_step = true;
  elseif step_queue_count == #step_queue then
    supportLegF = 3; --This means END state
  elseif t>step_queue_t0 + step_queue[step_queue_count][4] then
    step_queue_t0 = step_queue_t0 + step_queue[step_queue_count][4];
    new_step = true;
  end

  if new_step then
    step_queue_count = step_queue_count + 1;
    supportLegF = step_queue[step_queue_count][3];
    uLeftF = step_queue[step_queue_count][1];
    uRightF = step_queue[step_queue_count][2];
    zaLeftF = step_queue[step_queue_count][5];
    zaRightF = step_queue[step_queue_count][6];
    zmpModF = step_queue[step_queue_count][7];
    stepTypeF = step_queue[step_queue_count][8];

    if supportLegF == 0 then-- Left support
      uSupportF = util.pose_global(
	{supportX+zmpModF[1], supportY+zmpModF[2], 0}, uLeftF);
    elseif supportLegF == 1 then  -- Right support
      uSupportF = util.pose_global(
	{supportX+zmpModF[1], -supportY+zmpModF[2], 0}, uRightF);
    else --Double support
      uLeftSupport = util.pose_global(
	{supportX+zmpModF[1], supportY+zmpModF[2], 0}, uLeftF);
      uRightSupport = util.pose_global(
	{supportX+zmpModF[1], -supportY+zmpModF[2], 0}, uRightF);
      uSupportF = util.se2_interpolate(0.5,uLeftSupport,uRightSupport);
    end
  end

  if supportLegF ~=3 then 
    phF = (t-step_queue_t0)/step_queue[step_queue_count][4];
  else
    phF = 0;
  end
  
  table.remove(zmpx,1);
  table.remove(zmpy,1);
  table.remove(uLeftTargets,1);
  table.remove(uRightTargets,1);
  table.remove(supportLegs,1);
  table.remove(phs,1);
  table.remove(stepTypes,1);
  table.remove(zaLefts,1);
  table.remove(zaRights,1);

  table.insert(zmpx, uSupportF[1]);
  table.insert(zmpy, uSupportF[2]);
  table.insert(uLeftTargets, {uLeftF[1],uLeftF[2],uLeftF[3]});
  table.insert(uRightTargets,{uRightF[1],uRightF[2],uRightF[3]});
  table.insert(supportLegs, supportLegF);
  table.insert(phs, phF);
  table.insert(stepTypes, stepTypeF);
  table.insert(zaLefts,{zaLeftF[1],zaLeftF[2]});
  table.insert(zaRights,{zaRightF[1],zaRightF[2]});

end

function update()
  if (not active) then 
    t0 = Body.get_time();
    t1 = Body.get_time();
    return; 
  end

  t = Body.get_time();  	   --actual time
  --Run discrete state update
  while t>tStateUpdate or initial_update_needed do  	   
    initial_update_needed = false;
    torso0=vector.new({torso1[1],torso1[2]});
    torso1=update_discrete(tStateUpdate);
    if stepType==9 then --END state
      print("Step done!!!")
      active = false;
      --Transition handling
      walk.set_initial_stance(uLeft,uRight,uTorso,support_end);
      return "done";
    end
    --Advance discrete time
    tStateUpdate = tStateUpdate + timeStep;
  end

  --Interpolate torso position for discrete time steps
  torsoPh = ( t - (tStateUpdate-timeStep) ) / timeStep;
  torsoInterpolated = (1-torsoPh)*torso0 + torsoPh*torso1;

--  print(string.format("tS0:%.2f : %.2f tS1: %.2f ph:%.2f",
--	tStateUpdate-timeStep, 	t,tStateUpdate,torsoPh));

  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  xFoot, zFoot = foot_phase(ph);  
  zFoot = zFoot * stepHeight;
  aFoot = 0;

  if not active then
  elseif stepType>0 then
    if supportLeg==0 then --Left support
      uRight, pRLeg[3], pRLeg[5] = 
	generate_kick_trajectory(ph,uRight0,uRight1,stepType);
    elseif supportLeg==1 then --Right support
      uLeft, pLLeg[3], pLLeg[5] = 
	generate_kick_trajectory(ph,uLeft0,uLeft1,stepType);
    end
  else
    pLLeg[5],pRLeg[5] = 0,0; --angle set as zero
    if supportLeg==0 then --Left support
      uRight = util.se2_interpolate(xFoot, uRight0, uRight1);
      pRLeg[3] = zFoot;
    elseif supportLeg==1 then --Right support
      uLeft = util.se2_interpolate(xFoot, uLeft0, uLeft1);
      pLLeg[3]=zFoot;
    else --Double support
      pLLeg[3],pRLeg[3] = 0,0;
    end
  end

  uTorso=vector.new({torsoInterpolated[1],torsoInterpolated[2],
	(uLeft[3]+uRight[3])/2 });
  uTorsoActual = util.pose_global(vector.new({-footX,0,0}),uTorso);

  pLLeg[1], pLLeg[2], pLLeg[6] = uLeft[1], uLeft[2], uLeft[3];
  pRLeg[1], pRLeg[2], pRLeg[6] = uRight[1], uRight[2], uRight[3];
  pTorso[1], pTorso[2], pTorso[6] = uTorsoActual[1], uTorsoActual[2], uTorsoActual[3];
  pTorso[3] = bodyHeight;

  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, supportLeg);
  motion_legs(qLegs);
  motion_arms();
end

function update_discrete(tStateUpdate)
  update_zmp_array(tStateUpdate+time_offset);
  if ph>phs[1] then --New step
    t1=t;
    uLeft, uRight = uLeft1,uRight1;
    uLeft0, uRight0 = uLeft1,uRight1;
    zaLeft0[1],zaLeft0[2] = zaLeft1[1],zaLeft1[2]; 
    zaRight0[1],zaRight0[2] = zaRight1[1],zaRight1[2];
    supportLeg = supportLegs[1];
    stepType = stepTypes[1];

    if supportLeg==2 then 
      zaLeft1 = zaLefts[1];  zaRight1 = zaRights[1];
    else
      uLeft1=uLeftTargets[1];
      uRight1=uRightTargets[1];
      zaLeft1[1],zaLeft1[2]=zaLefts[1][1],zaLefts[1][2];
      zaRight1[1],zaRight1[2]=zaRights[1][1],zaRights[1][2];
    end

    if supportLeg == 0 then --LS
        Body.set_lleg_hardness(hardnessSupport);
        Body.set_rleg_hardness(hardnessSwing);
    elseif supportLeg==1 then --RS
        Body.set_lleg_hardness(hardnessSwing);
        Body.set_rleg_hardness(hardnessSupport);
    end
--    print("stepType:",stepType)
  end
  ph = phs[1];

  -- Get state feedback
  imuAngle = Body.get_sensor_imuAngle();
  imuGyr = Body.get_sensor_imuGyrRPY();
  imuRoll = imuAngle[1];
  imuPitch = imuAngle[2]-bodyTilt;
  gyro_roll=imuGyr[1];
  gyro_pitch=imuGyr[2];

  x_err0 = {math.sin(imuPitch)*bodyHeight,-math.sin(imuRoll)*bodyHeight};

  x_err={x_err0[1]*math.cos(uTorso[3])-x_err0[2]*math.sin(uTorso[3]),
	x_err0[2]*math.cos(uTorso[3])+x_err0[1]*math.sin(uTorso[3])}

  x_err[1]=math.min(0.06,math.max(-0.06,x_err[1]));
  x_err[2]=math.min(0.06,math.max(-0.06,x_err[2]));
--  print("x_err:",unpack(x_err))

  threshold = 0.02;
  --Deadzone filtering
  if x_err[1]>threshold then x_err[1]=x_err[1]-threshold;
  elseif x_err[1]<-threshold then x_err[1]=x_err[1]+threshold;
  else x_err[1]=0;
  end
  if x_err[2]>threshold then x_err[2]=x_err[2]-threshold;
  elseif x_err[2]<-threshold then x_err[2]=x_err[2]+threshold;
  else x_err[2]=0;
  end

  --feedback_gain1 = 1;
  feedback_gain1 = 0;

  x_closed=x[1][1]+x_err[1]*feedback_gain1;
  y_closed=x[1][2]+x_err[2]*feedback_gain1;

  --  Update state variable
  --  u = param_k1_px * x - param_k1* zmparray; --Control output
  --  x = param_a * x + param_b * u;

  ux = param_k1_px[1][1] * x_closed+
	param_k1_px[1][2] * x[2][1]+
	param_k1_px[1][3] * x[3][1];

  uy =  param_k1_px[1][1] * y_closed+
	param_k1_px[1][2] * x[2][2]+
	param_k1_px[1][3] * x[3][2];

  for i=1,nPreview do
    ux = ux - param_k1[1][i]*zmpx[i];
    uy = uy - param_k1[1][i]*zmpy[i];
  end

  feedback_gain2 = 0;

  x[1][1]=x[1][1]+x_err[1]*feedback_gain2;
  x[1][2]=x[1][2]+x_err[2]*feedback_gain2;
  x= param_a*x + param_b * matrix:new({{ux,uy}});

  return  vector.new({x[1][1],x[1][2]}); --current torso position
end

function motion_legs(qLegs)
  phComp = math.min(1, phSingle/.1, (1-phSingle)/.1);

  --Ankle stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyrRPY();

  gyro_roll=imuGyr[1];
  gyro_pitch=imuGyr[2];

--Hack: No gyro-based ankle strategy here
--  gyro_roll, gyro_pitch =0,0;

  ankleShiftX=util.procFunc(gyro_pitch*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4]);
  ankleShiftY=util.procFunc(gyro_roll*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4]);
  kneeShiftX=util.procFunc(gyro_pitch*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4]);
  hipShiftY=util.procFunc(gyro_roll*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4]);
  armShiftX=util.procFunc(gyro_pitch*armImuParamY[2],armImuParamY[3],armImuParamY[4]);
  armShiftY=util.procFunc(gyro_roll*armImuParamY[2],armImuParamY[3],armImuParamY[4]);

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);
  kneeShift=kneeShift+kneeImuParamX[1]*(kneeShiftX-kneeShift);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);
  armShift[1]=armShift[1]+armImuParamX[1]*(armShiftX-armShift[1]);
  armShift[2]=armShift[2]+armImuParamY[1]*(armShiftY-armShift[2]);

--TODO: Toe/heel lifting

  toeTipCompensation = 0;

  if supportLeg == 0 then  -- Left support
    qLegs[2] = qLegs[2] + hipShift[2];    --Hip roll stabilization
    qLegs[4] = qLegs[4] + kneeShift;    --Knee pitch stabilization
    qLegs[5] = qLegs[5]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[6] = qLegs[6] + ankleShift[2];    --Ankle roll stabilization
    qLegs[11] = qLegs[11]  + toeTipCompensation;
    qLegs[2] = qLegs[2] + hipRollCompensation*phComp; --Hip roll compensation
  elseif supportLeg==1 then --Right support
    qLegs[8] = qLegs[8]  + hipShift[2];    --Hip roll stabilization
    qLegs[10] = qLegs[10] + kneeShift;    --Knee pitch stabilization
    qLegs[11] = qLegs[11]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[12] = qLegs[12] + ankleShift[2];    --Ankle roll stabilization

    --Lifting toetip
    qLegs[5] = qLegs[5]  + toeTipCompensation;
    qLegs[8] = qLegs[8] - hipRollCompensation*phComp;--Hip roll compensation
  else --double support
    qLegs[4] = qLegs[4] + kneeShift;    --Knee pitch stabilization
    qLegs[5] = qLegs[5]  + ankleShift[1];    --Ankle pitch stabilization
    qLegs[10] = qLegs[10] + kneeShift;    --Knee pitch stabilization
    qLegs[11] = qLegs[11]  + ankleShift[1];    --Ankle pitch stabilization
  end

  Body.set_lleg_command(qLegs);
end

function motion_arms()
  qLArmActual={}
  qRArmActual={}
 
  qLArmActual[1],qLArmActual[2]=
	qLArm0[1]+armShift[1],qLArm0[2]+armShift[2];
  qRArmActual[1],qRArmActual[2]=
	qRArm0[1]+armShift[1],qRArm0[2]+armShift[2];

  --Check leg hitting
  RotLeftA =  util.mod_angle(uLeft[3] - uTorso[3]);
  RotRightA =  util.mod_angle(uTorso[3] - uRight[3]);

  LLegTorso = util.pose_relative(uLeft,uTorso);
  RLegTorso = util.pose_relative(uRight,uTorso);

  qLArmActual[2]=math.max(
    5*math.pi/180 + math.max(0, RotLeftA)/2
    + math.max(0,LLegTorso[2] - 0.04) /0.02 * 6*math.pi/180
    ,qLArmActual[2])

  qRArmActual[2]=math.min(
    -5*math.pi/180 - math.max(0, RotRightA)/2
    - math.max(0,-RLegTorso[2] - 0.04)/0.02 * 6*math.pi/180
    ,qRArmActual[2]);

  qLArmActual[3]=qLArm0[3];
  qRArmActual[3]=qRArm0[3];

  Body.set_larm_command(qLArmActual);
  Body.set_rarm_command(qRArmActual);
end

function exit()
  mcm.set_walk_isStepping(0);
end

function start()
  if (not active) then
    active = true;
    t0 = Body.get_time();
    stance_reset();
  end
end

function stop()
end

function get_odometry(u0)
  if (not u0) then
    u0 = vector.new({0, 0, 0});
  end
  local uFoot = util.se2_interpolate(.5, uLeft, uRight);
  return util.pose_relative(uFoot, u0), uFoot;
end

function get_body_offset()
  local uFoot = util.se2_interpolate(.5, uLeft, uRight);
  return util.pose_relative(uTorso, uFoot);
end

function foot_phase(ph)
  -- Computes relative x,z motion of foot during single support phase
  -- phSingle = 0: x=0, z=0, phSingle = 1: x=1,z=0
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local phSingleSkew = phSingle^0.8 - 0.17*phSingle*(1-phSingle);
  local xf = .5*(1-math.cos(math.pi*phSingleSkew));
  local zf = .5*(1-math.cos(2*math.pi*phSingleSkew));
  return xf, zf;
end

function generate_kick_trajectory(ph,uFoot0,uFoot1, stepType)
  local uFoot, zFoot, aFoot;
  local kick_ph1,kick_ph2, kick_ph3  = 0.4, 0.7, 0.9
  local kick_mag = 1.5;

--  local kick_ph1,kick_ph2, kick_ph3  = 0.4, 0.8, 0.9
--  local kick_mag = 1.2;

  if stepType==1 then --Lifting
    uFoot = util.se2_interpolate(ph,uFoot0,uFoot1);
    zFoot = ph * kickHeight;
    aFoot = ph * kickAngle0;
  elseif stepType==5 then --Moving
    uFoot = util.se2_interpolate(ph,uFoot0,uFoot1);
    zFoot = kickHeight;
    aFoot = kickAngle1;

  elseif stepType==2 then --Kicking
    uFoot = uFoot1;
    zFoot = kickHeight;
    aFoot = kickAngle1;
  elseif stepType==3 then --Returning (Moving back in space)
    uFoot = util.se2_interpolate(ph,uFoot0,uFoot1);
    zFoot = (1-ph) * (kickHeight-0.02)+0.02;
    aFoot = (1-ph) * kickAngle1;
  elseif stepType==4 then  --Landing
    uFoot = util.se2_interpolate(ph,uFoot0,uFoot1);
    zFoot = (1-ph) * 0.02;
    aFoot = 0;
  end
  return uFoot, zFoot, aFoot;
end

precompute();


function set_velocity()
end
