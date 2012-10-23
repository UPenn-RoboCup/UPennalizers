------------------------------
-- Fix the head angle during approaching
------------------------------

module(..., package.seeall);

require('Body')
require('wcm')
require('mcm')

t0 = 0;


--TODO: implement headkick for nao head SMs

-- follow period
--[[
timeout = Config.fsm.headKick.timeout;
tLost = Config.fsm.headKick.tLost;
pitch0 = Config.fsm.headKick.pitch0;
xMax = Config.fsm.headKick.xMax;
yMax = Config.fsm.headKick.yMax;
--]]

tLost = 3.0;
timeout = 10.0;

function entry()
  print("Head SM:".._NAME.." entry");
  t0 = Body.get_time();
  kick_dir=wcm.get_kick_dir();
end

function update()
  local t = Body.get_time();
  local ball = wcm.get_ball();

--[[
  pitchBias=vcm.get_camera_pitchBias(); --Robot specific head angle bias

  if ball.x<xMax and math.abs(ball.y)<yMax then
     Body.set_head_command({0, pitch0-pitchBias});
  else
   local yaw, pitch = HeadTransform.ikineCam(ball.x, ball.y, 0.03);
   local currentYaw = Body.get_head_position()[1];
   local currentPitch = Body.get_head_position()[2];
   local p = 0.3;
   yaw = currentYaw + p*(yaw - currentYaw);
   pitch = currentPitch + p*(pitch - currentPitch);
   Body.set_head_command({yaw, pitch});
  end
--]]

  Body.set_head_command({0,25*math.pi/180});

  if (t - ball.t > tLost) then
    return "ballLost";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end
