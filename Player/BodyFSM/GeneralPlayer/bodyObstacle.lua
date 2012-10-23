module(..., package.seeall);

require('Body')
require('walk')
require('vector')

require('wcm')
require('gcm')

t0 = 0;
timeout = 3.0;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
  walk.set_velocity(0,0,0);
  walk.stop();
  Speak.talk('Obstacle');
end

function update()
  local t = Body.get_time();
  walk.stop();

  --us = UltraSound.checkObstacle();
  us = UltraSound.check_obstacle();
  if ((t - t0 > 1.0) and (us[1] < 7 and us[2] < 7)) then
    print('Exiting Obstacle: clear');
    return 'clear';
  end

  if (t - t0 > timeout) then
    print('Exiting Obstacle: timeout');
    return "timeout";
  end
end

function exit()
  walk.start();
end

