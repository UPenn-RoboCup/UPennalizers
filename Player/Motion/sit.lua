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

footX = mcm.get_footX();
footY = Config.walk.footY;
supportX = Config.walk.supportX;

footXSit = Config.stance.footXSit or 0;
bodyHeightSit = Config.stance.bodyHeightSit;
bodyTiltSit = Config.stance.bodyTiltSit or 0;

-- Final stance foot position6D
pTorsoTarget = vector.new({-footXSit, 0, bodyHeightSit, 0,bodyTiltSit,0});
pLLeg = vector.new({-supportX, footY, 0, 0,0,0});
pRLeg = vector.new({-supportX, -footY, 0, 0,0,0});

qLArm = Config.stance.qLArmSit;
qRArm = Config.stance.qRArmSit;

-- Max change in postion6D to reach stance:
dpLimit=Config.stance.dpLimitSit or vector.new({.1,.01,.03,.1,.3,.1});

tStartWait = 0.2;
tFinish=0;
tStart=0;

function entry()
  print("Motion SM:".._NAME.." entry");

  walk.stop();
  started=false;
  --This makes the robot look up and see goalposts while sitting down
  Body.set_head_command({0,-20*math.pi/180});
  Body.set_head_hardness(.5);
  Body.set_larm_hardness(.1);
  Body.set_rarm_hardness(.1);
  t0=Body.get_time();
  Body.set_syncread_enable(1); 
end

function update()
  local t = Body.get_time();
  if walk.active then
     walk.update();
     t0=Body.get_time();
     return;
  end


--Sit init using joint encoder
  if not started then 
    if t-t0>tStartWait then
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
      Body.set_lleg_hardness(0.7);
      Body.set_rleg_hardness(0.7);
      t0 = Body.get_time();
      count=1;
      Body.set_syncread_enable(0); 

      if qLArm then
        Body.set_larm_command(qLArm);
        Body.set_rarm_command(qRArm);
        Body.set_larm_hardness(0.4);
        Body.set_rarm_hardness(0.4);
      end


    else 
      Body.set_syncread_enable(1); 
      return; 
    end
  end

--[[
--Sit init NOT using joint encoder 
  if not started then 
    started=true;
    --Now we assume that the robot always start sitting from stance position
    pTorso = vector.new({-footX,0,vcm.get_camera_bodyHeight(),
	  	         0,vcm.get_camera_bodyTilt(),0});
    pLLeg = vector.new({-supportX,footY,0,0,0,0});
    pRLeg= vector.new({-supportX,-footY,0,0,0,0});
    Body.set_lleg_hardness(1);
    Body.set_rleg_hardness(1);
    t0 = Body.get_time();
    tStart=t;
    count=1;
  end
--]]
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
  q = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);
  Body.set_lleg_command(q);

  if Config.platform.name == 'NaoV4' then
    for i=1,12 do 
      Body.commanded_joint_angles[6+i] = q[i];
    end
  end

  if (tol) then
    print("Sit done, time elapsed",t-tStart)
    return "done"
  end

end

function exit()
end
