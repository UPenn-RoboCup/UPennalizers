module(..., package.seeall);

require('Body')
require('Config')
require('vcm')

t0 = 0;
timeout = 30.0;

-- ball detection timeout
tLost = 2.0;

--forikinecam
camOffsetZ = Config.head.camOffsetZ;
pitchMin = Config.head.pitchMin;
pitchMax = Config.head.pitchMax;
yawMin = Config.head.yawMin;
yawMax = Config.head.yawMax;
cameraPos = Config.head.cameraPos;
cameraAngle = Config.head.cameraAngle;

-- z-axis tracking position
trackZ = Config.vision.ball_diameter; 


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();

  -- only use bottom camera
  vcm.set_camera_command(1);
end

function update()
  local t = Body.get_time();

  -- update head position based on ball location
  ball = wcm.get_ball();

  local yaw, pitch = ikineCam(ball.x, ball.y, trackZ);

  Body.set_head_command({yaw, pitch});
  
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  local tLook = 5.0/(1.0 + ballR/0.3) + 2.0;
  local tState = t - t0;

  if (tState > tLook) then
    return 'timeout';
  end
  if (t - ball.t > tLost and tState > tLost) then
    return 'lost';
  end

end

function exit()
end

function ikineCam(x, y, z)
  --Bottom camera by default (cameras are 0 indexed so add 1)
  select = 2;
  --Look at ground by default
  z = z or 0;

  z = z-camOffsetZ;
  local norm = math.sqrt(x^2 + y^2 + z^2);
  local yaw = math.atan2(y, x);
  local pitch = math.asin(-z/(norm + 1E-10));

  pitch = pitch - cameraAngle[select][2];

  yaw = math.min(math.max(yaw, yawMin), yawMax);
  pitch = math.min(math.max(pitch, pitchMin), pitchMax);

  return yaw, pitch;
end

