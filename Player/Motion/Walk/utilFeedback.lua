module(..., package.seeall);

require('Config')
require('vector');
require('util')
require('math')
require('invhyp') --Inverse hyperbolic sin function (not supported with vanilla math)
local matrix = require('matrix_zmp') --for linear equations solving (temporary)
require('Transform')
require('Kinematics')
require('mcm')

stanceQueue={data={},itemno = 0}

legbuf={
  lleg={},
  rleg={},
  support={},
  index=0,
  maxsize=5
}

debug_enable = false
--debug_enable = true

t0 = Body.get_time()

function legEnqueue(qLLeg,qRLeg,support)
  if #legbuf.lleg<legbuf.maxsize then
    legbuf.index=legbuf.index+1
  else
    legbuf.index = (legbuf.index%legbuf.maxsize)+1
  end
  legbuf.lleg[legbuf.index]=util.shallow_copy(qLLeg)
  legbuf.rleg[legbuf.index]=util.shallow_copy(qRLeg)
  legbuf.support[legbuf.index]=support
end

function legReadqueue(iDelay)
  if #legbuf.lleg==0 then return end
  index = (legbuf.index + (legbuf.maxsize-iDelay-1))%legbuf.maxsize+1
  if #legbuf.lleg<iDelay then index=1 end
  return legbuf.lleg[index],legbuf.rleg[index],legbuf.support[index]
end


function init()
  feedbackState={
    ankleX=0,
    ankleY=0,
    kneeX=0,
    hipY=0,

    torsoPitch=0,
    torsoRoll=0,
    torsoX=0,
    torsoY=0,
  }
end

init()

function apply_simple_feedback(ph,supportLeg,sp,disable,dt)
  imuGyr = Body.get_sensor_imuGyrRPY();
  gyro_roll,gyro_pitch=imuGyr[1],imuGyr[2]
  if disable then  
    gyro_roll,gyro_pitch=0,0 
    init()
    calculate_error(2)
    return
  end

  local fp = sp.feedbackParam
  calculate_error(supportLeg)

  --mcm.set_feedback_errorJE({xErr*1000,yErr*1000,pitchErr*180/math.pi,rollErr*180/math.pi})
  local errorJE = mcm.get_feedback_errorJE()
  local pitchErr = errorJE[3]*math.pi/180
  local rollErr = errorJE[4]*math.pi/180

  --gyro direction is flipped at the body
  gyro_pitch_tr = -0.01*gyro_pitch
  gyro_roll_tr = -0.01*gyro_roll

  local torsoPT = 
    util.procFunc(gyro_pitch_tr*fp.PIDX[3],fp.filterX[2],fp.filterX[3])
--    +fp.PIDX[1]*pitchErr

  local torsoRT = 
     util.procFunc(gyro_roll_tr*fp.PIDY[3],fp.filterY[2],fp.filterY[3])
--     +fp.PIDY[1]*rollErr

  roll_feedback_enable = Config.roll_feedback_enable or 0
  pitch_feedback_enable = Config.pitch_feedback_enable or 0
  if pitch_feedback_enable==0 then torsoPT=0 end
  if roll_feedback_enable==0 then torsoRT=0 end

  local dTorsoPitch = fp.filterX[1]*(torsoPT-feedbackState.torsoPitch)
  local dTorsoRoll = fp.filterY[1]*(torsoRT-feedbackState.torsoRoll)


  feedbackState.torsoPitch = feedbackState.torsoPitch + 
    math.min(fp.PIDVelX*dt, math.max(-fp.PIDVelX*dt, dTorsoPitch))
  feedbackState.torsoRoll = feedbackState.torsoRoll + 
    math.min(fp.PIDVelY*dt, math.max(-fp.PIDVelY*dt, dTorsoRoll))

  mcm.set_feedback_torsoTarget({torsoPT*180/math.pi,torsoRT*180/math.pi})
  mcm.set_feedback_torsoTargetFiltered({
		feedbackState.torsoPitch*180/math.pi
		,feedbackState.torsoRoll*180/math.pi})

