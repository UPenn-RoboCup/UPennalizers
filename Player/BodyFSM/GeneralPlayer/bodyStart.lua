module(..., package.seeall);

require('Body')
require('walk')
require('gcm')
require('wcm')
require('Speak')

t0=0;
tLastCount=0;

tKickOff=10.0; --5 sec max wait before moving
--If ball moves more than this amount, start moving
ballTh = 0.50; 
--If the ball comes any closer than this, start moving
ballClose = 0.50; 

if Config.fsm.playMode ==1 then
  --Turn off kickoff waiting for demo
  wait_kickoff = 0; 
else
  wait_kickoff = Config.fsm.wait_kickoff or 0;
end

function entry()
  print(_NAME..' entry');
  kickoff=0;

  --Kickoff handling (only for attacker)
  --TODO: This flag is set when player returns from penalization too

  if gcm.get_team_role()<4 and wait_kickoff>0 then 
    if gcm.get_game_kickoff()==1 then
      --Our kickoff, go ahead and kick the ball
      --Kickoff kick should be different 
      wcm.set_kick_kickOff(1);
      wcm.set_kick_tKickOff(Body.get_time());
    else
      --Their kickoff, wait for ball moving
      Speak.talk("Waiting for opponent's kickoff");
      kickoff=1;
      t0=Body.get_time();
      tLastCount=t0;
      ball0 = wcm.get_ball();
--      print("Initial ball pos: ",ballR)
      walk.stop();
    end
  else
      kickoff=0; --Defenders may move
  end
end

function update()

  role = gcm.get_team_role();
  if role==0 then 
    return 'goalie'
  end

  t=Body.get_time();
  if kickoff>0 then
    walk.stop();
    ball = wcm.get_ball();
    ballDiff={ball.x-ball0.x,ball.y-ball0.y};
    if math.sqrt(ballDiff[1]^2+ballDiff[2]^2)>ballTh or
       math.sqrt(ball.x^2+ball.y^2)<ballClose then
       return 'done';
    else

      role = gcm.get_team_role();
      if role==1 then 
	 tKickOff=10.0; 
      else
	 tKickOff=7.0; 
      end

      tRemaining = tKickOff-(t-t0);
      if tRemaining<0 then 
        return 'done';
      elseif t>tLastCount then
	tLastCount=tLastCount+1;
	countdown=string.format("%d",tRemaining)
        print("Count: ",countdown)
--        Speak.talk(countdown);
      end
    end
  else
    return 'done';
  end
end


function exit()
  walk.start();
end
