module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('kick');
require('HeadFSM')
require('Config')
require('wcm')

require('walk');
require('dive')

t0 = 0;
tStart = 0;
timeout = 30.0;

started = false;
kickable = true;
follow = false;

tFollowDelay = Config.fsm.bodyKick.tFollowDelay;
rClose = 1.0;

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  started = false;
  follow = false;
  Motion.event("diveready");
end

function update()
  local t = Body.get_time();
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2+ ball.y^2);

  if ballR<rClose and t-ball.t<0.1 then
    Motion.event("walk");
    return "ballClose";
  end

--[[
  if ball.t<0.1 and ball.vx<-0.5 then
    dive.set_dive("diveLeft");
    Motion.event("dive");
    return "done";
  end
--]]


  if (t - t0 > timeout) then
    Motion.event("walk");
    return "timeout";
  end
end

function exit()
  walk.start();
end
