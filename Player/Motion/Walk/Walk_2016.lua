module(..., package.seeall);

require('Body')
require('Kinematics')
require('Config');
require('vector')
require('mcm')
require('unix')
require('util')
require('Body')
require('libWalk')
require('libZmp')

----------------------------------------------------------
-- Walk state variables
----------------------------------------------------------
--u means for the world coordinate, origin is in the middle of two feet
uTorso = vector.new({Config.walk.supportX, 0, 0});
uLeft = vector.new({0, Config.walk.footY, 0});
uRight = vector.new({0, -Config.walk.footY, 0});
velCurrent, velCommand,velDiff = vector.new({0,0,0}),vector.new({0,0,0}),vector.new({0,0,0})
ph,phSingle = 0,0

-- Walk parameters
cp=libWalk.load_default_param_values() --Walk parametes for current step
np=libWalk.load_default_param_values() --Walk parametes for next step

active,started = true,false;
iStep0,iStep = -1,0
tLastStep = Body.get_time()

canWalkKick = true; --Can we do walkkick with this walk code?
walkKickRequest,current_step_type = 0,0
initial_step,stopRequest=2,2

--emergency stop/resume handling
is_stopped = false
stop_threshold = {10*math.pi/180,18*math.pi/180}
tStopStart = 0
tStopDuration = 2.0
max_unstable_factor=0

----------------------------------------------------------
-- End initialization 
----------------------------------------------------------

function entry()
  print ("Motion: Walk entry")
  velCurrent, velCommand,velDiff = vector.new({0,0,0}),vector.new({0,0,0}),vector.new({0,0,0})
  uLeft = util.pose_global(vector.new({-cp.supportX, cp.footY, 0}),uTorso)
  uRight = util.pose_global(vector.new({-cp.supportX, -cp.footY, 0}),uTorso)
  uLeft1, uLeft2,uRight1, uRight2,uTorso1, uTorso2 = uLeft, uLeft, uRight, uRight, uTorso, uTorso
  uSupport = uTorso
  tLastStep=Body.get_time()
  walkKickRequest,current_step_type  = 0,0 
  iStep0,iStep = -1,0
  max_unstable_factor=0;

  --Place arms in appropriate position at sides
  Body.set_larm_command(Config.walk.qLArm)
  Body.set_rarm_command(Config.walk.qRArm)
  Body.set_larm_hardness(Config.walk.hardnessArm or 0.2)
  Body.set_rarm_hardness(Config.walk.hardnessArm or 0.2);
end

function start()
  stopRequest = 0;
  if (not active) then
    active,started = true,false    
    iStep0,initial_step = -1,2
    tLastStep = Body.get_time()    
  end
end

function stop() stopRequest = math.max(1,stopRequest) end


function update()  
  t = Body.get_time()
  if check_instability() then return end
