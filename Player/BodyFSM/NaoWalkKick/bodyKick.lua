module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('kick');
require('HeadFSM')
require('Config')
require('wcm')

require('walk');

t0 = 0;
timeout = 20.0;

started = false;

kickable = true;


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();

  -- set kick depending on ball position
  ball = wcm.get_ball();
  if (ball.y > 0) then
    kick.set_kick("kickForwardLeft");
  else
    kick.set_kick("kickForwardRight");
  end

  --SJ - only initiate kick while walking
  kickable = walk.active;  

  HeadFSM.sm:set_state('headIdle');
  Motion.event("kick");
  started = false;
end

function update()
  local t = Body.get_time();
  if not kickable then 
     print("bodyKick escape");
     --Set velocity to 0 after kick fails ot prevent instability--
     walk.setVelocity(0, 0, 0);
     return "done";
  end
  
  if (not started and kick.active) then
    started = true;
  elseif (started and not kick.active) then
  	--Set velocity to 0 after kick to prevent instability--
  	walk.still=true;
  	walk.set_velocity(0, 0, 0);
    return "done";
  end

  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
  HeadFSM.sm:set_state('headTrack');
end
