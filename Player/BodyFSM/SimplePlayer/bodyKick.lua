module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('kick');
require('HeadFSM')
require('Config')
require('wcm')
require('walk');

--initial wait 
tStartWait = Config.fsm.bodyKick.tStartWait or 0.5;
tStartWaitMax = Config.fsm.bodyKick.tStartWaitMax or 1.0;
thGyroMag = Config.fsm.bodyKick.thGyroMag or 100; 

--headFollow delay
tFollowDelay = Config.fsm.bodyKick.tFollowDelay;

t0 = 0;
tStart = 0;
timeout = 10.0;
phase=0; --0 for init.wait, 1 for kicking, 2 for headFollow
kickable = true;

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  --SJ - only initiate kick while walking
  kickable = walk.active;  
  walk.stop();
  phase=0;   
end

function update()
  t = Body.get_time();
  if not kickable then 
     print("bodyKick escape");
     --Set velocity to 0 after kick fails ot prevent instability--
     walk.set_velocity(0, 0, 0);
     return "done";
  end

  if (t - t0 > timeout) then
    print("bodyKick timeout")
    return "timeout";
  end

  --wait until vibration ceases
  if phase==0 and not walk.active then
    tPassed=t-t0;
    imuGyr = Body.get_sensor_imuGyrRPY();
    gyrMag = math.sqrt(imuGyr[1]^2+imuGyr[2]^2);

    if tPassed>tStartWaitMax or
       (tPassed>tStartWait and gyrMag<thGyroMag) then
         phase=1;
         tStart=t;
         check_ball_pos();
         Motion.event("kick");
    end
  elseif phase==1 then
  --Wait a bit and try find the ball
    if t-tStart > tFollowDelay then
      phase=2;
      HeadFSM.sm:set_state('headKickFollow');
    end
  elseif phase==2 then
  --Wait until kick is over
    if not kick.active then
      walk.still=true;
      walk.set_velocity(0, 0, 0);
      walk.start();
      return "done";
    end
  end
end

function check_ball_pos()
  -- straight kick, set kick depending on ball position
  ball = wcm.get_ball();

  if (ball.y > 0) then
    kick.set_kick("kickForwardLeft");
  else
    kick.set_kick("kickForwardRight");
  end
  return true;
end

function exit()
end
