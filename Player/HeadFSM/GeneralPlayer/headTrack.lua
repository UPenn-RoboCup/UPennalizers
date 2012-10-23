module(..., package.seeall);

require('Body')
require('HeadTransform')
require('Config')
require('wcm')

t0 = 0;

minDist = Config.fsm.headTrack.minDist;
fixTh = Config.fsm.headTrack.fixTh;
trackZ = Config.vision.ball_diameter; 
timeout = Config.fsm.headTrack.timeout;
tLost = Config.fsm.headTrack.tLost;

goalie_dive = Config.goalie_dive or 0;
goalie_type = Config.fsm.goalie_type;


function entry()
  print("Head SM:".._NAME.." entry");

  t0 = Body.get_time();
end

function update()

  role = gcm.get_team_role();
  --Force attacker for demo code
  if Config.fsm.playMode==1 then role=1; end
  if role==0 and goalie_type>2 then --Escape if diving goalie
    return "goalie";
  end

  local t = Body.get_time();

  -- update head position based on ball location
  ball = wcm.get_ball();
  ballR = math.sqrt (ball.x^2 + ball.y^2);

  local yaw, pitch =
	HeadTransform.ikineCam(ball.x, ball.y, trackZ, bottom);

  -- Fix head yaw while approaching (to reduce position error)
  if ball.x<fixTh[1] and math.abs(ball.y) < fixTh[2] then
     yaw=0.0; 
  end

  Body.set_head_command({yaw, pitch});

  if (t - ball.t > tLost) then
    print('Ball lost!');
    return "lost";
  end
--TODO: generalize this using eta information
  if (t - t0 > timeout) and
     ballR > minDist   then
     if role==0 then
       return "sweep"; --Goalie, sweep to localize
     else
       return "timeout";  --Player, look up to see goalpost
     end
  end
end

function exit()
end
