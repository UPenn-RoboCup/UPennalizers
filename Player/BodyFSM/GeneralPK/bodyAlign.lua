module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('kick');
require('HeadFSM')
require('Config')
require('wcm')
require('walk');
require('align')

--initial wait 
tStartWait = Config.fsm.bodyKick.tStartWait or 0.5;
tStartWaitMax = Config.fsm.bodyKick.tStartWaitMax or 1.0;
thGyroMag = Config.fsm.bodyKick.thGyroMag or 100; 

--ball position checking params
kickTargetFront=Config.fsm.bodyKick.kickTargetFront or {0.15,0.04};
kickTargetSide=Config.fsm.bodyKick.kickTargetSide or {0.15,0.04};
kickTh=Config.fsm.bodyKick.kickTh or {0.03,0.025};

kickTargetFront={0.12,0.05};
kickTh={0.01,0.01,7.5*math.pi/180}; --1cm precision

t0 = 0;
tStart = 0;
timeout = 10.0;

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  walk.stop();
  phase=0;   
end

function update()
  t = Body.get_time();
  if (t - t0 > timeout) then
    return "timeout";
  end
  if walk.active or align.active then
    tStoped=t;
    return;
  end

  if phase==0 then
    if not shouldWait then phase=1;
    else
       --wait until vibration ceases
      tPassed=t-tStoped;
      imuGyr = Body.get_sensor_imuGyrRPY();
      gyrMag = math.sqrt(imuGyr[1]^2+imuGyr[2]^2);
      if tPassed>tStartWaitMax or
         (tPassed>tStartWait and gyrMag<thGyroMag) then
	phase=1;
      end
    end
  end

  if phase==1 then
   --Check ball position
    if check_ball_pos() then
      print("bodyAlign: done")
      return("done")
    else
      print("bodyAlign: reposition")
      walk.start();
      return "reposition";
    end
  end

  
end

function check_ball_pos()
  ball = wcm.get_ball();
  kick_dir=wcm.get_kick_dir();
  kick_angle=wcm.get_kick_angle();

  attackBearing, daPost = wcm.get_attack_bearing();
  angle = util.mod_angle(attackBearing-kick_angle);

  if kick_dir==1 then
    -- straight kick, set kick depending on ball position
    ball = wcm.get_ball();
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

  xErr=ball.x-xTarget;
  yErr=ball.y-yTarget;
  aErr=angle;

  local uRobot=vector.new({0,0,0});
  local uTarget=vector.new({xTarget,yTarget,0});
  local uBall=vector.new({ball.x,ball.y,angle});
  local uTargetBall=util.pose_global(-uTarget,uBall);

print("kickAngle:",kick_angle*180/math.pi)

  print("Ball",unpack(uBall));
  print("Target",unpack(uTarget));
  print("Alignment:",unpack(uTargetBall));
  print("Rotation:",180*math.pi*uTargetBall[3]);
  align.set_velocity(uTargetBall);
  if uTargetBall[2]>0 then
    align.set_supportLeg(1);
  else
    align.set_supportLeg(0);
  end

  if math.abs(xErr)<kickTh[1] and
    math.abs(yErr)<kickTh[2] and
    math.abs(angle)<kickTh[3] and    
    (t - ball.t <0.5) then
    return true;
  else
    return false;
  end  
end

function exit()
end
