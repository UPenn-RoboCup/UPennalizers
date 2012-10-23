module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')

rTurn= Config.fsm.bodyPosition.rTurn;
rTurn2= Config.fsm.bodyPosition.rTurn2;
rDist1= Config.fsm.bodyPosition.rDist1;
rDist2= Config.fsm.bodyPosition.rDist2;
rOrbit= Config.fsm.bodyPosition.rOrbit;

maxStep1 = Config.fsm.bodyPosition.maxStep1;

maxStep2 = Config.fsm.bodyPosition.maxStep2;
rVel2 = Config.fsm.bodyPosition.rVel2 or 0.5;
aVel2 = Config.fsm.bodyPosition.aVel2 or 45*math.pi/180;
maxA2 = Config.fsm.bodyPosition.maxA2 or 0.2;
maxY2 = Config.fsm.bodyPosition.maxY2 or 0.02;

maxStep3 = Config.fsm.bodyPosition.maxStep3;
rVel3 = Config.fsm.bodyPosition.rVel3 or 0.8;
aVel3 = Config.fsm.bodyPosition.aVel3 or 30*math.pi/180;
maxA3 = Config.fsm.bodyPosition.maxA3 or 0.1;
maxY3 = Config.fsm.bodyPosition.maxY3 or 0;

dapost_check = Config.fsm.daPost_check or 0;
variable_dapost = Config.fsm.variable_dapost or 0;

function posCalc()
  ball=wcm.get_ball();
  pose=wcm.get_pose();
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  ballxy=vector.new( {ball.x,ball.y,0} );
  tBall = Body.get_time() - ball.t;
  posexya=vector.new( {pose.x, pose.y, pose.a} );
  ballGlobal=util.pose_global(ballxy,posexya);

  if gcm.get_team_color() == 1 then
    -- red attacks cyan goal
    postAttack = PoseFilter.postCyan;
  else
    -- blue attack yellow goal
    postAttack = PoseFilter.postYellow;
  end

  aBallLocal=math.atan2(ball.y,ball.x); 
  aBall=math.atan2(ballGlobal[2]-pose.y, ballGlobal[1]-pose.x);

  goalGlobal=wcm.get_goal_attack();
  LPost = postAttack[1];
  RPost = postAttack[2];
  aGoal1 = math.atan2(LPost[2]-ballGlobal[2],LPost[1]-ballGlobal[1]);
  aGoal2 = math.atan2(RPost[2]-ballGlobal[2],RPost[1]-ballGlobal[1]);
  daPost = math.abs(util.mod_angle(aGoal1-aGoal2));
  
  aGoal = aGoal2 + 0.5 * daPost;

  rGoalBall = math.sqrt( (goalGlobal[2]-ballGlobal[2])^2+
			(goalGlobal[1]-ballGlobal[1])^2);

  --Near-goal handling
  thNearGoal = 80*math.pi/180;
  daNearGoal = 20*math.pi/180;
  shiftNearGoal = 0.8;
  rMinGoal = 0.7;

  if math.abs(aGoal)>thNearGoal and
     math.abs(util.mod_angle(aGoal-math.pi))>thNearGoal and
     daPost<daNearGoal and
     rGoalBall> rMinGoal then
    goalGlobal[1] = goalGlobal[1] - util.sign(goalGlobal[1])*shiftNearGoal;
    aGoal=math.atan2(goalGlobal[2]-ballGlobal[2],goalGlobal[1]-ballGlobal[1]);
    aGoal1 = aGoal + 10* math.pi/180;
    aGoal2 = aGoal - 10* math.pi/180;
    daPost = 20*math.pi/180;
  end

  --Far-goal handling : widen the goalpost 
  rMinGoal2 = 5.0;
  if rGoalBall > rMinGoal2 and variable_dapost>0 then
    aGoal1 = math.atan2(LPost[2]*1.5-ballGlobal[2],LPost[1]-ballGlobal[1]);
    aGoal2 = math.atan2(RPost[2]*1.5-ballGlobal[2],RPost[1]-ballGlobal[1]);
    daPost = math.abs(util.mod_angle(aGoal1-aGoal2));
    aGoal = aGoal2 + 0.5 * daPost;
  end

  --Kick target angle
  wcm.set_goal_attack_angle2(aGoal); 
  wcm.set_goal_daPost2(daPost);
end

function getDirectAttackerHomePose()
  posCalc();
  local homepose={ballGlobal[1],ballGlobal[2], aBall};
  return homepose;
end


