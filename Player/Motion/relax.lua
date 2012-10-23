module(..., package.seeall);

require('Body')

t0 = 0;
timeout = 1.0;

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
  else
    Body.set_body_hardness(0);
  end
  Body.set_syncread_enable(1);
end

function update()
  local t = Body.get_time();

  --Only reset leg positons, not arm positions (for waiting players)

  if(Config.platform.name == 'OP') then
    local qSensor = Body.get_sensor_position();
    qSensor[6],qSensor[7]=0,0;
    qSensor[12],qSensor[13]=0,0;
    qSensor[8],qSensor[14]=hip_pitch_target,hip_pitch_target;

    qLLeg = {0,0,hip_pitch_target, qSensor[9],qSensor[10],qSensor[11]};
    qRReg = {0,0,hip_pitch_target, qSensor[15],qSensor[16],qSensor[17]};

    Body.set_lleg_command(qLLeg);
    Body.set_rleg_command(qRLeg);
  else
    local qSensor = Body.get_sensor_position();
    Body.set_actuator_command(qSensor);
  end

  --update vcm body information
  local qLLeg = Body.get_lleg_position();
  local qRLeg = Body.get_rleg_position();
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
