module(..., package.seeall);

require('Body')
require('walk')
require('vector')

require('wcm')
require('gcm')

t0 = 0;
timeout = 2.0;

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

  role = gcm.get_team_role();

  --us = UltraSound.checkObstacle();
  us = UltraSound.check_obstacle();
  if ((t - t0 > 1.0) and (us[1] < 4 and us[2] < 4)) then
    print('Exiting Obstacle: clear');
    if (role~=1) then
      return 'continue';
    else
      return 'clear';
    end
  end

  if (t - t0 > timeout) then
    print('Exiting Obstacle: timeout');
    if (role~=1) then
      return 'continue';
    else
      return "timeout";
    end
  end
end

function exit()
  walk.start();
end

