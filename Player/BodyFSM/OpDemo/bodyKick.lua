module(..., package.seeall);

require('Body')
require('wcm')
require('vector')
require('Motion');
require('kick');

require('walk');

t0 = 0;
timeout = 5.0;
started = false;

--by SJ
kickable=true;

function entry()
  print("Body FSM:".._NAME.." entry");

  t0 = Body.get_time();
  -- set kick depending on ball position
  ball = wcm.get_ball();
  if (ball.y > 0) then
    kick.set_kick("kickForwardLeft");
  else
    kick.set_kick("kickForwardRight");
  end
--SJ - only initiate kick while walking
  kickable=walk.active;  
  Motion.event("kick");
  started = false;
end

function update()
  local t = Body.get_time();
  if (t - t0 > timeout) then
    return "timeout";
  end

  if not kickable then 
     print("bodyKick escape");
     return "done";
  end
  
  if (not started and kick.active) then
    started = true;
  elseif (started and not kick.active) then
    return "done";
  end
end

function exit()
end
