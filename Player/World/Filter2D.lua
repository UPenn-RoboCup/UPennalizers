module(..., package.seeall);

require('vector');
require('util')

enableVelocity = Config.vision.enable_velocity_detection or 0;
--SJ: We can use the ball model (x,y,dx,dy) 
--and update the model using current estimate of velocity
--TODO!

mod_angle = util.mod_angle;

local mt = {};

function new()
  local t = {};
  reset(t);
  return setmetatable(t, mt);
end

function reset(t)
  t.r = 1;
  t.a = 0;
  t.rVar = 1E10;
  t.aVar = 1E10;
end

function get_xy(t)
  local x = t.r * math.cos(t.a);
  local y = t.r * math.sin(t.a);
  return x, y;
end

function get_ra(t)
  return t.r, t.a;
end

function get_deviation(t)
  local dr = math.sqrt(t.rVar);
  local da = math.sqrt(t.aVar);
  return dr, da;
end

function observation_ra(t, r, a, rErr, aErr)
  rErr = rErr or 1;
  aErr = aErr or 1;
  local rVar = rErr^2;
  local aVar = aErr^2;

  local dr = r - t.r;
  t.r = t.r + (t.rVar * dr)/(t.rVar + rVar);
  local da = mod_angle(a - t.a);
  t.a = t.a + (t.aVar * da)/(t.aVar + aVar);

  t.rVar = (t.rVar * rVar)/(t.rVar + rVar);
  if (t.rVar + rVar < dr^2) then
    t.rVar = dr^2;
  end

  t.aVar = (t.aVar * aVar)/(t.aVar + aVar);
  if (t.aVar + aVar < da^2) then
    t.aVar = da^2;
  end
end

function observation_xy(t, x, y, rErr, aErr)
  rErr = rErr or 1;
  aErr = aErr or 1;
  local r = math.sqrt(x^2 + y^2);
  local a = math.atan2(y, x);
  return observation_ra(t, r, a, rErr, aErr);
end

function odometry(t, dx, dy, da, drErr, daErr)
  local x = t.r * math.cos(t.a) - dx;
  local y = t.r * math.sin(t.a) - dy;
  t.r = math.sqrt(x^2 + y^2);
  t.a = mod_angle(math.atan2(y,x) - da);

  drErr = drErr or 0.10 * math.sqrt(dx^2 + dy^2);
  daErr = daErr or 0.10 * math.abs(da);
  t.rVar = t.rVar + drErr;
  t.aVar = t.aVar + daErr;
end

mt.__index = {};
mt.__index.reset = reset;
mt.__index.get_xy = get_xy;
mt.__index.get_ra = get_ra;
mt.__index.get_deviation = get_deviation;
mt.__index.observation_ra = observation_ra;
mt.__index.observation_xy = observation_xy;
mt.__index.odometry = odometry;

