module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
require('wcm')
require('gcm')
require('UltraSound')
require('position')

t0 = 0;

--[[
maxStep = Config.fsm.bodyChase.maxStep;
tLost = Config.fsm.bodyChase.tLost;
timeout = Config.fsm.bodyChase.timeout;
rClose = Config.fsm.bodyChase.rClose;
--]]

timeout = 20.0;
maxStep = 0.06;
maxPosition = 0.55;
tLost = 6.0;

rClose = Config.fsm.bodyAnticipate.rClose;
rCloseX = Config.fsm.bodyAnticipate.rCloseX;
thClose = Config.fsm.bodyGoaliePosition.thClose;
goalie_type = Config.fsm.goalie_type;

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  if goalie_type>2 then
    HeadFSM.sm:set_state('headSweep');
  else
--    HeadFSM.sm:set_state('headTrack');
  end
end

function update()
  role = gcm.get_team_role();
  if role~=0 then
    return "player";
  end

  local t = Body.get_time();

  ball = wcm.get_ball();
  pose = wcm.get_pose();
  ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a});
  tBall = Body.get_time() - ball.t;

  if goalie_type<3 then 
    --moving goalie
    homePose=position.getGoalieHomePose();

  else
    --diving goalie
--    homePose=position.getGoalieHomePose2();
    homePose=position.getGoalieHomePose();

  end

  vx,vy,va=position.setGoalieVelocity0(homePose);

--    vx,vy,va=position.setDefenderVelocity(homePose);


  walk.set_velocity(vx, vy, va);

  goal_defend=wcm.get_goal_defend();
  ballxy=vector.new( {ball.x,ball.y,0} );
  posexya=vector.new( {pose.x, pose.y, pose.a} );
  ballGlobal=util.pose_global(ballxy,posexya);
  ballR_defend = math.sqrt(
	(ballGlobal[1]-goal_defend[1])^2+
	(ballGlobal[2]-goal_defend[2])^2);
  ballX_defend = math.abs(ballGlobal[1]-goal_defend[1]);

  rCloseX2 = 0.8;
  eta_kickaway = 3.0;
  attacker_eta = wcm.get_team_attacker_eta();

  if tBall<1.0 then
    if ballX_defend < rCloseX2 or
--       ((ballR_defend<rClose or ballX_defend<rCloseX) 
       (ballR_defend<rClose  
         and attacker_eta > eta_kickaway) then
      return "ballClose";
    end
  end

  uPose=vector.new({pose.x,pose.y,pose.a})
  homeRelative = util.pose_relative(homePose, uPose);  
  --Should we stop?
  if goalie_type>1 and  
     math.abs(homeRelative[1])<thClose[1] and
     math.abs(homeRelative[2])<thClose[2] and
     math.abs(homeRelative[3])<thClose[3] then
    return "ready";
  end

end

function exit()
  if goalie_type>2 then
    HeadFSM.sm:set_state('headTrack');
  end
end