--[[
  local ankleXT = util.procFunc(gyro_pitch*fp.ankleX[2],fp.ankleX[3],fp.ankleX[4])
  local kneeXT = util.procFunc(gyro_pitch*fp.kneeX[2],fp.kneeX[3],fp.kneeX[4])
  local ankleYT = util.procFunc(gyro_roll*fp.ankleY[2],fp.ankleY[3],fp.ankleY[4])
  local hipYT = util.procFunc(gyro_roll*fp.hipY[2],fp.hipY[3],fp.hipY[4])
  feedbackState.ankleX = feedbackState.ankleX + fp.ankleX[1]*(ankleXT - feedbackState.ankleX ) 
  feedbackState.ankleY = feedbackState.ankleY + fp.ankleY[1]*(ankleYT - feedbackState.ankleY ) 
  feedbackState.kneeX = feedbackState.kneeX + fp.kneeX[1]*(kneeXT - feedbackState.kneeX) 
  feedbackState.hipY = feedbackState.hipY + fp.hipY[1]*(hipYT - feedbackState.hipY ) 
--]]

end

function calculate_error(supportLeg)
  local qLLegDelayed,qRLegDelayed,supportLegDelayed = legReadqueue(3)
  if not qLLegDelayed then return end

  local qLLegMeasured = Body.get_lleg_position()
  local qRLegMeasured = Body.get_rleg_position()

  local pLLegTorso = Kinematics.torso_lleg(qLLegMeasured)
  local pRLegTorso = Kinematics.torso_rleg(qRLegMeasured)
  local pLLegTorsoCommand = Kinematics.torso_lleg(qLLegDelayed)
  local pRLegTorsoCommand = Kinematics.torso_rleg(qRLegDelayed)

  local uLLegTorsoMeasured = {pLLegTorso[1],pLLegTorso[2]}
  local uRLegTorsoMeasured = {pRLegTorso[1],pRLegTorso[2]}
  local uLLegTorsoCommand = {pLLegTorsoCommand[1],pLLegTorsoCommand[2]}
  local uRLegTorsoCommand = {pRLegTorsoCommand[1],pRLegTorsoCommand[2]}


  local xErrLeft = uLLegTorsoMeasured[1] - uLLegTorsoCommand[1]
  local yErrLeft = uLLegTorsoMeasured[2] - uLLegTorsoCommand[2]
  local xErrRight = uRLegTorsoMeasured[1] - uRLegTorsoCommand[1]
  local yErrRight = uRLegTorsoMeasured[2] - uRLegTorsoCommand[2]
   
  local pitchErr,rollErr,xErr,yErr=0,0,0,0;

  if supportLegDelayed==0 then --left support
    pitchErr = pLLegTorso[5]
    rollErr = pLLegTorso[4]
    xErr,yErr = xErrLeft,yErrLeft
  elseif supportLeg==1 then
    pitchErr = pRLegTorso[5]
    rollErr = pRLegTorso[4]
    xErr,yErr = xErrRight,yErrRight
  else
    pitchErr = (pLLegTorso[5]+pRLegTorso[5])/2
    rollErr = (pLLegTorso[4]+pRLegTorso[4])/2
    xErr,yErr = (xErrLeft+xErrRight)/2,(yErrLeft+yErrRight)/2
  end

  imuGyr = Body.get_sensor_imuGyrRPY()
  imuAngle = Body.get_sensor_imuAngle()

  mcm.set_feedback_t((Body.get_time()-t0)*1000)
  mcm.set_feedback_support({supportLeg,supportLegDelayed})
  mcm.set_feedback_imuAngle({imuAngle[2]*180/math.pi,imuAngle[1]*180/math.pi})
  mcm.set_feedback_imuGyro({imuGyr[2]*180/math.pi,imuGyr[1]*180/math.pi})
  mcm.set_feedback_errorLeftJE({xErrLeft*1000,yErrLeft*1000,pLLegTorso[5]*180/math.pi,pLLegTorso[4]*180/math.pi})
  mcm.set_feedback_errorRightJE({xErrRight*1000,yErrRight*1000,pRLegTorso[5]*180/math.pi,pRLegTorso[4]*180/math.pi})
  mcm.set_feedback_errorJE({xErr*1000,yErr*1000,pitchErr*180/math.pi,rollErr*180/math.pi})