--  if vcm.get_camera_bodyHeight()<cp.bodyHeight-0.01 then return end
  if (not active) then mcm.set_walk_isMoving(0);update_still() return end

  mcm.set_walk_isMoving(1)
  if (not started) then started=true;tLastStep = Body.get_time() end
  ph = (t-tLastStep)/cp.tStep   --step phase factor, should between 0 to 1

  if ph>1 then
    iStep=iStep+1
    ph=ph-math.floor(ph)
    tLastStep=tLastStep+cp.tStep
  end

  -- New step
  if (iStep > iStep0) then
    if stopRequest==2 then --Stop when stopping sequence is done
      stopRequest,active = 0,false
      velCurrent, velCommand,velDiff = vector.new({0,0,0}),vector.new({0,0,0}),vector.new({0,0,0})      
      return "stop"
    end
    velCurrent,velDiff,initial_step = 
      libWalk.update_velocity(velCurrent,velCommand,initial_step,max_unstable_factor)
    iStep0 = iStep;
    supportLeg = iStep % 2; -- 0 for left support, 1 for right support
    uLeft1,uRight1,uTorso1 = uLeft2,uRight2,uTorso2

    --Switch walk params 
    cp = np
    np = libWalk.load_default_param_values()
  
    supportMod = {0,0}; --Support Point modulation for walkkick
    shiftFactor = 0.5; --How much should we shift final Torso pose?

    check_walkkick(); 
    if walkKickRequest==0 then
      local tStep_next = libZmp.calculate_swap(uLeft1,uLeft2,uRight1,uRight2,cp)
      np.tStep0, np.tStep = tStep_next,tStep_next
      if (stopRequest==1) then  --Final step
        stopRequest=2        
        if supportLeg == 0 then uRight2 = libWalk.stop_right_destination(uLeft1,uRight1,cp)
        else uLeft2 = libWalk.stop_left_destination(uLeft1,uRight1,cp) end
      else --Normal walk, advance steps
        if supportLeg == 0 then uRight2 = libWalk.step_right_destination(velCurrent, uLeft1, uRight1,cp) --LS
        else uLeft2 = libWalk.step_left_destination(velCurrent, uLeft1, uRight1,cp) end --RS
        support_compensation() 
      end
    end
    uTorso2 = libWalk.step_torso(uLeft2, uRight2,shiftFactor,cp)

    --Apply velocity-based support point modulation for uSupport
    if supportLeg == 0 then --Left leg support
      local uLeftTorso = util.pose_relative(uLeft1,uTorso1);
      local uTorsoModded = util.pose_global(vector.new({supportMod[1],supportMod[2],0}),uTorso)
      local uLeftModded = util.pose_global (uLeftTorso,uTorsoModded); 
      uSupport = util.pose_global({cp.supportX, cp.supportY, 0},uLeftModded)
      Body.set_lleg_hardness(cp.hardnessSupport);
      Body.set_rleg_hardness(cp.hardnessSwing);
    else --Right leg support
      local uRightTorso = util.pose_relative(uRight1,uTorso1);
      local uTorsoModded = util.pose_global(vector.new({supportMod[1],supportMod[2],0}),uTorso)
      local uRightModded = util.pose_global (uRightTorso,uTorsoModded); 
      uSupport = util.pose_global({cp.supportX, -cp.supportY, 0}, uRightModded)
      Body.set_lleg_hardness(cp.hardnessSwing);
      Body.set_rleg_hardness(cp.hardnessSupport);      
    end
    libZmp.calculate_zmp_param(uSupport,uTorso1,uTorso2,cp) --calculate new zmp parameters
    max_unstable_factor=0
  end --End new step

  local xFoot,zFoot = libWalk.foot_phase(ph,cp)
  local aLeft,aRight = libWalk.foot_tilt(ph,velCurrent,supportLeg,cp)
  if initial_step>0 then zFoot=0;  end --Don't lift foot at initial step
  
  if supportLeg == 0 then    -- Left support
    uRight = libWalk.foot_interpolate(uRight1,uRight2,uRight15,xFoot,current_step_type)    
    zLeft,zRight = 0,cp.stepHeight*zFoot
  else    -- Right support    
    uLeft = libWalk.foot_interpolate(uLeft1,uLeft2,uLeft15,xFoot,current_step_type)    
    zLeft,zRight = cp.stepHeight*zFoot,0
  end
  
  footX = mcm.get_footX()  
  uTorso = libZmp.zmp_com(uSupport,ph,cp)
  uTorso[3]=(uLeft[3]+uRight[3])/2
  uTorsoActual = util.pose_global(vector.new({-footX,0,0}),uTorso)
  pLLeg = vector.new({uLeft[1], uLeft[2], zLeft, 0,0,uLeft[3]});
  pRLeg = vector.new({uRight[1], uRight[2], zRight, 0,0,uRight[3]})
  pTorso = vector.new({uTorsoActual[1], uTorsoActual[2], cp.bodyHeight, 0,cp.bodyTilt,uTorsoActual[3]});

  libWalk.move_legs(pLLeg, pRLeg, pTorso, supportLeg, phSingle,cp,gyro_off)
end

function check_instability()
  imuAngle = Body.get_sensor_imuAngle();
  local unstable_factor = math.max ( 
    math.abs(imuAngle[1]) / stop_threshold[1],math.abs(imuAngle[2]) / stop_threshold[2])
  max_unstable_factor = math.max(unstable_factor, max_unstable_factor)
  --start emergency stop
  if unstable_factor>1 and walkKickRequest==0 then
    stopRequest = 2
    tStopStart = t
    velCurrent= vector.new({0,0,0})
    is_stopped = true
  end
  --end emergency stop
  if is_stopped and t>tStopStart+tStopDuration then
    is_stopped = false
    start()
    return true
  end
end

function update_still()
  footX = mcm.get_footX()
  Body.set_lleg_hardness(cp.hardnessSwing);
  Body.set_rleg_hardness(cp.hardnessSwing);

  uTorso = libWalk.step_torso(uLeft, uRight,0.5,cp);
  uTorsoActual = util.pose_global(vector.new({-footX,0,0}), uTorso);
  pLLeg = vector.new({uLeft[1], uLeft[2], 0, 0,0,uLeft[3]});
  pRLeg = vector.new({uRight[1], uRight[2], 0, 0,0,uRight[3]})
  pTorso = vector.new({uTorsoActual[1], uTorsoActual[2], cp.bodyHeight, 0,cp.bodyTilt,uTorsoActual[3]});
  libWalk.move_legs(pLLeg,pRLeg,pTorso,2,0,cp,true)
end

