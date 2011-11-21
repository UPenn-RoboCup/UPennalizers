module(..., package.seeall);

require('Body')
require('World')
require('vector')
require('Motion');
require('pickup');
require('walk');
require('wcm');

t0 = 0;
timeout = 20.0;
started = false;

--by SJ
kickable=true;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();

  -- set kick depending on ball position

  local ball = wcm.get_ball();
  if( t0 - ball.t < .5 ) then -- Just saw it
	  pickup.setdistance( ball.x );
  end

  --SJ - only initiate kick while walking
  kickable = walk.active;  
  pickup.throw = 0;
  Motion.event("pickup");
  started = false;
end

function update()
  local t = Body.get_time();
  if not kickable then 
   print("bodyPickup escape");
   return "done";
  end
  
  if (not started and pickup.active) then
    started = true;
  elseif (started and not pickup.active) then
    return "done";
  end

  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
   walk.start();
end
