module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
require('wcm')
require('gcm')

t0 = 0;

tStepOut = 5.0;
function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();
  walk.set_velocity(0.04,0,0);

  if (t-t0>tStepOut) then
    return "done";
  end
end

function exit()
  walk.stop();
end