end


function motion_legs_2(uTorso,uTorsoComp,pLLeg, pRLeg,supportLeg,sp,ph)

  local ph1Single,ph2Single = sp.phSingleRatio/2,1-sp.phSingleRatio/2
  local phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local phComp = math.min(1, phSingle/.1, (1-phSingle)/.1);

  local uTorsoActual = util.pose_global(uTorsoComp,uTorso)
  local pTorso = {uTorsoActual[1], uTorsoActual[2], sp.bodyHeight, 0,sp.bodyTilt,uTorsoActual[3]}
  local qLegs0 = Kinematics.inverse_legs(pLLeg,pRLeg,pTorso,supportLeg or 0)
  legEnqueue(vector.slice(qLegs0,1,6),vector.slice(qLegs0,7,12),supportLeg)

  local ankle_com_z = 0.085+0.185
  local knee_com_z = 0.085+0.09
  local hip_com_z = 0.085

  local torsoPitchComp = feedbackState.torsoPitch
  local torsoXComp = (ankle_com_z*0.625 + knee_com_z*0.325)*math.tan(feedbackState.torsoPitch)

  local torsoRollComp =  feedbackState.torsoRoll
  local torsoYComp = -(ankle_com_z*0.625 + hip_com_z*0.325)*math.tan(feedbackState.torsoRoll)

  local uTorsoActualTarget = util.pose_global({torsoXComp,torsoYComp,0},uTorsoActual)
  local bodyRollTarget = torsoRollComp
  local bodyTiltTarget = sp.bodyTilt + torsoPitchComp

  local pTorsoTarget = {uTorsoActualTarget[1], uTorsoActualTarget[2], sp.bodyHeight, bodyRollTarget,bodyTiltTarget,uTorsoActual[3]}
  local qLegsTarget = Kinematics.inverse_legs(pLLeg,pRLeg,pTorsoTarget,supportLeg or 0)




  local LOffset=vector.new({
	0,0,Config.walk.LHipOffset,
	0,Config.walk.LAnkleOffset,0})
  local ROffset=vector.new({
	0,0,Config.walk.RHipOffset,
	0,Config.walk.RAnkleOffset,0})

	
  if supportLeg==0 then --left support
    qLegsTarget[2] = qLegsTarget[2] + sp.hipRollCompensation*phComp; --Hip roll compensation

    Body.set_lleg_command(vector.slice(qLegsTarget,1,6)+LOffset)
    Body.set_rleg_command(vector.slice(qLegs0,7,12)+ROffset)
  elseif supportLeg==1 then
    qLegsTarget[8] = qLegsTarget[8] - sp.hipRollCompensation*phComp;--Hip roll compensation
    Body.set_lleg_command(vector.slice(qLegs0,1,6)+LOffset)
    Body.set_rleg_command(vector.slice(qLegsTarget,7,12)+ROffset)
  else
    Body.set_lleg_command(vector.slice(qLegsTarget,1,6)+LOffset)
    Body.set_rleg_command(vector.slice(qLegsTarget,7,12)+ROffset)
  end
end