function getAttackerHomePose()
  posCalc();
  --In what angle should we approach the ball?
  daPostMargin = Config.fsm.daPostMargin or 15* math.pi/180;
  daPost1 = math.max(0, daPost - daPostMargin);


  kickAngle = wcm.get_kick_angle();
  aGoal = aGoal - kickAngle;

  aGoalL = aGoal + daPost1 * 0.5;
  aGoalR = aGoal - daPost1 * 0.5;

  --How much we need to turn?
  angle1 = util.mod_angle(aGoalL - aBall);
  angle2 = util.mod_angle(aGoalR - aBall);
  if angle1 < 0 then
--print("AIMING LEFT")
    angle2Turn = angle1;
    aGoalSelected = aGoalL;
  elseif angle2 > 0 then
--print("AIMING RIGHT")
    angle2Turn = angle2;
    aGoalSelected = aGoalR;
  else --go straight
    angle2Turn = 0;
    aGoalSelected = pose.a;
  end

  --Disable left-right check
  if dapost_check==0 then
    aGoalSelected = aGoal;
    angle2Turn = util.mod_angle(aGoal-aBall);
  end

  --Curved approach
  if math.abs(angle2Turn)<math.pi/2 then
--    rDist=math.min(rDist1,math.max(rDist2,ballR-rTurn2));
    --New approach
    rDist = math.min(
        rDist2 + (rDist1-rDist2) * math.abs(angle2Turn)/(math.pi/2),
        ballR
        );    
    local homepose={
        ballGlobal[1]-math.cos(aGoalSelected)*rDist,
        ballGlobal[2]-math.sin(aGoalSelected)*rDist,
        aGoalSelected};
    return homepose;

  --Circle around the ball
  elseif angle1>0 then
    local homepose={
        ballGlobal[1]+math.cos(-aBall+math.pi/2)*rOrbit,
        ballGlobal[2]-math.sin(-aBall+math.pi/2)*rOrbit,
        aBall};
    return homepose;
  else
    local homepose={
        ballGlobal[1]+math.cos(-aBall-math.pi/2)*rOrbit,
        ballGlobal[2]-math.sin(-aBall-math.pi/2)*rOrbit,
        aBall};
    return homepose;
  end
end



------------------------------------------------------------------
-- Defender
------------------------------------------------------------------



--Simple defender
function getDefenderHomePose0()
  posCalc();

  homePosition = .6 * ballGlobal;
  homePosition[1] = homePosition[1] - 0.50*util.sign(homePosition[1]);
  homePosition[2] = homePosition[2] - 0.80*util.sign(homePosition[2]);
  relBallX = ballGlobal[1]-homePosition[1];
  relBallY = ballGlobal[2]-homePosition[2];

  -- face ball 
  homePosition[3] = util.mod_angle(math.atan2(relBallY, relBallX));
  return homePosition;
end


function getDefenderHomePose()
  posCalc();

  goal_defend=wcm.get_goal_defend();
  relBallX = ballGlobal[1]-goal_defend[1];
  relBallY = ballGlobal[2]-goal_defend[2];
  RrelBall = math.sqrt(relBallX^2+relBallY^2)+0.001;

  --Check attacker position
  attacker_pose = wcm.get_team_attacker_pose();
  
  goalie_alive = wcm.get_team_goalie_alive();
  
  attacker_goal_dist = math.sqrt(
	(attacker_pose[1] - goal_defend[1])^2+
	(attacker_pose[2] - goal_defend[2])^2
	);

  defender_goal_dist = math.sqrt(
	(pose.x - goal_defend[1])^2+
	(pose.y - goal_defend[2])^2
	);

  homePosition = {};

  defending_type = 1; 

  support_dist = Config.team.support_dist or 3.0;
  supportPenalty = Config.team.supportPenalty or 0.3;


  --How close is the ball to our goal?
  if RrelBall < support_dist then --Ball close to our goal
    --Are our attacker closer to the ball than me?
    if attacker_goal_dist < defender_goal_dist - supportPenalty then
      --Attacker is closer to our goal
      defending_type = 2; --Go back to side of our field
    else --Defender closer to our goal
      defending_type = 1; --Center defender
    end
  else --Ball in their field
    if attacker_goal_dist < defender_goal_dist - supportPenalty then
       --Attacker closer to the our goal
      defending_type = 3; --Supporter
    else
      --Stay in defending position
      --TODO: we can still go support
      defending_type = 1;      
