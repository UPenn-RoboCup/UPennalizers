module(..., package.seeall);

require('Body')
require('wcm')
require('walk')
require('vector')
require('walk')
require('position')

t0 = 0;
timeout = Config.fsm.bodyApproach.timeout;
maxStep = Config.fsm.bodyApproach.maxStep; -- maximum walk velocity
rFar = Config.fsm.bodyApproach.rFar;-- maximum ball distance threshold
tLost = Config.fsm.bodyApproach.tLost; --ball lost timeout

-- default kick threshold
xTarget = Config.fsm.bodyApproach.xTarget11;
yTarget = Config.fsm.bodyApproach.yTarget11;

dapost_check = Config.fsm.daPost_check or 0;
daPostMargin = Config.fsm.daPostMargin or 15*math.pi/180;

fast_approach = Config.fsm.fast_approach or 0;
enable_evade = Config.fsm.enable_evade or 0;
evade_count=0;

function check_approach_type()
  is_evading = 0;
  check_angle=1;
  ball = wcm.get_ball();
  kick_dir=wcm.get_kick_dir();
  kick_type=wcm.get_kick_type();
  kick_angle=wcm.get_kick_angle();

  role = gcm.get_team_role();

  --Evading kick check
  do_evade_kick=false;
  if enable_evade==1 and role>0 then
    evade_count = evade_count+1;
    if evade_count % 2 ==0 then
      do_evade_kick=true;
    end
  elseif enable_evade==2 then

-- Hack : use localization info to detect obstacle
-- We should use vision
    obstacle_num = wcm.get_obstacle_num();
    obstacle_x = wcm.get_obstacle_x();
    obstacle_y = wcm.get_obstacle_y();
    obstacle_dist = wcm.get_obstacle_dist();

    for i=1,obstacle_num do
      if obstacle_dist[i]<0.60 then
        obsAngle = math.atan2(obstacle_y[i],obstacle_x[i]);
        if math.abs(obsAngle) < 40*math.pi/180 then
  	  do_evade_kick = true;
        end
      end
    end
  end


  if do_evade_kick then
    print("EVADE KICK!!!")
    pose=wcm.get_pose();
    goalDefend = wcm.get_goal_defend();
    --Always sidekick to center side
    if (pose.y>0 and goalDefend[1]>0) or
       (pose.y<0 and goalDefend[1]<0) then
      kick_type = 2;
      kick_dir = 2; --kick to the right
      wcm.set_kick_dir(kick_dir);
      wcm.set_kick_type(kick_type);
    else
      kick_type = 2;
      kick_dir = 3; --kick to the left
      wcm.set_kick_dir(kick_dir);
      wcm.set_kick_type(kick_type);
    end
    check_angle = 0; --Don't check angle if we're doing evade kick
  end

--  if role==0 then
  if false then
    --Goalie always approach the ball directly without turning
    position.posCalc();
    pose=wcm.get_pose();
    aGoal = wcm.get_goal_attack_angle2(); --Global angle to goal
    aRot = util.mod_angle(aGoal - pose.a);    
    th_sidekick = math.pi*60/180;

    if aRot > th_sidekick then 
      --stationary kick to the right
      kick_type = 1;
      kick_dir = 2;
      kickAngle = 90*math.pi/180;

    elseif aRot<-th_sidekick then
      --stationary kick to the left
      kick_type = 1;
      kick_dir = 3;
      kickAngle = -90*math.pi/180;
    else
      kickAngle = 0*math.pi/180;
      if Config.fsm.goalie_use_walkkick>0 then
        --walkkick to front
        kick_type = 2;
      else
        --stationary kick to front
        kick_type = 1;
      end
      kick_dir = 1;
    end
    wcm.set_kick_dir(kick_dir);
    wcm.set_kick_type(kick_type);
    wcm.set_kick_angle(kickAngle);

