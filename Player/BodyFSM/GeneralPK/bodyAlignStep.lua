module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('kick');
require('HeadFSM')
require('Config')
require('wcm')
require('walk');
require('align')

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  Motion.event("align");
  walk.stop();
end

function update()
  t = Body.get_time();
  if (t - t0 > 4.0) and not align.active then
    return "done";
  end
end

function exit()
end