--      defending_type = 3;      
    end
  end

  if defending_type == 1 then
    --Center defender
    if goalie_alive>0 then 
      distGoal,sideGoal = 1.5, 0.3;
    else
      distGoal,sideGoal = 1.0, 0; --We don't have goalie!
    end
    homePosition[1]= goal_defend[1]+distGoal * relBallX / RrelBall;
    homePosition[2]= goal_defend[2]+distGoal * relBallY / RrelBall
			+ util.sign(goal_defend[1]) * sideGoal;
    homePosition[3] = math.atan2(relBallY, relBallX);
  elseif defending_type==2 then

    --Side defender, avoiding attacker
    if math.abs(attacker_pose[2])<0.5 then
      homePosition[1] = goal_defend[1]/2;
      homePosition[2] = util.sign(pose.y) * 1.0;
    else
      homePosition[1] = goal_defend[1]/2;
      homePosition[2] = -util.sign(attacker_pose[2]) * 1.0;
    end
    homePosition[3] = math.atan2(relBallY, relBallX);
  elseif defending_type==3 then  
    --Front supporter
    attackGoalPosition = vector.new(wcm.get_goal_attack());
    relBallX = ballGlobal[1]-goal_defend[1];
    relBallY = ballGlobal[2]-goal_defend[2];
    RrelBall = math.sqrt(relBallX^2+relBallY^2)+0.001;

    -- move near attacking goal
    homePosition = attackGoalPosition;
    homePosition[1] = homePosition[1] - util.sign(homePosition[1]) * 1.5;

    if math.abs(ballGlobal[2])< 1.0 then
      homePosition[2] = util.sign(pose.y)*1.25;
    else
      homePosition[2] = -1*util.sign(ballGlobal[2]) * 1.25;
    end

    relBallX = ballGlobal[1]-homePosition[1];
    relBallY = ballGlobal[2]-homePosition[2];

    -- face ball 
    homePosition[3] = math.atan2(relBallY, relBallX);
  end

  return homePosition;
end



--Aditya's defender homepose
function getDefenderHomePose2()
  posCalc();

  -- Updated to account for defending goal post
  --goal_post_width_half=1.6/2;

  goalDefend=wcm.get_goal_defend();
  homePosition={};
  homePosition[1] = 0.5*goalDefend[1]+0.5*ballGlobal[1];

  -- New Positioning based on angle of ball to goal

  angle_shift=0.02;

 if ballGlobal[1]>0 then
    angle_ball_goaldefend_center = 
     math.atan((ballGlobal[2]-goalDefend[2])
		/(goalDefend[1]-ballGlobal[1]));
  else
    angle_ball_goaldefend_center = 
    math.atan((ballGlobal[2]-goalDefend[2])
	      /(goalDefend[1]+math.abs(ballGlobal[1])))
  end
 
  -- Change y co-ordinate according to theta, shift it by a factor of angle_shift and divide the angle by the present theta in degrees
  -- The division is for scaling down when the bot is in the defending half.
  homePosition[2]=homePosition[1] * 
	math.tan((1+angle_shift)*angle_ball_goaldefend_center)
	/ math.deg(angle_ball_goaldefend_center);

  -- face ball 
  relBallX = ballGlobal[1]-homePosition[1];
  relBallY = ballGlobal[2]-homePosition[2];
  homePosition[3] = util.mod_angle(math.atan2(relBallY, relBallX));

  return homePosition;
end



--Front supporter
function getSupporterHomePose()
  posCalc();
  goal_defend=wcm.get_goal_defend();


  attackGoalPosition = vector.new(wcm.get_goal_attack());
  relBallX = ballGlobal[1]-goal_defend[1];
  relBallY = ballGlobal[2]-goal_defend[2];
  RrelBall = math.sqrt(relBallX^2+relBallY^2)+0.001;

  -- move near attacking goal
  homePosition = attackGoalPosition;
  homePosition[1] = homePosition[1] - util.sign(homePosition[1]) * 1.5;

  if math.abs(ballGlobal[2])< 1.0 then
    homePosition[2] = util.sign(pose.y)*1.25;
  else
    homePosition[2] = -1*util.sign(ballGlobal[2]) * 1.25;
  end

  relBallX = ballGlobal[1]-homePosition[1];
  relBallY = ballGlobal[2]-homePosition[2];

  -- face ball 
  homePosition[3] = math.atan2(relBallY, relBallX);
  return homePosition;
end

function getGoalieHomePose()
  --Changing goalie position for moving goalie
  posCalc();

  homePosition = 0.98*vector.new(wcm.get_goal_defend());

