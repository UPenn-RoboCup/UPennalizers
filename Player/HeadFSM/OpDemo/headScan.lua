------------------------------
--NSL Linear two-line head scan
------------------------------

module(..., package.seeall);

require('Body')
require('wcm')
require('mcm')

t0 = 0;

-- scan period
tScan = 3.0*Config.speedFactor;
timeout = tScan * 2;
direction = 1;

pitch0=25*math.pi/180;
pitchMag=25*math.pi/180;
yawMag=90*math.pi/180;
yawMagTurn = 45*math.pi/180;

pitchTurn0 = 20 * math.pi/180;
pitchTurnMag = 20 * math.pi/180;

--Robot specific head pitch bias
headPitch = Config.walk.headPitch or 0;

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
  --Is the robot in bodySearch and spinning?
  isSearching = mcm.get_walk_isSearching();

  local t = Body.get_time();
  -- update head position

  -- Scan left-right and up-down with constant speed
  if isSearching ==0 then --Normal headScan
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

  else --Rotating scan
    timeout = 20.0 * Config.speedFactor; --Longer timeout
    local ph = (t-t0)/tScan * 2;
    ph = ph - math.floor(ph);
    --Look up and down in constant speed
    if ph<0.25 then
      pitch=pitchTurn0+pitchTurnMag*(ph*4);
    elseif ph<0.75 then
      pitch=pitchTurn0+pitchTurnMag*(1-(ph-0.25)*4);
    else
      pitch=pitchTurn0+pitchTurnMag*(-1+(ph-0.75)*4);
    end
    yaw = yawMagTurn * isSearching;
  end

  Body.set_head_command({yaw, pitch-headPitch});

  local ball = wcm.get_ball();
  if (t - ball.t < 0.1) then
    return "ball";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end