function motion_legs(uTorso,uTorsoComp,pLLeg, pRLeg,supportLeg,sp,ph)

  use_2 = true
  if use_2 then
    motion_legs_2(uTorso,uTorsoComp,pLLeg,pRLeg,supportLeg,sp,ph)
  else
  local ph1Single,ph2Single = sp.phSingleRatio/2,1-sp.phSingleRatio/2
  local phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local phComp = math.min(1, phSingle/.1, (1-phSingle)/.1);

  local uTorsoActual = util.pose_global(uTorsoComp,uTorso)
  local pTorso = {uTorsoActual[1], uTorsoActual[2], sp.bodyHeight, 0,sp.bodyTilt,uTorsoActual[3]}
  local qLegs = Kinematics.inverse_legs(pLLeg,pRLeg,pTorso,supportLeg)
  legEnqueue(vector.slice(qLegs,1,6),vector.slice(qLegs,7,12),supportLeg)

  if supportLeg == 0 then  -- Left support
    qLegs[2] = qLegs[2] + feedbackState.hipY
    qLegs[4] = qLegs[4] + feedbackState.kneeX
    qLegs[5] = qLegs[5] + feedbackState.ankleX
    qLegs[6] = qLegs[6] + feedbackState.ankleY

    qLegs[2] = qLegs[2] + sp.hipRollCompensation*phComp; --Hip roll compensation
  else
    qLegs[8] = qLegs[8] + feedbackState.hipY
    qLegs[10] = qLegs[10] + feedbackState.kneeX
    qLegs[11] = qLegs[11] + feedbackState.ankleX
    qLegs[12] = qLegs[12] + feedbackState.ankleY
   
    qLegs[8] = qLegs[8] - sp.hipRollCompensation*phComp;--Hip roll compensation
  end

  qLegs[3] = qLegs[3]  + Config.walk.LHipOffset
  qLegs[9] = qLegs[9]  + Config.walk.RHipOffset
  qLegs[5] = qLegs[5]  + Config.walk.LAnkleOffset
  qLegs[11] = qLegs[11]  + Config.walk.RAnkleOffset

  Body.set_lleg_command(qLegs);
  end
end










function pushStance(uLeftTorso, uRightTorso)
  if stanceQueue.itemno<4 then
		stanceQueue.itemno = stanceQueue.itemno + 1
		stanceQueue.data[stanceQueue.itemno] = {uLeftTorso,uRightTorso}
	else
		stanceQueue.data[1]=stanceQueue.data[2]
		stanceQueue.data[2]=stanceQueue.data[3]
		stanceQueue.data[3]=stanceQueue.data[4]
		stanceQueue.data[4] = {uLeftTorso,uRightTorso}
	end
end



function computeError(ph)	
	if stanceQueue.itemno<4 then return end
	--compute measured transform

--	measuredLeftToCom = 
--	measuredRightToCom = 
--[[
	measuredLeftToCom = -Pose3D(theTorsoMatrix.rotation)
		.translate(-theRobotModel.centerOfMass)
		.conc(theRobotModel.limbs[MassCalibration::footLeft])
		.translate(0.f, 0.f, -theRobotDimensions.heightLeg5Joint).translation;
  measuredRightToCom = -Pose3D(theTorsoMatrix.rotation)
  	.translate(-theRobotModel.centerOfMass)
  	.conc(theRobotModel.limbs[MassCalibration::footRight])
  	.translate(0.f, 0.f, -theRobotDimensions.heightLeg5Joint).translation;
--]]

	qLLegMeasured = Body.get_lleg_position()
	qRLegMeasured = Body.get_rleg_position()
	pLLegTorso = Kinematics.torso_lleg(qLLegMeasured)
	pRLegTorso = Kinematics.torso_rleg(qRLegMeasured)
	uLLegTorsoMeasured = {pLLegTorso[1],pLLegTorso[2],pLLegTorso[6]}
	uRLegTorsoMeasured = {pRLegTorso[1],pRLegTorso[2],pRLegTorso[6]}

-- observer measurment delay: 40ms
-- So compare to the stance 40ms ago	
-- expectedLeftToCom = 
-- expectedRightToCom = 

	uLLegTorsoExpected = stanceQueue.data[1][1]
	uRLegTorsoExpected = stanceQueue.data[1][2]

	--[[
    int index = std::min(int(p.observerMeasurementDelay / 10.f - 0.5f), legStances.getNumberOfEntries() - 1);
    expectedStance = &legStances.getEntry(index);
    if(observedPendulumPlayer.isActive() && !observedPendulumPlayer.isLaunching())
      observedPendulumPlayer.getStance(*expectedStance, 0, 0, &stepOffset);
    else
      stepOffset = StepSize();
  }

  expectedLeftToCom = expectedStance->leftOriginToCom - expectedStance->leftOriginToFoot.translation;
  expectedRightToCom = expectedStance->rightOriginToCom - expectedStance->rightOriginToFoot.translation;
  --]]

  leftError = {uLLegTorsoMeasured[1]-uLLegTorsoExpected[1],
  	uLLegTorsoMeasured[2]-uLLegTorsoExpected[2],
			}
  rightError = {uRLegTorsoMeasured[1]-uRLegTorsoExpected[1],
  	uRLegTorsoMeasured[2]-uRLegTorsoExpected[2],
		}


	local imuAngle = Body.get_sensor_imuAngle()

	local lPitch = qLLegMeasured[3]+qLLegMeasured[4]+qLLegMeasured[5]
	local rPitch = qRLegMeasured[3]+qRLegMeasured[4]+qRLegMeasured[5]
