------------------------------
--NSL Linear two-line head scan
------------------------------

module(..., package.seeall);

require('Body')
require('wcm')
require('mcm')

if Config.fsm.headLog then
  pitch0 = Config.fsm.headLog.pitch0 or 20*math.pi/180;
  pitchMag = Config.fsm.headScan.pitchMag or 30*math.pi/180;
  yawMag = Config.fsm.headScan.yawMag or 90*math.pi/180;
else
  pitch0 = 22.5*math.pi/180;
  pitchMag = 32.5*math.pi/180;
  yawMag = 90*math.pi/180;
end

tScan = 4.0;
timeout = tScan * 2;

t0 = 0;
direction = 1;


function entry()
  print("Head SM:".._NAME.." entry");

  -- start scan in ball's last known direction
  t0 = Body.get_time();
  ball = wcm.get_ball();
  timeout = tScan * 2;

  yaw_0, pitch_0 = HeadTransform.ikineCam(ball.x, ball.y,0);
  local currentYaw = Body.get_head_position()[1];

  if currentYaw>0 then
    direction = 1;
  else
    direction = -1;
  end
  if pitch_0>pitch0 then
    pitchDir=1;
  else
    pitchDir=-1;
  end
end

function update()
  pitchBias =  mcm.get_headPitchBias();--Robot specific head angle bias

  local t = Body.get_time();
  -- update head position


    local ph = (t-t0)/tScan;
    ph = ph - math.floor(ph);

    if ph<0.25 then --phase 0 to 0.25
      yaw=yawMag*(ph*4)* direction;
      pitch=pitch0+pitchMag*pitchDir;
    elseif ph<0.75 then --phase 0.25 to 0.75
      yaw=yawMag*(1-(ph-0.25)*4)* direction;
      pitch=pitch0-pitchMag*pitchDir;
    else --phase 0.75 to 1
      yaw=yawMag*(-1+(ph-0.75)*4)* direction;
      pitch=pitch0+pitchMag*pitchDir;
    end

  Body.set_head_command({yaw, pitch-pitchBias});
end

function exit()
end