--    check_angle = 0; --Don't check angle during approaching
    check_angle = 1; --CHECK angle during approaching
  end

  print("Approach: kick dir /type /angle",kick_dir,kick_type,kick_angle*180/math.pi)

  y_inv=0;
  if kick_type==1 then --Stationary 
    if kick_dir==1 then --Front kick
      xTarget = Config.fsm.bodyApproach.xTarget11;
      yTarget0 = Config.fsm.bodyApproach.yTarget11;
      if sign(ball.y)<0 then y_inv=1;end
    elseif kick_dir==2 then --Kick to the left
      xTarget = Config.fsm.bodyApproach.xTarget12;
      yTarget0 = Config.fsm.bodyApproach.yTarget12;
    else --Kick to the right
      xTarget = Config.fsm.bodyApproach.xTarget12;
      yTarget0 = Config.fsm.bodyApproach.yTarget12;
      y_inv=1;
    end
  else --walkkick
    if kick_dir==1 then --Front kick
      xTarget = Config.fsm.bodyApproach.xTarget21;
      yTarget0 = Config.fsm.bodyApproach.yTarget21;
      if sign(ball.y)<0 then y_inv=1; end
    elseif kick_dir==2 then --Kick to the left
      xTarget = Config.fsm.bodyApproach.xTarget22;
      yTarget0 = Config.fsm.bodyApproach.yTarget22;
    else --Kick to the right
      xTarget = Config.fsm.bodyApproach.xTarget22;
      yTarget0 = Config.fsm.bodyApproach.yTarget22;
      y_inv=1;
    end
  end

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

  if t0-ball.t<0.2 then
    ball_tracking=true;
    print("Ball Tracking")
    HeadFSM.sm:set_state('headKick');
  else
    ball_tracking=false;
  end

  role = gcm.get_team_role();
  if role==0 then
    aThresholdTurn = Config.fsm.bodyApproach.aThresholdTurnGoalie;
  else
    aThresholdTurn = Config.fsm.bodyApproach.aThresholdTurn;
  end
end

function update()
  local t = Body.get_time();
  -- get ball position 
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);

  if t-ball.t<0.2 and ball_tracking==false then
    ball_tracking=true;
    HeadFSM.sm:set_state('headKick');
  end

  --Current cordinate origin: midpoint of uLeft and uRight
  --Calculate ball position from future origin
  --Assuming we stop at next step
  if fast_approach == 1 then
    uLeft = walk.uLeft;
    uRight = walk.uRight;
    uFoot = util.se2_interpolate(0.5,uLeft,uRight); --Current origin 
    if walk.supportLeg ==0 then --left support 
      uRight2 = walk.uRight2;
      uLeft2 = util.pose_global({0,2*walk.footY,0},uRight2);
    else --Right support
      uLeft2 = walk.uLeft2;
      uRight2 = util.pose_global({0,-2*walk.footY,0},uLeft2);
    end
    uFoot2 = util.se2_interpolate(0.5,uLeft2,uRight2); --Projected origin 
    uMovement = util.pose_relative(uFoot2,uFoot);
    uBall2 = util.pose_relative({ball.x,ball.y,0},uMovement);
    ball.x=uBall2[1];
    ball.y=uBall2[2];
    factor_x = 0.8;
  else
    factor_x = 0.6;
  end

  
  -- calculate walk velocity based on ball position
  vStep = vector.new({0,0,0});
  vStep[1] = factor_x*(ball.x - xTarget[2]);
  vStep[2] = .75*(ball.y - yTarget[2]);
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

  if Config.fsm.playMode==1 then 
    --Demo FSM, just turn towards the ball
    ballA = math.atan2(ball.y - math.max(math.min(ball.y, 0.05), -0.05),
            ball.x+0.10);
    vStep[3] = 0.5*ballA;
    targetangle = 0;
    angleErrL = 0;
    angleErrR = 0;

  else
    --Player FSM, turn towards the goal
