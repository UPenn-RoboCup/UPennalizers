module(..., package.seeall);

require('Body')
require('World')
require('walk')
require('vector')
require('vcm')
require('Config')
Team = require('Team_SyncStep')
-- 2 is master
t0 = 0;
timeout =Config.BodyFSM.orbit.timeout;
maxStep =Config.BodyFSM.orbit.maxStep;
rOrbit = Config.BodyFSM.orbit.rOrbit;
rFar = Config.BodyFSM.orbit.rFar;
thAlign = Config.BodyFSM.orbit.thAlign;
tLost = Config.BodyFSM.orbit.tLost;
playerID = Config.game.playerID;

direction = 1;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();

  -- Keep the hands from moving around to balance
  walk.has_ball=1;

end

function update()

  local t = Body.get_time();

  -- Master does his own thing...
  if( playerID==2 ) then
    return;
  end

  ball = vcm.get_ball();
  ball = vcm.ball;

  va, vx, vy = 0,0,0;

  if( math.abs(ball.eyes_cent[1]-160)>7 ) then -- center the other two eyes in our image
--    print("Not centered! "..ball.eyes_cent[1]-160);
    -- Set vy
--    vy = (ball.eyes_cent[1]-160) / 2000;
  end

  eye_width = math.sqrt( ball.eyes_dist[1]^2 + ball.eyes_dist[2]^2 );
  if( math.abs(eye_width-Config.stretcher.eye_width) > 10 ) then -- move back and forth to align ourselves
    print("We are too far/close: ".. eye_width);
    --print("Max speed: "..maxStep)
    -- set vx
    vx = -1/1000*(eye_width - 40);
    print("Setting Forward Speed to "..vx);
  end
--  if( vx>0 ) then
      walk.set_velocity(Team.myvel[1] + vx, vy, va);
--  end;

  if (t - t0 > timeout) then
    return "timeout";
  end

end

function exit()
end

