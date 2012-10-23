------------------------------
-- Follow the ball after kicking
------------------------------

module(..., package.seeall);

require('Body')
require('wcm')
require('mcm')

t0 = 0;

-- follow period
tFollow = 2.0;
pitchSide=0;
yawMagSide=90*math.pi/180;

function entry()
  print("Head SM:".._NAME.." entry");

  t0 = Body.get_time();
  kick_dir=wcm.get_kick_dir();

  --Continuously switch cameras 
  vcm.set_camera_command(-1);
end

function update()
  local t = Body.get_time();
  local ph = (t-t0)/tFollow;

  if kick_dir == 1 then --front kick
      yaw=0;
  elseif kick_dir==2 then --sidekick to the left
      yaw = ph*yawMagSide;
  else --sidekick to the right
      yaw = ph*-yawMagSide;
  end
  Body.set_head_command({yaw, 0});

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