--    attackBearing, daPost = wcm.get_attack_bearing();
    position.posCalc();

    kickAngle = wcm.get_kick_angle();
    attackAngle = wcm.get_goal_attack_angle2()-kickAngle;
    daPost = wcm.get_goal_daPost2();

    if dapost_check == 0 then
      daPost1 = 2*aThresholdTurn;
    else
      daPost1 = math.max(2*aThresholdTurn,daPost - daPostMargin);
    end

    --Wider margin for sidekicks and goalies
    if kick_dir~=1 or role==0 then 
      daPost1 = math.max(25*math.pi/180,daPost1);
    end

    pose=wcm.get_pose();

    angleErrL = util.mod_angle(pose.a - (attackAngle + daPost1 * 0.5));
    angleErrR = util.mod_angle((attackAngle - daPost1 * 0.5)-pose.a);

    --If we have room for turn, turn to the ball
    angleTurnMargin = -10*math.pi/180;
    ballA = math.atan2(ball.y - math.max(math.min(ball.y, 0.05), -0.05),
            ball.x+0.10);
    if angleErrL < angleTurnMargin and ballA > 0 then
      vStep[3] = 0.5*ballA;
    elseif angleErrR < angleTurnMargin and ballA < 0 then
      vStep[3] = 0.5*ballA;
    end    


    if check_angle>0 then

      if angleErrR > 0 then
--print("TURNLEFT")
        vStep[3]=0.2;
      elseif angleErrL > 0 then
--print("TURNRIGHT")
        vStep[3]=-0.2;
      else
        vStep[3]=0;
      end
    end
  end

  --when the ball is on the side of the ROBOT, backstep a bit
  local wAngle = math.atan2 (ball.y,ball.x);

  ballYMin = Config.fsm.bodyApproach.ballYMin or 0.20;


  if math.abs(wAngle) > 45*math.pi/180 then
    vStep[1]=vStep[1] - 0.03;

    if ball.y<ballYMin and ball.y>0 then
     vStep[2] = -0.03;
    elseif ball.y<0 and ball.y>-ballYMin then
      vStep[2]=0.03;
    else
      vStep[2] = 0;
    end    

  else
    --Otherwise, don't make robot backstep
    vStep[1]=math.max(0,vStep[1]);
  end




  if walk.ph>0.95 then 
    print(string.format("Ball position: %.2f %.2f\n",ball.x,ball.y));
    print(string.format("Approach velocity:%.2f %.2f\n",vStep[1],vStep[2]));
  end

 
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);

  if (t - ball.t > tLost) and role>0 then
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

  angle_check_done = true;
  if check_angle>0 and
     (angleErrL > 0 or
     angleErrR > 0 )then
    angle_check_done=false;
  else
  end

  --For front kick, check for other side too
  if kick_dir==1 then --Front kick
    yTargetMin = math.min(math.abs(yTarget[1]),math.abs(yTarget[3]));
    yTargetMax = math.max(math.abs(yTarget[1]),math.abs(yTarget[3]));

    if (ball.x < xTarget[3]) and (t-ball.t < 0.5) and
       (math.abs(ball.y) > yTargetMin) and 
	(math.abs(ball.y) < yTargetMax) and
	angle_check_done then
      print(string.format("Approach done, ball position: %.2f %.2f\n",ball.x,ball.y))
      print(string.format("Ball target: %.2f %.2f\n",xTarget[2],yTarget[2]))
      if kick_type==1 then return "kick";
      else return "walkkick";
      end
    end
  else
    --Side kick, only check one side
    if (ball.x < xTarget[3]) and (t-ball.t < 0.5) and
       (ball.y > yTarget[1]) and (ball.y < yTarget[3]) and
       angle_check_done then

      print(string.format("Approach done, ball position: %.2f %.2f\n",ball.x,ball.y))
      print(string.format("Ball target: %.2f %.2f\n",xTarget[2],yTarget[2]))
      if kick_type==1 then return "kick";
      else return "walkkick";
      end
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
