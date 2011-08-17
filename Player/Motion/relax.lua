module(..., package.seeall);

require('Body')

t0 = 0;
timeout = 1.0;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
  Body.set_body_hardness(0);
  Body.set_syncread_enable(1);
end

function update()
  local t = Body.get_time();

  local qSensor = Body.get_sensor_position();
  Body.set_actuator_command(qSensor);

  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end
