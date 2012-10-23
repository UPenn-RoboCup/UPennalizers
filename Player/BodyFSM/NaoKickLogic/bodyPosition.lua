module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
require('wcm')
require('gcm')
require('UltraSound')
require('postDist')

t0 = 0;
timeout = 20.0;

maxStep = 0.05;

rClose = 0.28;

tLost = 3.0;

rTurn= Config.fsm.bodyPosition.rTurn;
rTurn2= Config.fsm.bodyPosition.rTurn2;
rDist1= Config.fsm.bodyPosition.rDist1;
rDist2= Config.fsm.bodyPosition.rDist2;
rOrbit= Config.fsm.bodyPosition.rOrbit;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  ball = wcm.get_ball();
  pose = wcm.get_pose();
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a});
  tBall = Body.get_time() - ball.t;

  role = gcm.get_team_role();
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

  if (role == 2) then
    -- defend
    goalDefend = wcm.get_goal_defend();
    homePosition = goalDefend - 0.5*(goalDefend - ballGlobal);
  
    --homePosition = .6 * ballGlobal;
    --homePosition[1] = homePosition[1] - 0.50*util.sign(homePosition[1]);
    homePosition[2] = homePosition[2] - 0.80*util.sign(homePosition[2]);

  elseif (role == 3) then
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
  else
    -- attack
    if math.abs(angle1)<math.pi/2 then
      rDist=math.min(rDist1,math.max(rDist2,ballR-rTurn2));
      homePosition={
        ballGlobal[1]-math.cos(aGoal)*rDist,
        ballGlobal[2]-math.sin(aGoal)*rDist,
        aGoal};
    elseif angle1>0 then
      homePosition={
        ballGlobal[1]+math.cos(-aBall+math.pi/2)*rOrbit,
        ballGlobal[2]-math.sin(-aBall+math.pi/2)*rOrbit,
        aBall};

    else
      homePosition={
        ballGlobal[1]+math.cos(-aBall-math.pi/2)*rOrbit,
        ballGlobal[2]-math.sin(-aBall-math.pi/2)*rOrbit,
        aBall};
    end  
  end

  -- do not go into own penalty box
  if (gcm.get_team_color() == 1) then
    -- red
    homePosition[1] = math.min(homePosition[1], 2.2);
  else
    -- blue
    homePosition[1] = math.max(homePosition[1], -2.2);
  end

  homeRelative = util.pose_relative(homePosition, {pose.x, pose.y, pose.a});
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

  vx = maxStep*homeRelative[1]/(rHomeRelative + 0.1);
  vy = maxStep*homeRelative[2]/(rHomeRelative + 0.1);
  va = .5*math.atan2(ball.y, math.max(ball.x + 0.05,0.05));

  walk.set_velocity(vx, vy, va);
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  if ((tBall < 1.0) and (ballR < rClose)) then
    if postDist.kick() then
      return "approach"; --Does not having approach in position make faster?
    else
      return "approach";
    end
  end

  -- TODO: add obstacle detection
  --us = UltraSound.checkObstacle();
  if Config.fsm.enable_obstacle_detection > 0 then
    us = UltraSound.check_obstacle();
  else
    us = vector.zeros(2)
  end
  if ((t - t0 > 2.5) and (us[1] > 5 or us[2] > 5) and role~=1) then
    return 'obstacle'; 
  end

  if ((t - t0 > 5.0) and (t - ball.t > tLost)) then
    return "ballLost";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end

