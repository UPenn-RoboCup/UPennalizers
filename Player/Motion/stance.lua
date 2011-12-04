module(..., package.seeall);

require('Config')
require('Body')
require('Kinematics')
require('walk')
require('vector')
require('Transform')

active = true;
t0 = 0;

bodyHeight = Config.walk.bodyHeight;
footY = Config.walk.footY;
supportX = Config.walk.supportX;
qLArm = walk.qLArm;
qRArm = walk.qRArm;
bodyTilt=Config.walk.bodyTilt;

-- Final stance foot position6D
pTorsoStance = vector.new({0, 0, bodyHeight, 0,bodyTilt,0});
pLLeg = vector.new({-supportX, footY, 0, 0,0,0});
pRLeg = vector.new({-supportX, -footY, 0, 0,0,0});

-- Max change in position6D to reach stance:
dpLimit = vector.new({.04, .03, .07, .4, .4, .4});

tFinish=0;
tWait=0.1;

function entry()
  print("Motion SM:".._NAME.." entry");
  Body.set_syncread_enable(1); 
  started=false; 
  tFinish=0;

  Body.set_head_command({0,0});
  Body.set_head_hardness(.5);

  Body.set_larm_command(qLArm);
  Body.set_rarm_command(qRArm);

  Body.set_larm_hardness(.1);
  Body.set_rarm_hardness(.1);

  Body.set_waist_hardness(1);
  Body.set_waist_command(0);

  t0 = Body.get_time();

  walk.active=false;
end

function update()
  local t = Body.get_time();
  local dt = t - t0;

  if not started then --these init codes are moved here for OP
 	if dt>0.2 then
  	  started=true;

	  local qSensor = Body.get_sensor_position();
	  local dpLLeg = Kinematics.torso_lleg(Body.get_lleg_position());
	  local dpRLeg = Kinematics.torso_rleg(Body.get_rleg_position());

	  pTorsoL=pLLeg+dpLLeg;
	  pTorsoR=pRLeg+dpRLeg;
          pTorso=(pTorsoL+pTorsoR)*0.5;

	  Body.set_lleg_command(vector.slice(qSensor,6,17));
	  Body.set_lleg_hardness(1);
	  Body.set_rleg_hardness(1);
	  t0 = Body.get_time();
	  count=1;
	else 
	  return; 
	end
  end


  Body.set_syncread_enable(0); 

  t0 = t;
  local tol = true;
  local tolLimit = 1e-6;
  dpDeltaMax = dt*dpLimit;

  dpTorso = pTorsoStance - pTorso;
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
  q = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);
  Body.set_lleg_command(q);

  if (tol) then
	if tFinish==0 then
	   tFinish=t;
	else
	   if t-tFinish>tWait then
		    return "done"
	   end
	end
  end

end

function exit()
  walk.start();
end
