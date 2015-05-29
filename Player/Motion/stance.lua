module(..., package.seeall);

require('Config')
require('Body')
require('Kinematics')
require('walk')
require('vector')
require('Transform')
require('vcm')
require('mcm')
require('walk')

active = true;
t0 = 0;

footX = Config.walk.footX or 0;
footY = Config.walk.footY;
supportX = Config.walk.supportX;
bodyHeight = Config.walk.bodyHeight;
bodyTilt=Config.walk.bodyTilt;
qLArm = Config.walk.qLArm;
qRArm = Config.walk.qRArm;

-- Max change in position6D to reach stance:
dpLimit = Config.stance.dpLimitStance or vector.new({.04, .03, .07, .4, .4, .4});

tFinish=0;
tStartWait=0.2;

tEndWait=Config.stance.delay or 0;
tEndWait=tEndWait/100;
tStart=0;

hardnessLeg = Config.stance.hardnessLeg or 1;

function entry()
  print("Motion SM:".._NAME.." entry");

  -- Final stance foot position6D
  pTorsoTarget = vector.new({-mcm.get_footX(), 0, bodyHeight, 
		0,bodyTilt,0});
  pLLeg = vector.new({-supportX , footY, 0, 0,0,0});
  pRLeg = vector.new({-supportX , -footY, 0, 0,0,0});

  Body.set_syncread_enable(1); 
  started=false; 
  tFinish=0;

  Body.set_head_command({0,0});
  Body.set_head_hardness(.5);

  Body.set_waist_hardness(1);
  Body.set_waist_command(0);

  t0 = Body.get_time();

  walk.active=false;
  --vcm.set_vision_enable(1);
  mcm.set_walk_isMoving(1); --start walk
  mcm.set_walk_isStepping(0);
end

function update()
  local t = Body.get_time();

    --For OP, wait a bit to read joint readings
  if not started then 
    if t-t0>tStartWait then
      started=true;
      local qLLeg = Body.get_lleg_position();
      local qRLeg = Body.get_rleg_position();

      --Nao uses last commanded value, not currently read value
      if Config.platform.name == 'NaoV4' then
        for i=1,6 do
	  qLLeg[i] = Body.commanded_joint_angles[6+i];
	  qRLeg[i] = Body.commanded_joint_angles[12+i];
	end
      end
      local dpLLeg = Kinematics.torso_lleg(qLLeg);
      local dpRLeg = Kinematics.torso_rleg(qRLeg);
      pTorsoL=pLLeg+dpLLeg;
      pTorsoR=pRLeg+dpRLeg;
      pTorso=(pTorsoL+pTorsoR)*0.5;

      Body.set_lleg_command(qLLeg);
      Body.set_rleg_command(qRLeg);
      Body.set_lleg_hardness(hardnessLeg);
      Body.set_rleg_hardness(hardnessLeg);
      t0 = Body.get_time();
      count=1;
      Body.set_syncread_enable(0); 
    else 
      Body.set_syncread_enable(1); 
      return; 
    end
  end

  local dt = t - t0;
  t0 = t;
  local tol = true;
  local tolLimit = 1e-6;
  dpDeltaMax = dt*dpLimit;

  dpTorso = pTorsoTarget - pTorso;
  for i = 1,6 do
    if (math.abs(dpTorso[i]) > tolLimit) then
      tol = false;
      if (dpTorso[i] > dpDeltaMax[i]) then
        dpTorso[i] = dpDeltaMax[i];
      elseif (dpTorso[i] < -dpDeltaMax[i]) then
        dpTorso[i] = -dpDeltaMax[i];
      end
    end
  end

  pTorso=pTorso+dpTorso;

  vcm.set_camera_bodyHeight(pTorso[3]);
  vcm.set_camera_bodyTilt(pTorso[5]);

  pTorsoActual = {
	pTorso[1],
	pTorso[2],
	pTorso[3],
	pTorso[4],
	pTorso[5],
	pTorso[6]}

  if walk.has_ball and walk.has_ball>0 then
    pTorsoActual[1] = pTorsoActual[1] - 0.01;
  end

  q = Kinematics.inverse_legs(pLLeg, pRLeg, pTorsoActual, 0);
  --print(q[9])
  Body.set_lleg_command(q);

  if (tol) then
    if tFinish==0 then
      tFinish=t;
--[[
      Body.set_larm_command(qLArm);
      Body.set_rarm_command(qRArm);
      Body.set_larm_hardness(.1);
      Body.set_rarm_hardness(.1);
--]]
    else
      if t-tFinish>tEndWait then
	print("Stand done, time elapsed",t-tStart)
	vcm.set_camera_bodyHeight(Config.walk.bodyHeight);
	vcm.set_camera_bodyTilt(Config.walk.bodyTilt);
	walk.stance_reset();
        if Config.disable_walk then
        else
	       walk.start();
       end
        return "done"
      end
    end
  end

end

function exit()
end