--[[
  vBallHome = math.exp(-math.max(tBall-3.0, 0)/4.0)*
        (ballGlobal - homePosition);
  rBallHome = math.sqrt(vBallHome[1]^2 + vBallHome[2]^2);

  maxPosition = 0.55;

  if (rBallHome > maxPosition) then
    scale = maxPosition/rBallHome;
    vBallHome = scale*vBallHome;
  end
  homePosition = homePosition + vBallHome;
--]]

  goal_defend=wcm.get_goal_defend();
  relBallX = ballGlobal[1]-goal_defend[1];
  relBallY = ballGlobal[2]-goal_defend[2];
  RrelBall = math.sqrt(relBallX^2 + relBallY^2)+0.001;

  if tBall>8 or RrelBall > 4.0 then  
    --Go back and face center
    dist = 0.40;
    relBallX = -goal_defend[1];
    relBallY = -goal_defend[2];
    homePosition[3] = util.mod_angle(math.atan2(relBallY, relBallX));
  else --Move out 
    dist = 0.60; 
    homePosition[3] = util.mod_angle(math.atan2(relBallY, relBallX));
  end

  homePosition[1] = homePosition[1] + dist*relBallX /RrelBall;
  homePosition[2] = homePosition[2] + dist*relBallY /RrelBall;

--Don't let goalie go back until it comes to blocking position first
  uPose=vector.new({pose.x,pose.y,pose.a})
  homeRelative = util.pose_relative(homePosition, uPose);  
  if math.abs(homeRelative[3])>20*math.pi/180 then

    posGoalX = pose.x-goal_defend[1];
    posGoalY = pose.y-goal_defend[2];
    posGoalR = math.sqrt(posGoalX^2+posGoalY^2)*0.8;

    --Recalculate home position
    homePosition = 0.98*vector.new(wcm.get_goal_defend());
    homePosition[1] = homePosition[1] + posGoalR*relBallX /RrelBall;
    homePosition[2] = homePosition[2] + posGoalR*relBallY /RrelBall;
    homePosition[3] = util.mod_angle(math.atan2(relBallY, relBallX));

  end

  return homePosition;
end

function getGoalieHomePose2()
  posCalc();

  --Fixed goalie position for diving goalie
  homePosition = 0.94*vector.new(wcm.get_goal_defend());

  --face center of the field
  goal_defend=wcm.get_goal_defend();
  relBallX = -goal_defend[1];
  relBallY = -goal_defend[2];
  homePosition[3] = util.mod_angle(math.atan2(relBallY, relBallX));

  return homePosition;
end

---------------------------------------------------------
-- Velocity Generation
--------------------------------------------------------








function setAttackerVelocity(homePose)
  uPose=vector.new({pose.x,pose.y,pose.a})
  homeRelative = util.pose_relative(homePose, uPose);  
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);
  aHomeRelative = math.atan2(homeRelative[2],homeRelative[1]);
  homeRot=math.abs(aHomeRelative);

  --Distance-specific velocity generation
  veltype=0;

  if rHomeRelative>rVel3 and homeRot<aVel3 then
    --Fast front dash
    maxStep = maxStep3;
    maxA = maxA3;
    maxY = maxY3;
    if max_speed==0 then
      max_speed=1;
      print("MAXIMUM SPEED")
--      Speak.play('./mp3/max_speed.mp3',50)
    end
    veltype=1;
  elseif rHomeRelative>rVel2 and homeRot<aVel2 then
    --Medium speed 
    maxStep = maxStep2;
    maxA = maxA2;
    maxY = maxY2;
    veltype=2;
 
  else --Normal speed
    maxStep = maxStep1;
    maxA = 999;
    maxY = 999;
    veltype=3;
  end

  --Slow down if battery is low
  batt_level=Body.get_battery_level();
  if batt_level*10<Config.bat_med then
    maxStep = maxStep1;
  end

  vx,vy,va=0,0,0;
  aTurn=math.exp(-0.5*(rHomeRelative/rTurn)^2);
  --Don't turn to ball if close
  if rHomeRelative < 0.3 then 
    aTurn = math.max(0.5,aTurn);
  end

  vx = maxStep*homeRelative[1]/rHomeRelative;

  --Sidestep more if ball is close and sideby
  if rHomeRelative<rVel2 and  
           math.abs(aHomeRelative)>45*180/math.pi then
     vy = maxStep*homeRelative[2]/rHomeRelative;
     aTurn = 1; --Turn toward the goal
  else
     vy = 0.3*maxStep*homeRelative[2]/rHomeRelative;
  end
  vy = math.max(-maxY,math.min(maxY,vy));
  scale = math.min(maxStep/math.sqrt(vx^2+vy^2), 1);
  vx,vy = scale*vx,scale*vy;

  if math.abs(aHomeRelative)<70*180/math.pi then
    --Don't allow the robot to backstep if ball is in front
