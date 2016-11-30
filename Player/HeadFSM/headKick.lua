------------------------------
-- Fix the head angle during approaching
------------------------------

module(..., package.seeall);

require('Body')
require('wcm')
require('mcm')
require('HeadTransform');

t0 = 0;

-- follow period
timeout = Config.fsm.headKick.timeout;
tLost = Config.fsm.headKick.tLost;
pitch0 = Config.fsm.headKick.pitch0;
xMax = Config.fsm.headKick.xMax;
yMax = Config.fsm.headKick.yMax;

function entry()
  print("Head SM:".._NAME.." entry");
  t0 = Body.get_time();
  kick_dir=wcm.get_kick_dir();
  vcm.set_camera_command(1); --bottom camera
end

function update()
  pitchBias =  mcm.get_headPitchBias();--robot specific head bias

  local t = Body.get_time();
  local ball = wcm.get_ball();

--[[
  if ball.x<xMax and math.abs(ball.y)<yMax then
     Body.set_head_command({0, pitch0-pitchBias});
  else
    local yaw, pitch;

    if Config.platform.name== 'WebotsNao' or
       Config.platform.name== 'NaoV4' then
      --Bottom camera check
      yaw, pitchBottom =
        HeadTransform.ikineCam(ball.x, ball.y, trackZ, 1);
      --Do we need to look down?
      if pitchBottom > 10*math.pi/180 then
        pitch = pitchBottom - 10*math.pi/180;
      else
        pitch = 0;
      end
    else --OP case, just track the bal
      yaw, pitch = HeadTransform.ikineCam(ball.x, ball.y, 0.03);
    end

    local p = 0.3; --Filter head movement here...

    local currentYaw = Body.get_head_position()[1];
    local currentPitch = Body.get_head_position()[2];
    yaw = currentYaw + p*(yaw - currentYaw);
    pitch = currentPitch + p*(pitch - currentPitch);
    Body.set_head_command({yaw, pitch});
  end
--]]

--SJ: I lessened pitch fixture 
  local yaw, pitch;

  if Config.platform.name== 'WebotsNao' or
     Config.platform.name== 'NaoV4' then
    --Bottom camera check
    yaw, pitchBottom =
      HeadTransform.ikineCam(ball.x, ball.y, trackZ, 1);
    --Do we need to look down?
    if pitchBottom > 10*math.pi/180 then
      pitch = pitchBottom - 10*math.pi/180;
    else
      pitch = 0;
    end
  else --OP case, just track the bal
    yaw, pitch = HeadTransform.ikineCam(ball.x, ball.y, 0.03);
  end
  
  if ball.x < xMax and math.abs(ball.y) < yMax then
    yaw = 0;
  end



  local p = 0.3; --Filter head movement here...

  local currentYaw = Body.get_head_position()[1];
  local currentPitch = Body.get_head_position()[2];
  yaw = currentYaw + p*(yaw - currentYaw);
  pitch = currentPitch + p*(pitch - currentPitch);
  Body.set_head_command({yaw, pitch});


  if (t - ball.t > tLost) then
    return "ballLost";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
  vcm.set_camera_command(-1); --switch camera
end
