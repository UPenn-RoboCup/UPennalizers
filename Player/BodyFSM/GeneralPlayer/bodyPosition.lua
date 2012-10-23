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
require('position')

t0 = 0;


tLost = Config.fsm.bodyPosition.tLost;
timeout = Config.fsm.bodyPosition.timeout;
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
end


function update()
  count=count+1;

  local t = Body.get_time();
  ball=wcm.get_ball();
  pose=wcm.get_pose();
  ballR = math.sqrt(ball.x^2 + ball.y^2);

  --recalculate approach path when ball is far away
  if ballR>0.60 then
    behavior.update();
  end

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

  role = gcm.get_team_role();
  kickDir = wcm.get_kick_dir();

  --Force attacker for demo code
  if Config.fsm.playMode==1 then role=1; end
  if role==0 then return "goalie";  end

  if (role == 2) then
    homePose = position.getDefenderHomePose();
  elseif (role==3) then
    homePose = position.getSupporterHomePose();
  else
    if Config.fsm.playMode~=3 or kickDir~=1 then --We don't care to turn when we do sidekick

      homePose = position.getAttackerHomePose();

--      homePose = position.getDirectAttackerHomePose();
    else
      homePose = position.getAttackerHomePose();
    end	
  end

  --Field player cannot enter our penalty box

--SJ:  We replace this with potential field around goalie

--[[
  if role~=0 then
    goalDefend = wcm.get_goal_defend();
    homePose[1]=util.sign(goalDefend[1])*
	math.min(2.2,homePose[1]*util.sign(goalDefend[1]));
  end
--]]







  if role==1 then
    vx,vy,va=position.setAttackerVelocity(homePose);
  else
    vx,vy,va=position.setDefenderVelocity(homePose);
  end

  --Get pushed away if other robots are around
  obstacle_num = wcm.get_obstacle_num();
  obstacle_x = wcm.get_obstacle_x();
  obstacle_y = wcm.get_obstacle_y();
  obstacle_dist = wcm.get_obstacle_dist();
  obstacle_role = wcm.get_obstacle_role();

  avoid_own_team = Config.team.avoid_own_team or 0;

  if avoid_own_team then
   for i=1,obstacle_num do

    --Role specific rejection radius
    if role==0 then --Goalie has the highest priority 
      r_reject = 0.4;



    elseif role==1 then --Attacker
      if obstacle_role[i]==0 then --Our goalie
--        r_reject = 1.0;
        r_reject = 0.5;


      elseif obstacle_role[i]<4 then --Our team
        r_reject = 0.001;
      else
        r_reject = 0.001;
      end
    else --Defender and supporter
      if obstacle_role[i]<4 then --Our team
        if obstacle_role[i]==0 then --Our goalie
--          r_reject = 1.0;
          r_reject = 0.7;
        else
          r_reject = 0.6;
        end
      else --Opponent team
        r_reject = 0.6;
      end
    end

    if obstacle_dist[i]<r_reject then
      local v_reject = 0.2*math.exp(-(obstacle_dist[i]/r_reject)^2);
      vx = vx - obstacle_x[i]/obstacle_dist[i]*v_reject;
      vy = vy - obstacle_y[i]/obstacle_dist[i]*v_reject;
    end
   end
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

--  if walk.ph>0.95 then
--    print(string.format("position error: %.3f %.3f %d\n",
--	homeRelative[1],homeRelative[2],homeRelative[3]*180/math.pi))
--    print("ballR:",ballR);
--    print(string.format("Velocity:%.2f %.2f %.2f",vx,vy,va));
--    print("VEL: ",veltype)
--  end

  attackAngle = wcm.get_goal_attack_angle2();
  daPost = wcm.get_goal_daPost2();
  daPostMargin = 15 * math.pi/180;
  daPost1 = math.max(thClose[3],daPost/2 - daPostMargin);

  uPose=vector.new({pose.x,pose.y,pose.a})
  homeRelative = util.pose_relative(homePose, uPose);  
  angleToTurn = math.max(0, homeRelative[3] - daPost1);

  if math.abs(homeRelative[1])<thClose[1] and
    math.abs(homeRelative[2])<thClose[2] and
    math.abs(homeRelative[3])<daPost1 and
    ballR<rClose and
    t-ball.t<tBall then
      print("bodyPosition done")
      return "done";
  end
end

function exit()
end

