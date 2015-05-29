module(..., package.seeall);

require('Body')
require('vcm')

t0 = 0;
timeout = 1.0;

---
--Prepare robot to enter relax state; set body hardnesses to zero.
footX = Config.walk.footX or 0;
footY = Config.walk.footY;
supportX = Config.walk.supportX;
pLLeg = vector.new({-supportX , footY, 0, 0,0,0});
pRLeg = vector.new({-supportX , -footY, 0, 0,0,0});

hip_pitch_target = -20*math.pi/180;

ankle_pitch_target = -95*math.pi/180;
ankle_pitch_target = -105*math.pi/180;
knee_pitch_target = 120*math.pi/180;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
  if(Config.platform.name == 'OP') then
--Turn on hip yaw and roll servos
    Body.set_head_hardness(0);
    Body.set_larm_hardness(0);
    Body.set_rarm_hardness(0);
--    Body.set_lleg_command({0,0,0,0,knee_pitch_target,0,0});
--    Body.set_rleg_command({0,0,0,0,knee_pitch_target,0,0});
    
    Body.set_lleg_command({0,0,hip_pitch_target,0,0,0});
    Body.set_rleg_command({0,0,hip_pitch_target,0,0,0});

    Body.set_lleg_hardness({0.6,0.6,0.6,0,0,0});
    Body.set_rleg_hardness({0.6,0.6,0.6,0,0,0});
  elseif Config.platform.name=='NaoV4' then
    Body.set_body_hardness(0);
    Body.set_lleg_hardness({0,0,0.5,0,0,0});
    Body.set_rleg_hardness({0,0,0.5,0,0,0});


  end
  Body.set_syncread_enable(1);
  --vcm.set_vision_enable(1);
end

---
--Set actuator commands to resting position, as gotten from joint encoders.
function update()
  local t = Body.get_time();

  --Only reset leg positons, not arm positions (for waiting players)


  if Config.game.role == 5 then --Enable head movement for COACH
    Body.set_head_hardness(.5)
  end

  if(Config.platform.name == 'OP') then
    local qSensor = Body.get_sensor_position();
    qSensor[6],qSensor[7]=0,0;
    qSensor[12],qSensor[13]=0,0;
    qSensor[8],qSensor[14]=hip_pitch_target,hip_pitch_target;

    qLLeg = {0,0,hip_pitch_target, qSensor[9],qSensor[10],qSensor[11]};
    qRReg = {0,0,hip_pitch_target, qSensor[15],qSensor[16],qSensor[17]};

    Body.set_lleg_command(qLLeg);
    Body.set_rleg_command(qRLeg);
  elseif Config.platform.name == 'NaoV4' then
    --Hack for pocket (bad ankle encoder)
    qLLeg = vector.new({0,0,-52,124,-70,3})*math.pi/180;
    qRLeg = vector.new({0,0,-52,124,-70,3})*math.pi/180;
    Body.set_lleg_command(qLLeg);
    Body.set_rleg_command(qRLeg);
    --Set initial commanded values
    for i=1,6 do
      Body.commanded_joint_angles[6+i] = qLLeg[i];
      Body.commanded_joint_angles[12+i] = qRLeg[i];
    end
  else
   qLLeg = Body.get_lleg_position();
   qRLeg = Body.get_rleg_position();
  end   
  
  --update vcm body information
  local dpLLeg = Kinematics.torso_lleg(qLLeg);
  local dpRLeg = Kinematics.torso_rleg(qRLeg);

  pTorsoL=pLLeg+dpLLeg;
  pTorsoR=pRLeg+dpRLeg;
  pTorso=(pTorsoL+pTorsoR)*0.5;

  vcm.set_camera_bodyHeight(pTorso[3]);
  vcm.set_camera_bodyTilt(pTorso[5]);

  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end
