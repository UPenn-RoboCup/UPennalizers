module(..., package.seeall);

require('Body')
require('keyframe')
require('walk')
require('vector')
require('Config')

-- default kick type
kickType = "kickForwardLeft";
active = false;

bodyHeight = walk.bodyHeight;
footY = walk.footY;
bodyTilt = walk.bodyTilt;
supportX = walk.supportX;
qLArm = walk.qLArm;
qRArm = walk.qRArm;

-- pTorso fixed for stance:
pTorso = vector.new({0, 0, bodyHeight, 0,bodyTilt,0});
pTorso0 = vector.new({0, 0, bodyHeight, 0,bodyTilt,0});

--OP specific shift parameters
pTorsoShift = -0.04;
pTorsoShiftLeft0 = -0.04;
pTorsoShiftRight0 = 0.04;

qLHipRollCompensation = 5*math.pi/180;
qRHipRollCompensation = -5*math.pi/180;



pStepForward = 0.08;
pStepHeight = 0.03;
pLandHeight = 0.005; --to compensate for side flex

tWait = 0.5;
tShift = 0.6;
tKick = 0.2;
tLand = 0.5;
tStand = 0.6;

-- Final stance foot position6D
pLLegStance = vector.new({-supportX, footY, 0, 0,0,0});
pRLegStance = vector.new({-supportX, -footY, 0, 0,0,0});
pLLeg= vector.new({-supportX, footY, 0, 0,0,0});
pRLeg= vector.new({-supportX, -footY, 0, 0,0,0});


function entry()
  print(_NAME.." entry");
  walk.stop();
  started = false;
  active = true;
  if kickType == "kickForwardLeft" then 
    pTorsoShift = pTorsoShiftLeft0;
  else 
    pTorsoShift = pTorsoShiftRight0;  
  end
  -- disable joint encoder reading
  Body.set_syncread_enable(0);
end

function update()
  if (not started and not walk.active) then
    started = true;
	  Body.set_head_hardness(.5);
	  Body.set_larm_hardness(.1);
	  Body.set_rarm_hardness(.1);
	  Body.set_lleg_hardness(1);
	  Body.set_rleg_hardness(1);
	   -- start kick
	  t0 = Body.get_time();
  	  print("Kick start");
  end

  if started then
	  local t = Body.get_time();
	  local dt = t - t0-tWait;
	  if dt<0 then --Wait a bit to stabilize 

	  elseif dt<tShift then 	--Preparing kick
		pTorso[2]=pTorso0[2]+pTorsoShift*dt/tShift;
		if kickType=="kickForwardLeft" then
			Body.set_rleg_slope(8);
		else
			Body.set_lleg_slope(8);
		end		
	  elseif dt<tShift+tKick then	--Performing kick
		if kickType=="kickForwardLeft" then
			pLLeg[1]=pLLegStance[1]+pStepForward;
			pLLeg[3]=pLLegStance[3]+pStepHeight;
		else
			pRLeg[1]=pRLegStance[1]+pStepForward;
			pRLeg[3]=pRLegStance[3]+pStepHeight;
		end
	  elseif dt<tShift+tKick+tLand then	--Landing
		local dt2=(tShift+tKick+tLand-dt)/tLand;
		if kickType=="kickForwardLeft" then
			pLLeg[1]=pLLegStance[1]+pStepForward*dt2;
			pLLeg[3]=pLLegStance[3]+
				pLandHeight+(pStepHeight-pLandHeight)*dt2;
		else
			pRLeg[1]=pRLegStance[1]+pStepForward*dt2;
			pRLeg[3]=pRLegStance[3]+
				pLandHeight+(pStepHeight-pLandHeight)*dt2;

		end
	  elseif dt<tShift+tKick+tLand+tStand then	--Returning to stance
		local dt2=(tShift+tKick+tLand+tStand-dt)/tStand;
		pTorso[2]=pTorso0[2]+pTorsoShift*dt2;
	  else   
		print("Kick done");
		return "done";  
	  end
	  q = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);
	  if dt>0 then
	  	  if kickType=="kickForwardLeft" then
		  q[8] = q[8] + qRHipRollCompensation;
		  else
		  q[2] = q[2] + qLHipRollCompensation;
		  end
	  end
	  Body.set_lleg_command(q);
  else
	walk.update();
  end
end

function exit()
  print("Kick exit");
  active = false;
  walk.active=true;
  Body.set_lleg_slope(32);
  Body.set_rleg_slope(32);
end

function set_kick(newKick)
  -- set the kick type (left/right)
	kickType = newKick;
end
