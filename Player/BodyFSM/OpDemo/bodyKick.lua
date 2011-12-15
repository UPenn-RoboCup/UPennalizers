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
tStart = 0;
timeout = 20.0;

started = false;
kickable = true;
follow = false;

tFollowDelay = 2.2; --for straight kick


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

  Motion.event("kick");
  started = false;
  follow = false;

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
    tStart =t;
  elseif started then
    if kick.active then
      if follow==false and t-tStart > tFollowDelay then
  	HeadFSM.sm:set_state('headKickFollow');
	follow=true;
      end
    else --Kick ended
  	--Set velocity to 0 after kick to prevent instability--
      walk.still=true;
      walk.set_velocity(0, 0, 0);
      return "done";
    end
  end

  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
end
