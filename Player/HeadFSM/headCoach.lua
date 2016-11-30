------------------------------
--NSL Linear two-line head scan
------------------------------

module(..., package.seeall);

require('Body')
require('wcm')
require('mcm')

pitch0=Config.fsm.headScan.pitch0;
pitchMag=Config.fsm.headScan.pitchMag;
yawMag=Config.fsm.headScan.yawMag;
yawMagTurn = Config.fsm.headScan.yawMagTurn;

pitchTurn0 = Config.fsm.headScan.pitchTurn0;
pitchTurnMag = Config.fsm.headScan.pitchTurnMag;

tScan = Config.fsm.headScan.tScan*0.5;
timeout = tScan * 2;

t0 = 0;
direction = 1;


function entry()
  print('running headCoach')
  print("Head SM:".._NAME.." entry");
  wcm.set_ball_t_locked_on(0);

  yawMag=Config.fsm.headScan.yawMag;
  
  -- start scan in ball's last known direction
  t0 = Body.get_time();
  ball = wcm.get_ball();
  timeout = tScan * 2;

  yaw_0, pitch_0 = HeadTransform.ikineCam(ball.x, ball.y,0);
  local currentYaw = Body.get_head_position()[1]; 
  
  direction = 1;
  pitchDir = 1

  vcm.set_camera_command(-1); --switch camera
end

function update()
  print('updating headCoach')
  pitchBias =  mcm.get_headPitchBias();--Robot specific head angle bias

  --Is the robot in bodySearch and spinning?
  isSearching = mcm.get_walk_isSearching();

  local t = Body.get_time();
  -- update head position


  local ph = (t-t0)/tScan;
  ph = ph - math.floor(ph);
  print('ph is '..ph)
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

  local ball = wcm.get_ball();
  if(t - ball.t < 0.30) then
     print('Ball found!') 
     return 'ball';     
  end
  if (t-t0 > timeout) then
     print('headCoach timed out')
     return 'timeout';
  end

end
function exit()
end
