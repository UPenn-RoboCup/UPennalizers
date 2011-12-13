module(..., package.seeall);

require('Body')
require('Motion')

function entry()
  print(_NAME..' entry');

  walk.set_velocity(0,0,0);
  walk.stop();
  started = false;
end

function update()
  --for webots : we have to stop with 0 bodytilt
  if not started then
    if not walk.active then
    Motion.sm:set_state('standstill');
    started = true;
    end
  end
  
end

function exit()
  Motion.sm:add_event('walk');
end
