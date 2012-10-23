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
locked_on = false;


th_lock = 5*math.pi/180;
th_unlock = 15*math.pi/180;


goalie_dive = Config.goalie_dive or 0;
goalie_type = Config.fsm.goalie_type;


function entry()
  print("Head SM:".._NAME.." entry");
  t0 = Body.get_time();
  locked_on=false;
  wcm.set_ball_locked_on(0);
end

function update()

  if goalie_type<3 then --Non-diving goalie, escape to headTrack
    return "player"
  end

  local t = Body.get_time();

  -- update head position based on ball location
  ball = wcm.get_ball();
  ballR = math.sqrt (ball.x^2 + ball.y^2);

  local yawTarget, pitchTarget =
	HeadTransform.ikineCam(ball.x,ball.y, trackZ, bottom);
  local headAngles = Body.get_head_position();

  pitchOffset = 10*math.pi/180;
  pitchTarget = pitchTarget + pitchOffset;


  yaw_error = yawTarget - headAngles[1];
  pitch_error = pitchTarget - headAngles[2];
  angle_error = math.sqrt(yaw_error^2+pitch_error^2);

  if not locked_on then
    Body.set_head_command({yawTarget, pitchTarget});
  end

  if locked_on then
    if angle_error>th_unlock then
      locked_on=false;
      wcm.set_ball_locked_on(0);
    end
  else
    if angle_error<th_lock then
      locked_on=true;
--    Speak.talk("Target Locked On");
      wcm.set_ball_locked_on(1);
    end
  end


  if (t - ball.t > tLost) then
    print('Ball lost!');
    return "lost";
  end

end

function exit()
  wcm.set_ball_locked_on(0);
end