function support_compensation()

  --Support bias parameters to reduce backlash-based instability
  velFastForward = Config.walk.velFastForward or 0.06;
  velFastTurn = Config.walk.velFastTurn or 0.2;
  supportFront = Config.walk.supportFront or 0;
  supportFront2 = Config.walk.supportFront2 or 0;
  supportBack = Config.walk.supportBack or 0;
  supportSideX = Config.walk.supportSideX or 0;
  supportSideY = Config.walk.supportSideY or 0;
  supportTurn = Config.walk.supportTurn or 0;
  frontComp = Config.walk.frontComp or 0.003;
  AccelComp = Config.walk.AccelComp or 0.003;

  if velDiff[1]>0 then supportMod[1] = supportFront2 --Accelerating to front
  elseif velCurrent[1]>velFastForward then 
    supportMod[1] = supportFront
  elseif velCurrent[1]<0 then 
    supportMod[1] = supportBack
  elseif math.abs(velCurrent[3])>velFastTurn then 
    supportMod[1] = supportTurn
  else
    if velCurrent[2]>0.015 then 
      supportMod[1],supportMod[2] = supportSideX,supportSideY              
    elseif velCurrent[2]<-0.015 then 
      supportMod[1],supportMod[2] = supportSideX,-supportSideY
    end
  end


  supportModYInitial = Config.walk.supportModYInitial or 0
  
  --Adjustable initial step body swing
  if initial_step>0 then 
    if supportLeg == 0 then supportMod[2]=supportModYInitial --LS
    else supportMod[2]=-supportModYInitial end--RS
  end
end


function check_walkkick()
  local uLRFootOffset = vector.new({0,cp.footY,0});
  --Walkkick def: 
  --tStep stepType supportFoot stepHeight bodyPosMod footPos1 footPos2
  if walkKickRequest==0 or (not walkKick) then return end
  if walkKickRequest>0 and walkKickRequest>#walkKick then
    print("NEWNEWNEWKICK: WALKKICK DONE");
    walkKickRequest = 0
    cp.tStep = cp.tStep0
    cp.stepHeight = cp.stepHeight0
    current_step_type=0
    velCurrent,velCommand=vector.new({0,0,0}),vector.new({0,0,0})
    return
  end

  if walkKickRequest==1 then 
    --Check current supporLeg and feet positions
    --and advance steps until ready
    uFootErr = util.pose_relative(uLeft1,util.pose_global(2*uLRFootOffset,uRight1))
    if supportLeg~=walkKick[1][3] or math.abs(uFootErr[1])>0.02 
        or math.abs(uFootErr[2])>0.01 or math.abs(uFootErr[3])>10*math.pi/180 then
      if supportLeg == 0 then uRight2 = util.pose_global( -2*uLRFootOffset, uLeft1) 
      else uLeft2 = util.pose_global( 2*uLRFootOffset, uRight1)  end
      return
    end
  end
  --  print("NEWNEWNEWKICK: WALKKICK, count",walkKickRequest);

  cp.tStep = walkKick[walkKickRequest][1];   
  current_step_type = walkKick[walkKickRequest][2];   
  supportLeg = walkKick[walkKickRequest][3];
  cp.stepHeight = walkKick[walkKickRequest][4];
  supportMod = walkKick[walkKickRequest][5];
  shiftFactor = walkKick[walkKickRequest][6];

  if #walkKick[walkKickRequest] <=7 then
    footPos1 =  walkKick[walkKickRequest][7];
    if supportLeg == 0 then      -- TODO: look at uLRFootOffset for use here
      uRight2 = util.pose_global({footPos1[1],footPos1[2]-2*cp.footY,footPos1[3]},uLeft1)
    else
      uLeft2 = util.pose_global({footPos1[1],footPos1[2]+2*cp.footY,footPos1[3]},uRight1)
    end
  else
    footPos1,footPos2 =  walkKick[walkKickRequest][7],walkKick[walkKickRequest][8]
    if supportLeg == 0 then
      uRight15 = util.pose_global({footPos1[1],footPos1[2]-2*cp.footY,footPos1[3]},uLeft1)
      uRight2 = util.pose_global({footPos2[1],footPos2[2]-2*cp.footY,footPos2[3]},uLeft1)
    else
      uLeft15 = util.pose_global({footPos1[1],footPos1[2]+2*cp.footY,footPos1[3]},uRight1)
      uLeft2 = util.pose_global({footPos2[1],footPos2[2]+2*cp.footY,footPos2[3]},uRight1)
    end
  end
  walkKickRequest = walkKickRequest + 1;
end

function stance_reset() end
function exit() end

function startwalkkick(kickname)
  if walkKickRequest==0 then walkKickRequest, walkKick = 1,Config.kick.walkKickDef[kickname] end
end
function doWalkKickLeft() startwalkkick("FrontLeft") end
function doWalkKickRight() startwalkkick("FrontRight") end
function doWalkKickLeft2() startwalkkick("FrontLeft") end
function doWalkKickRight2() startwalkkick("FrontRight") end
function doStepKickLeft() startwalkkick("FrontLeft") end
function doStepKickRight() startwalkkick("FrontRight") end
function doSideKickLeft() startwalkkick("SideLeft") end
function doSideKickRight() startwalkkick("SideRight") end
function zero_velocity() end
function stopAlign() stop() end

function get_odometry(u0)
  if (not u0) then u0 = vector.new({0, 0, 0}) end
  local uFoot = util.se2_interpolate(.5, uLeft, uRight);
  return util.pose_relative(uFoot, u0), uFoot;
end

function get_body_offset()
  local uFoot = util.se2_interpolate(.5, uLeft, uRight);
  return util.pose_relative(uTorso, uFoot);
end

function set_velocity(vx, vy, va) velCommand=libWalk.clip_velocity(vx,vy,va) end
function get_velocity() return velCurrent end

entry()