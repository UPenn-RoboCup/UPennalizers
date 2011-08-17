module(..., package.seeall);
name = ...;

require('vector')
require('Kinematics')
require('Body')
require('walk')

active = true;
t0 = 0;

-- These values should be in the Config file!
-- Old values from LC/HP2 days...
--bodyHeight = 0.23;
--footY = 0.0475;

bodyHeight = 0.18;--for OP sitting pose
footY = 0.0375;
supportX = 0.025; --for OP sitting pose

-- pTorso fixed for stance:
pTorso = vector.new({supportX, 0, bodyHeight, 0,0,0});
-- Final stance foot position6D
pLLegStance = vector.new({0, footY, 0, 0,0,0});
pRLegStance = vector.new({0, -footY, 0, 0,0,0});

-- Max change in postion6D to reach stance:
--dpLimit = vector.new({.01, .01, .01, .1, .1, .1});
dpLimit = vector.new({.1, .01, .03, .1, .3, .1}); --OP specific

-- THIS REALLY NEEDS TO BE FIXED, 3 or 4 params???
-- OP only uses three servos for the arm.
--qLArm = math.pi/180*vector.new({105, 12, -85, -30});
--qRArm = math.pi/180*vector.new({105, -12, 85, 30});

qLArm = math.pi/180*vector.new({105, 12,  30});
qRArm = math.pi/180*vector.new({105, -12, 30});

function entry()
  print(_NAME.." entry");

  Body.set_syncread_enable(1);--OP specific
  t0=Body.get_time();
  started=false;
  Body.set_head_command({0,0});
  Body.set_head_hardness(.8);
  Body.set_larm_hardness(.1);
  Body.set_rarm_hardness(.1);
  Body.set_lleg_hardness(.7);
  Body.set_rleg_hardness(.7);
  walk.stop();
end

function update()
  if walk.active then
     walk.update();
     return
  end
  local t = Body.get_time();
  local dt = t - t0;
--INIT code is moved here temporary for OP
  if not started then --these init codes are moved here for OP
        if 1 then
--	if dt>0.2 then
  	  started=true;
	  local qSensor = Body.get_sensor_position();
	  local dpLLeg = Kinematics.lleg_torso(Body.get_lleg_position());
	  local dpRLeg = Kinematics.rleg_torso(Body.get_rleg_position());
	  pLLeg = pTorso + dpLLeg;
	  pRLeg = pTorso + dpRLeg;
	  Body.set_actuator_command(qSensor);
          Body.set_syncread_enable(0);
	else return; end
  end


  t0 = t;

  local tol = true;
  local tolLimit = 1e-8;
  dpDeltaMax = dt*dpLimit;
  dpLeft = pLLegStance - pLLeg;
  for i = 1,6 do
    if (math.abs(dpLeft[i]) > tolLimit) then
      tol = false;
      if (dpLeft[i] > dpDeltaMax[i]) then
        dpLeft[i] = dpDeltaMax[i];
      elseif (dpLeft[i] < -dpDeltaMax[i]) then
        dpLeft[i] = -dpDeltaMax[i];
      end
    end
  end
  pLLeg = pLLeg + dpLeft;
	 
  dpRight = pRLegStance - pRLeg;
  for i = 1,6 do
    if (math.abs(dpRight[i]) > tolLimit) then
      tol = false;
      if (dpRight[i] > dpDeltaMax[i]) then
        dpRight[i] = dpDeltaMax[i];
      elseif (dpRight[i] < -dpDeltaMax[i]) then
        dpRight[i] = -dpDeltaMax[i];
      end
    end
  end
  pRLeg = pRLeg + dpRight;

  q = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);
  Body.set_lleg_command(q);

  if (tol) then
    return "done"
  end
end

function exit()
  -- Arms last
  Body.set_larm_command(qLArm);
  Body.set_rarm_command(qRArm);
end
