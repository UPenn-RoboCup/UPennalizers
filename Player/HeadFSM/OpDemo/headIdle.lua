module(..., package.seeall);

require('Body')

t0 = 0;
timeout = 1.0;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();

  -- set head to default position
  local yaw = 0;
  local pitch = -15*math.pi/180;
  Body.set_head_command({yaw, pitch});
end

function update()
  local t = Body.get_time();

  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end
