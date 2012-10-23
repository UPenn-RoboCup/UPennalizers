module(..., package.seeall);

require('Body')
require('World')
require('walk')
require('vector')
require('wcm')
require('Config')
require('Team')
require('util')
require('walk')
require('behavior')

t0 = 0;
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


tLost = Config.fsm.bodyPosition.tLost;
timeout = Config.fsm.bodyPosition.timeout;

rTurn= Config.fsm.bodyPosition.rTurn;
rTurn2= Config.fsm.bodyPosition.rTurn2;
rDist1= Config.fsm.bodyPosition.rDist1;
rDist2= Config.fsm.bodyPosition.rDist2;
rOrbit= Config.fsm.bodyPosition.rOrbit;

thClose = Config.fsm.bodyPosition.thClose;
rClose= Config.fsm.bodyPosition.rClose;
fast_approach=Config.fsm.fast_approach or 0;

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  max_speed=0;
  count=0;
  ball=wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  maxStep=maxStep1;

  behavior.update();

--[[
  kickType=2;
  if walk.canWalkKick ~= 1 or Config.fsm.enable_walkkick == 0 then
    kickType=1;
  end
  wcm.set_kick_dir(1);--front kick default
  wcm.set_kick_angle(0);
  wcm.set_kick_type(kickType);
--]]
end


function update()
  count=count+1;

  local t = Body.get_time();
  ball=wcm.get_ball();
  pose=wcm.get_pose();

  --Current cordinate origin: midpoint of uLeft and uRight
  --Calculate ball position from future origin
  --Assuming we stop at next step
  if fast_approach ==1 then
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
  else
  end

  ballR = math.sqrt(ball.x^2 + ball.y^2);

  ballxy=vector.new( {ball.x,ball.y,0} );
  posexya=vector.new( {pose.x, pose.y, pose.a} );

  ballGlobal=util.pose_global(ballxy,posexya);
  goalGlobal=wcm.get_goal_attack();
  aBallLocal=math.atan2(ball.y,ball.x); 

  aBall=math.atan2(ballGlobal[2]-pose.y, ballGlobal[1]-pose.x);
  aGoal=math.atan2(goalGlobal[2]-ballGlobal[2],goalGlobal[1]-ballGlobal[1]);

  --Apply angle
  kickAngle=  wcm.get_kick_angle();
  aGoal = util.mod_angle(aGoal - kickAngle);

  --In what angle should we approach the ball?
  angle1=util.mod_angle(aGoal-aBall);

  role = gcm.get_team_role();
  --Force attacker for demo code
  if Config.fsm.playMode==1 then role=1; end

   if (role == 2) then
    homePose = getDefenderHomePose();
  elseif (role==3) then
    homePose = getSupporterHomePose();
  else
    homePose=getAttackerHomePose();	
  end

  --Field player cannot enter our penalty box
  --TODO: generalize
  if role~=0 then
    goalDefend = wcm.get_goal_defend();
    homePose[1]=sign(goalDefend[1])*
	math.min(2.2,homePose[1]*sign(goalDefend[1]));
  end

  if role==1 then
    setAttackerVelocity();
  else
    setDefenderVelocity();
  end

  --Check the nearest obstacle (for non-attacker)
  obstacle_dist = wcm.get_obstacle_dist();
  obstacle_pose = wcm.get_obstacle_pose();
  if role<2 then
    r_reject = 0.3;
  else
    r_reject = 0.8;
  end
  if obstacle_dist<r_reject then
    local v_reject = 0.1*math.exp(-(obstacle_dist/r_reject)^2);
    vx = vx - obstacle_pose[1]/obstacle_dist*v_reject;
    vy = vy - obstacle_pose[2]/obstacle_dist*v_reject;
  end

  walk.set_velocity(vx,vy,va);


  if (t - ball.t > tLost) then
    return "ballLost";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end

  tBall=0.5;

  if Config.fsm.playMode~=3 then
    if ballR<rClose then
      print("bodyPosition ballClose")
      return "ballClose";
    end
  end

  if walk.ph>0.95 then
--    print(string.format("position error: %.3f %.3f %d\n",
--	homeRelative[1],homeRelative[2],homeRelative[3]*180/math.pi))

--    print(string.format("Velocity:%.2f %.2f %.2f",vx,vy,va));
--    print("VEL: ",veltype)
--    print("ballR:",ballR);

  end


  if math.abs(homeRelative[1])<thClose[1] and
    math.abs(homeRelative[2])<thClose[2] and
    math.abs(homeRelative[3])<thClose[3] and
    ballR<rClose and
    t-ball.t<tBall then
      print("bodyPosition done")
      return "done";
--      return "dribble"; --for test
  end
end

function setAttackerVelocity()
  uPose=vector.new({pose.x,pose.y,pose.a})
  homeRelative = util.pose_relative(homePose, uPose);  
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);
  aHomeRelative = math.atan2(homeRelative[2],homeRelative[1]);
  homeRot=math.abs(homeRelative[3]);

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
  
  vx,vy,va=0,0,0;
  aTurn=math.exp(-0.5*(rHomeRelative/rTurn)^2);
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
    vx=math.max(0,vx) 
  end

  va = 0.5*(aTurn*homeRelative[3] --Turn toward the goal
     + (1-aTurn)*aHomeRelative); --Turn toward the target
  va = math.max(-maxA,math.min(maxA,va)); --Limit rotation
end

function setDefenderVelocity()
  homeRelative = util.pose_relative(homePose, {pose.x, pose.y, pose.a});
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

  vx = maxStep*homeRelative[1]/rHomeRelative;
  vy = maxStep*homeRelative[2]/rHomeRelative;
  va = .5*math.atan2(ball.y, ball.x + 0.05);
end

function getAttackerHomePose()

  --Direct approach 
  if Config.fsm.playMode~=3 then
    local homepose={
	ballGlobal[1],
	ballGlobal[2],
	aBall};
    return homepose;
  end

  --Curved approach
  if math.abs(angle1)<math.pi/2 then
    rDist=math.min(rDist1,math.max(rDist2,ballR-rTurn2));
    local homepose={
	ballGlobal[1]-math.cos(aGoal)*rDist,
	ballGlobal[2]-math.sin(aGoal)*rDist,
	aGoal};
    return homepose;
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

function getDefenderHomePose()
    -- defend
  homePosition = .6 * ballGlobal;
  homePosition[1] = homePosition[1] - 0.50*util.sign(homePosition[1]);
  homePosition[2] = homePosition[2] - 0.80*util.sign(homePosition[2]);
  return homePosition;
end

function getSupporterHomePose()

    -- support
    attackGoalPosition = vector.new(wcm.get_goal_attack());

    --[[
    homePosition = ballGlobal;
    homePosition[1] = homePosition[1] + 0.75*util.sign(homePosition[1]);
    homePosition[1] = util.sign(homePosition[1])*math.min(2.0, math.abs(homePosition[1]));
    homePosition[2] = 
    --]]

    -- move near attacking goal
    homePosition = attackGoalPosition;
    -- stay in the field (.75 m from end line)
    homePosition[1] = homePosition[1] - util.sign(homePosition[1]) * 1.0;
    -- go to far post (.75 m from center)
    homePosition[2] = -1*util.sign(ballGlobal[2]) * .75;

    -- face ball 
    homePosition[3] = ballGlobal[3];
    return homePosition;
end

function exit()
end

function sign(s)
  if s>0 then return 1;
  else return -1;
  end
end