--[[
	print("X error(mm):",leftError[1]*1000,rightError[1]*1000)	
	print("X angle error:",lPitch*180/math.pi,rPitch*180/math.pi)
	print("imu Pitch:",imuAngle[2]*180/math.pi)
--]]

--[[
	print(string.format("%.2f   %.1f %.1f    %.2f %.2f   %.2f",
		ph,
		leftError[1]*1000,rightError[1]*1000,	
		lPitch*180/math.pi,rPitch*180/math.pi,
		imuAngle[2]*180/math.pi))
--]]
end

--[[

function applyCorrection()
  local error = (leftError + rightError) * 0.5

  c = matrix{{1,0,0,0},{0,1,0,0}}
  c_t = c.transpose()
  a = matrix({1,0,dT,0},{0,1,0,dT},{0,0,1,0},{0,0,0,1})
  a_t = a.transpose()
  
  cov = a * cov * a_t
  for i=1,4 do 
  	cov[i][i]=cov[i][i]+observerProcessDev[i]*observerProcessDev[i]
  end

  covPlusSensorCov = c*cov*c_t
	observerMeasurementDeviation={20,20}
  if instable then
		observerMeasurementDeviation={20,10}  	--default value for instable
  elseif sp.next.move[1]>0 then
  	--Add deviation if walking fast
  	observerMeasurementDeviation[1]= observerMeasurementDeviation[1]+
  		(p.observerMeasurementDeviationAtFullSpeedX.x - p.observerMeasurementDeviation.x) * abs(next.s.translation.x) / (p.speedMax.translation.x * 0.5);
  	observerMeasurementDeviation[2]= observerMeasurementDeviation[2]+
    	(p.observerMeasurementDeviationAtFullSpeedX.y - p.observerMeasurementDeviation.y) * abs(next.s.translation.x) / (p.speedMax.translation.x * 0.5);
  end

  covPlusSensorCov[1][1] = covPlusSensorCov[1][1] + observerMeasurementDeviation[1]*observerMeasurementDeviation[1]
  covPlusSensorCov[2][2] = covPlusSensorCov[2][2] + observerMeasurementDeviation[2]*observerMeasurementDeviation[2]

  kalmanGain = cov * c_t * covPlusSensorCov.invert()

  innovation = {error[1],error[2]}
  correction = kalmanGain * innovation
  cov = cov - kalmanGain * c* cov

  --Recalculate xt, yt, vxt, vyt
  local p = sp.current
  xt= p.rx + p.cx*t + p.x0*math.cosh(t/t_zmp_x) + p.vx0*math.sinh(t/t_zmp_x)*t_zmp_x + correction[1]
  yt= p.ry + p.cy*t + p.y0*math.cosh(t/t_zmp_y) + p.vy0*math.sinh(t/t_zmp_y)*t_zmp_y + correction[2]
	vxt= p.cx + p.x0*math.sinh(t/t_zmp_x)/t_zmp_x + p.vx0*math.cosh(t/t_zmp_x) + correction[3]
  vyt= p.cy + p.y0*math.sinh(t/t_zmp_y)/t_zmp_y + p.vy0*math.cosh(t/t_zmp_y) + correction[4]

  ComputeParamY(t,yt,vyt,error[2],sp)
  ComputeParamX(t,xt,vxt,error[1],sp)
end
--]]
