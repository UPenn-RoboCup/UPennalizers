------------------------------
-- Follow the ball after kicking
------------------------------

module(..., package.seeall);

require('Body')
require('wcm')
require('mcm')

t0 = 0;

-- follow period
tFollow = Config.fsm.headKickFollow.tFollow;
pitch0=Config.fsm.headKickFollow.pitch[1];
pitch1=Config.fsm.headKickFollow.pitch[2];
pitchSide=Config.fsm.headKickFollow.pitchSide;
yawMagSide=Config.fsm.headKickFollow.yawMagSide;

function entry()
  print("Head SM:".._NAME.." entry");

  t0 = Body.get_time();
  kick_dir=wcm.get_kick_dir();

end

function update()
  pitchBias =  mcm.get_headPitchBias();--robot specific head bias

  local t = Body.get_time();
  local ph = (t-t0)/tFollow;

  if kick_dir == 1 then --front kick
      pitch = (1-ph)*pitch0 + ph*pitch1;
      yaw=0;
  elseif kick_dir==2 then --sidekick to the left
      pitch = (1-ph)*pitch0 + ph*pitch1;
      yaw = ph*yawMagSide;
  else --sidekick to the right
      pitch = (1-ph)*pitch0 + ph*pitch1;
      yaw = ph*-yawMagSide;
  end
  Body.set_head_command({yaw, pitch-pitchBias});

  local ball = wcm.get_ball();
  if (t - ball.t < 0.1) then
    print("BallFound")
    return "ball";
  end
  if (t - t0 > tFollow) then
    return "lost";
  end
end

function exit()
end
