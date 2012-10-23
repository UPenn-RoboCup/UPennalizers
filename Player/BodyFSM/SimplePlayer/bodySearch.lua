module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('mcm')

t0 = 0;
direction = 1;

timeout = Config.fsm.bodySearch.timeout or 10.0*Config.speedFactor;
vSpin = Config.fsm.bodySearch.vSpin or 0.3;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();

  -- set turn direction to last known ball position
  ball = wcm.get_ball();
  if (ball.y > 0) then
    direction = 1;
    mcm.set_walk_isSearching(1);
  else
    direction = -1;
    mcm.set_walk_isSearching(-1);
  end
end

function update()
  local t = Body.get_time();

  ball = wcm.get_ball();

  -- search/spin until the ball is found
  walk.set_velocity(0, 0, direction*vSpin);

  if (t - ball.t < 0.1) then
    return "ball";
  end
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
  mcm.set_walk_isSearching(0);
end
