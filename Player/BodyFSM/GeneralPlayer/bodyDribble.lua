module(..., package.seeall);

require('Body')
require('wcm')
require('walk')
require('vector')

t0 = 0;

--Todo 
timeout = 10.0;
maxStep = 0.06;
rFar = 0.50;
tLost = 3.0;

-- default kick threshold
xTarget = Config.fsm.bodyApproach.xTarget11;
yTarget = Config.fsm.bodyApproach.yTarget11;

function check_approach_type()
  ball = wcm.get_ball();

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
  print("Dribble, target: ",xTarget[2],yTarget[2]);
end



function entry()
  print("Body FSM:".._NAME.." entry");
  t0 = Body.get_time();
  ball = wcm.get_ball();
  check_approach_type();
  kick_angle = 0;

end

function update()
  local t = Body.get_time();
  -- get ball position 
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);

--[[
  if t-ball.t<0.2 and ball_tracking==false then
    HeadFSM.sm:set_state('headTrack');
    ball_tracking=true;
    HeadFSM.sm:set_state('headKick');
  end
--]]

  -- calculate walk velocity based on ball position
  vStep = vector.new({0,0,0});
  vStep[1] = .6*(ball.x - xTarget[2]);
  vStep[2] = .75*(ball.y - yTarget[2]);
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

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

  if t-ball.t>1.5 then --missed the ball, backstep a bit
    vStep[1]=-0.03; 
  elseif t-ball.t>0.1 then --we are looking up, stop advancing
    vStep[1]=0;
  else 
    --we are tracking the ball. 
    --check ball is within threshold
    if (math.abs(ball.y) > 0.03) and (math.abs(ball.y) < 0.06) then
      vStep[1]=0.06;
    end
  end
 
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);

  if (t - ball.t > tLost) then
    HeadFSM.sm:set_state('headScan');
    print("ballLost")
    return "ballLost";
  end
  if (t - t0 > timeout) then
    HeadFSM.sm:set_state('headTrack');
    print("timeout")
    return "timeout";
  end
  if (ballR > rFar) then
    HeadFSM.sm:set_state('headTrack');
    print("ballfar, ",ballR,rFar)
    return "ballFar";
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
