module(..., package.seeall);
name = ...;

require('Config')
require('vector')
require('Kinematics')
require('Body')
require('walk')
require('mcm')

active = true;
t0 = 0;

footY = Config.walk.footY;
supportX = Config.walk.supportX;
bodyHeight = Config.stance.bodyHeightDive or 0.25;
bodyTilt = Config.stance.bodyTiltDive or 0;


-- Max change in postion6D to reach stance:
dpLimit=Config.stance.dpLimitDive or 
vector.new({.1,.01,.03,.1,.3,.1});

tFinish=0;
tStartWait=0.2;
tEndWait=0.1;
tStart=0;
finished=false;

function entry()
  print("Motion SM:".._NAME.." entry");

  footX = mcm.get_footX();
  -- Final stance foot position6D
  pTorsoTarget = vector.new({0, 0, bodyHeight, 0,bodyTilt,0});
  pLLeg = vector.new({-supportX + footX, footY, 0, 0,0,0});
  pRLeg = vector.new({-supportX + footX, -footY, 0, 0,0,0});

  walk.stop();
  started=false;
  finished=false;

--  Body.set_head_hardness(.5);
  Body.set_larm_hardness(.1);
  Body.set_rarm_hardness(.1);
  t0=Body.get_time();

end

function update()
  local t = Body.get_time();
  if walk.active then
     walk.update();
     t0=Body.get_time();
     return;
  end
  if finished then 
    return; 
  end

  local dt = t - t0;
  if not started then 
   --For OP, wait a bit to read joint readings
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
      Body.set_lleg_hardness(1);
      Body.set_rleg_hardness(1);
      t0 = Body.get_time();
      tStart=t;
      count=1;
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
--  print("BodyHeight/Tilt:",pTorso[3],pTorso[5]*180/math.pi)

  q = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);
  Body.set_lleg_command(q);

  if (tol) then
    if tFinish==0 then
      tFinish=t;
    else
      if t-tFinish>tEndWait then
	finished=true;
	print("Sit done, time elapsed",t-tStart)
      end
    end
  end

end

function exit()
  Body.set_syncread_enable(1); 
end
