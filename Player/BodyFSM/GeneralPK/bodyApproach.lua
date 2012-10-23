module(..., package.seeall);

require('Body')
require('wcm')
require('walk')
require('vector')

t0 = 0;
timeout = Config.fsm.bodyApproach.timeout;
maxStep = Config.fsm.bodyApproach.maxStep; -- maximum walk velocity
rFar = Config.fsm.bodyApproach.rFar;-- maximum ball distance threshold
tLost = Config.fsm.bodyApproach.tLost; --ball lost timeout

-- default kick threshold
xTarget = Config.fsm.bodyApproach.xTarget11;
yTarget = Config.fsm.bodyApproach.yTarget11;

xTarget = {0, 0.14,0.15}; --min, target, max


function check_approach_type()
  ball = wcm.get_ball();
  kick_dir=wcm.get_kick_dir();
  kick_type=wcm.get_kick_type();
  kick_angle=wcm.get_kick_angle();

  print("Approach: kick dir /type /angle",kick_dir,kick_type,kick_angle*180/math.pi)

  y_inv=0;
  xTarget = Config.fsm.bodyApproach.xTarget11;
  yTarget0 = Config.fsm.bodyApproach.yTarget11;
  if sign(ball.y)<0 then y_inv=1;end

  if y_inv>0 then
    yTarget[1],yTarget[2],yTarget[3]=
      -yTarget0[3],-yTarget0[2],-yTarget0[1];
  else
     yTarget[1],yTarget[2],yTarget[3]=
       yTarget0[1],yTarget0[2],yTarget0[3];
  end

  print("Approach, target: ",xTarget[2],yTarget[2]);
end

function entry()
  print("Body FSM:".._NAME.." entry");
  t0 = Body.get_time();
  ball = wcm.get_ball();
  check_approach_type(); --walkkick if available
  HeadFSM.sm:set_state('headTrack');
end

function update()
  local t = Body.get_time();

  -- get ball position
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);

  -- calculate walk velocity based on ball position
  vStep = vector.new({0,0,0});
  vStep[1] = .6*(ball.x - xTarget[2]);
  vStep[2] = .75*(ball.y - yTarget[2]);
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

  --Player FSM, turn towards the goal
  attackBearing, daPost = wcm.get_attack_bearing();
  angle = util.mod_angle(attackBearing-kick_angle);
  if angle > 10*math.pi/180 then
    vStep[3]=0.2;
  elseif angle < -10*math.pi/180 then
    vStep[3]=-0.2;
  else
    vStep[3]=0;
  end


  --when the ball is on the side, backstep a bit
  local wAngle = math.atan2 (vStep[2], vStep[1]);
  if math.abs(wAngle) > 70*math.pi/180 then
    vStep[1]=vStep[1] - 0.03;
  end
 
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);

  if (t - ball.t > tLost) then
    print("ballLost")
    return "ballLost";
  end
  if (t - t0 > timeout) then
    print("timeout")
    return "timeout";
  end
  if (ballR > rFar) then
    print("ballfar, ",ballR,rFar)
    return "ballFar";
  end

--  print("Ball xy:",ball.x,ball.y);
--  print("Threshold xy:",xTarget[3],yTarget[3]);

  --TODO: angle threshold check
  if (ball.x < xTarget[3]) and (t-ball.t < 0.3) and
     (ball.y > yTarget[1]) and (ball.y < yTarget[3]) then
    if kick_type==1 then return "kick";
    else return "walkkick";
    end
  end
end

function exit()
  HeadFSM.sm:set_state('headTrack');
end

function sign(x)
  if (x > 0) then return 1;
  elseif (x < 0) then return -1;
  else return 0;
  end
end
