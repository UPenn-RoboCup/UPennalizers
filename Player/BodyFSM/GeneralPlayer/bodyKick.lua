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

--ball position checking params
kickTargetFront=Config.fsm.bodyKick.kickTargetFront or {0.15,0.04};
kickTargetSide=Config.fsm.bodyKick.kickTargetSide or {0.15,0.04};
kickTh=Config.fsm.bodyKick.kickTh or {0.03,0.025};


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
         if check_ball_pos() then
           phase=1;
           tStart=t;
           Motion.event("kick");
         else
           print("bodyKick: reposition")
	   walk.start();
           return "reposition";
	 end
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
  ball = wcm.get_ball();

  kick_dir=wcm.get_kick_dir();
  if kick_dir==1 then
    -- straight kick, set kick depending on ball position
    if (ball.y > 0) then
      kick.set_kick("kickForwardLeft");
      xTarget,yTarget=kickTargetFront[1],kickTargetFront[2];
    else
      kick.set_kick("kickForwardRight");
      xTarget,yTarget=kickTargetFront[1],-kickTargetFront[2];
    end
  elseif kick_dir==2 then --Kick to left
      kick.set_kick("kickSideRight");
      xTarget,yTarget=kickTargetSide[1],kickTargetSide[2];
  else --Kick to right
      kick.set_kick("kickSideLeft");
      xTarget,yTarget=kickTargetSide[1],-kickTargetSide[2];
  end

  print("Kick dir:",kick_dir)
  print("Ball position: ",ball.x,ball.y)
  print("Ball target:",xTarget,yTarget)

  ballErr = {ball.x-xTarget,ball.y-yTarget};
  print("ball error:",unpack(ballErr))
  print("Ball pos threshold:",unpack(kickTh))
  print("Ball seen:",t-ball.t," sec ago");

  if ballErr[1]<kickTh[1] and --We don't care if ball is too close
    math.abs(ballErr[2])<kickTh[2] and
    (t - ball.t <0.5) then
    return true;
  else
    return false;
  end  
end

function exit()
end