--    vx=math.max(0,vx) 
  end

  va = 0.5*(aTurn*homeRelative[3] --Turn toward the goal
     + (1-aTurn)*aHomeRelative); --Turn toward the target
  va = math.max(-maxA,math.min(maxA,va)); --Limit rotation

  --NaN Check
  if (not (vx<0) and not (vx>=0)) or
    (not (vy<0) and not (vy>=0)) or
    (not (va<0) and not (va>=0)) then
    vx,vy,va=0,0,0;
    print("ATTACKER: VELOCITY NAN!")

  end

  return vx,vy,va;
end



function setGoalieVelocity0()
  maxStep = 0.06;
  homeRelative = util.pose_relative(homePosition, {pose.x, pose.y, pose.a});
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);
  aHomeRelative = math.atan2(homeRelative[2], homeRelative[1]);

--Basic velocity generation
  vx = maxStep*homeRelative[1]/rHomeRelative;
  vy = maxStep*homeRelative[2]/rHomeRelative;
  rTurn = 0.3;
  aTurn=math.exp(-0.5*(rHomeRelative/rTurn)^2);
  vaTurn = .2 * aHomeRelative;
  vaGoal = .35*homeRelative[3];
  va = aTurn * vaGoal + (1-aTurn)*vaTurn;

  --NaN Check
  if (not (vx<0) and not (vx>=0)) or
    (not (vy<0) and not (vy>=0)) or
    (not (va<0) and not (va>=0)) then
    vx,vy,va=0,0,0;
  --  print("VELOCITY NAN!")

  end

  return vx,vy,va;
end



function setDefenderVelocity(homePose)
  homeRelative = util.pose_relative(homePose, {pose.x, pose.y, pose.a});
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);
  aHomeRelative = math.atan2(homeRelative[2],homeRelative[1]);
  homeRot=math.abs(aHomeRelative);

  if rHomeRelative>rVel3 and homeRot<aVel3 then
    --Fast front dash
    maxStep = maxStep3;
    maxA = maxA3;
    maxY = maxY3;
    if max_speed==0 then
      max_speed=1;
      print("MAXIMUM SPEED")
--      Speak.play('./mp3/max_speed.mp3',50)
    end
    veltype=1;
  elseif rHomeRelative>rVel2 and homeRot<aVel2 then
    --Medium speed 
    maxStep = maxStep2;
    maxA = maxA2;
    maxY = maxY2;
    veltype=2;
  elseif rHomeRelative>0.40 then --Normal speed
    maxStep = maxStep1;
    maxA = 999;
    maxY = 999;
    veltype=3;
  elseif rHomeRelative>0.20 then --Reached target area, don't move too much
    maxStep = 0.02;
    maxA = 999;
    maxY = 999;
  else
    maxStep = 0.001; --Just turn
    maxA = 999;
    maxY = 999;
  end

  --Don't turn back if final angle is reached
  --just walk back without turning
  if math.abs(homeRelative[3])<20*math.pi/180 then
    maxA = 0;
  end


  --Slow down if battery is low
  batt_level=Body.get_battery_level();
  if batt_level*10<Config.bat_med then
    maxStep = maxStep1;
  end

  vx,vy,va=0,0,0;
  aTurn=math.exp(-0.5*(rHomeRelative/rTurn)^2);
  if rHomeRelative<0.40 then 
    aTurn = 1; 
  end

  vx = maxStep*homeRelative[1]/(rHomeRelative+0.001);--to get rid of NaN


  if rHomeRelative<rVel2 and  
           math.abs(aHomeRelative)>45*180/math.pi then
     vy = maxStep*homeRelative[2]/rHomeRelative;
     aTurn = 1; --Turn toward the goal
  else
     vy = 0.3*maxStep*homeRelative[2]/rHomeRelative;
  end

  vy = math.max(-maxY,math.min(maxY,vy));
  scale = math.min(maxStep/math.sqrt(vx^2+vy^2), 1);
  vx,vy = scale*vx,scale*vy;

  va = 0.5*(aTurn*homeRelative[3] --Turn toward the target direction
     + (1-aTurn)*aHomeRelative); --Turn toward the target
  va = math.max(-maxA,math.min(maxA,va)); --Limit rotation

  --NaN Check
  if (not (vx<0) and not (vx>=0)) or
    (not (vy<0) and not (vy>=0)) or
    (not (va<0) and not (va>=0)) then

    print("DEFENDER: VELOCITY NAN!")

    print("maxStep:",maxStep)

    print("v:",vx,vy,va)    
    print("HomePose:",unpack(homePose));
    print("HomeRelative:",unpack(homeRelative));
    print("aHomeRelative:",aHomeRelative*180/math.pi);
    vx,vy,va=0,0,0;
  end

  return vx,vy,va;
end

