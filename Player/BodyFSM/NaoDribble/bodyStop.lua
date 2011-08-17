module(..., package.seeall);

require('Body')
require('Motion')

function entry()
  print(_NAME..' entry');

  walk.set_velocity(0,0,0);
  walk.stop();
end

function update()
  -- do nothing
end

function exit()
  walk.start();
end
