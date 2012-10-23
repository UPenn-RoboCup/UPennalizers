module(..., package.seeall);

require('Config')
require('Body')
require('Kinematics')
require('walk')
require('vector')
require('Transform')
require('vcm')
require('mcm')

active = true;
t0 = 0;

footY = Config.walk.footY;
supportX = Config.walk.supportX;
bodyHeight = Config.walk.bodyHeight;
bodyTilt = Config.stance.bodyTiltStance or 0;
qLArm = Config.walk.qLArm;
qRArm = Config.walk.qRArm;

-- Max change in position6D to reach stance:
dpLimit = Config.stance.dpLimitStance or vector.new({.04, .03, .07, .4, .4, .4});

tFinish=0;
tStartWait=0.2;
tEndWait=0.1;
tStart=0;

finished=false;

hardnessLeg = Config.stance.hardnessLeg or 1;

function entry()
  print("Motion SM:".._NAME.." entry");
  -- Final stance foot position6D
  pTorsoTarget = vector.new({0, 0, bodyHeight, 0,bodyTilt,0});
  pLLeg = vector.new({-supportX + mcm.get_footX(), footY, 0, 0,0,0});
  pRLeg = vector.new({-supportX + mcm.get_footX(), -footY, 0, 0,0,0});

  Body.set_syncread_enable(1); 
  started=false; 
  finished=false;

  tFinish=0;

  Body.set_head_command({0,0});
  Body.set_head_hardness(.5);

  Body.set_larm_command(qLArm);
  Body.set_rarm_command(qRArm);

  Body.set_larm_hardness(.1);
  Body.set_rarm_hardness(.1);

  Body.set_waist_command(0);
  Body.set_waist_hardness(1);

  t0 = Body.get_time();

  walk.active=false;
end

function update()
  local t = Body.get_time();
  local dt = t - t0;
  if finished then return; end

  --Wait a bit to read joint readings
  if not started then 
    if dt>tStartWait then
      started=true;

      local qLLeg = Body.get_lleg_position();
      local qRLeg = Body.get_rleg_position();
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
      tStart=t0;
      Body.set_syncread_enable(0); 
    else 
      Body.set_syncread_enable(1); 
      return; 
    end
  end


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
--print("BodyHeight/Tilt:",pTorso[3],pTorso[5]*180/math.pi)

  q = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);
  Body.set_lleg_command(q);

  if (tol) then
    if tFinish==0 then
      tFinish=t;
    else
      if t-tFinish>tEndWait then
        finished=true;
	print("Stand done, time elapsed",t-tStart)
        return "done"
      end
    end
  end

end

function exit()
end
