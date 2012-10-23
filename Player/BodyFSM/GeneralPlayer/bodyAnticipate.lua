module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('kick');
require('HeadFSM')
require('Config')
require('wcm')

require('walk');
require('dive')

t0 = 0;
tStart = 0;

started = false;
kickable = true;
follow = false;

goalie_dive = Config.goalie_dive or 0;
goalie_type = Config.fsm.goalie_type;



tStartDelay = Config.fsm.bodyAnticipate.tStartDelay;
rCloseDive = Config.fsm.bodyAnticipate.rCloseDive;
rMinDive = Config.fsm.bodyAnticipate.rMinDive;
ball_velocity_thx = Config.fsm.bodyAnticipate.ball_velocity_thx;
ball_velocity_th = Config.fsm.bodyAnticipate.ball_velocity_th;
center_dive_threshold_y = Config.fsm.bodyAnticipate.center_dive_threshold_y;
dive_threshold_y = Config.fsm.bodyAnticipate.dive_threshold_y;

ball_velocity_th2 = Config.fsm.bodyAnticipate.ball_velocity_th2;
rClose = Config.fsm.bodyAnticipate.rClose;
rCloseX = Config.fsm.bodyAnticipate.rCloseX;

timeout = Config.fsm.bodyAnticipate.timeout;
thFar = Config.fsm.bodyAnticipate.thFar or {0.4,0.4,15*math.pi/180};




function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  started = false;
  follow = false;
  walk.stop();
  if goalie_type>2 then
    Motion.event("diveready");
  end
end

function update()
  role = gcm.get_team_role();
  if role~=0 then
    return "player";
  end

  if goalie_type>1 then 
    walk.stop();
  else
    return 'position';
  end

  local t = Body.get_time();
  ball = wcm.get_ball();
 
  ball_v_inf = wcm.get_ball_v_inf();
  ball.x=ball_v_inf[1];
  ball.y=ball_v_inf[2];

  pose = wcm.get_pose();
  tBall = Body.get_time() - ball.t;
  ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a});
  ballR = math.sqrt(ball.x^2+ ball.y^2);

  -- See where our home position is...

  if goalie_type<3 then 
    --moving goalie
    homePose=position.getGoalieHomePose();
  else
    --diving goalie
    homePose=position.getGoalieHomePose2();
  end


  homeRelative = util.pose_relative(homePose, {pose.x, pose.y, pose.a});
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

  goal_defend=wcm.get_goal_defend();
  ballxy=vector.new( {ball.x,ball.y,0} );
  aBall = math.atan2 (ball.y,ball.x);
  posexya=vector.new( {pose.x, pose.y, pose.a} );
  ballGlobal=util.pose_global(ballxy,posexya);
  ballR_defend = math.sqrt(
	(ballGlobal[1]-goal_defend[1])^2+
	(ballGlobal[2]-goal_defend[2])^2);
  ballX_defend = math.abs(ballGlobal[1]-goal_defend[1]);

  --TODO: Diving handling 

  ball_v = math.sqrt(ball.vx^2+ball.vy^2);

  if goalie_dive > 0 and goalie_type>2 then
    if t-t0>tStartDelay and t-ball.t<0.1 then

      ballR=math.sqrt(ball.x^2+ball.y^2);

      if ball_v>ball_velocity_th and
	ball.vx<ball_velocity_thx then
        print(string.format("B: %.1f %.1f V %.2f %.2f", 
	ball.x,ball.y,ball.vx,ball.vy));
      end

      if ball.vx<ball_velocity_thx and 
	ballR<rCloseDive and
	ballR>rMinDive and
        ball_v>ball_velocity_th then

        t0=t;
        py = ball.y - (ball.vy/ball.vx) * ball.x;
        print("Ball velocity:",ball.vx,ball.vy);
        print("Projected y pos:",py);
        if math.abs(py)<dive_threshold_y then
          if py>center_dive_threshold_y then 
  	    Speak.talk('Left');
            dive.set_dive("diveLeft");
          elseif py<-center_dive_threshold_y then
  	    Speak.talk('Right');
            dive.set_dive("diveRight");
          else 
	    Speak.talk('Center');
            dive.set_dive("diveCenter");
          end
          Motion.event("dive");
          return "dive";
	end
      end
    end
  end

  aBall = math.atan2 (ball.y,ball.x);

  --Penalty mark: 1.2m
  --Penalty box: 0.6m
  rCloseX2 = 0.8; --absolute min X pos
  eta_kickaway = 3.0;
  attacker_eta = wcm.get_team_attacker_eta();

  kick_away = false;
--  if goalie_dive~=1 or goalie_type<3 then 
  if true then --Always reposition
    if t-ball.t<0.1 and ball_v < ball_velocity_th2 then
      --ball is not moving, check whether we go out for kicking      
      if ballX_defend<rCloseX2 or
--       ((ballX_defend<rCloseX or ballR_defend<rClose)
       (ballR_defend<rClose
	     and attacker_eta > eta_kickaway) then
        Motion.event("walk");
        return "ballClose";
      end
    end

    attackBearing = wcm.get_attack_bearing();
    if Config.fsm.goalie_reposition==1 then --check yaw error only
      if (t - t0 > timeout) and 
  	math.abs(aBall) > thFar[3] then

        Motion.event("walk");
        return 'position';
      end
    --check yaw and position error
    elseif Config.fsm.goalie_reposition==2 then 
      if (t - t0 > timeout) and 
	( rHomeRelative>math.sqrt(thFar[1]^2+thFar[2]^2) or
  	math.abs(aBall) > thFar[3]) then

        Motion.event("walk");
        return 'position';
      end
    end
  end
end


function exit()
  walk.start();
end
