module(..., package.seeall);

require('Config');
require('wcm');
require('vector');
require('ballfilter');

x = nil;
y = nil;
vx = nil;
vy = nil;
dt = .5;

-- How much change in a timestamp can we tolerate?
outlier_dx = .05;
outlier_dy = .05;

function entry()
  obs_cnt = 1;
  t0 = unix.time();
  t = t0;
  t_old = t0;
  ballfilter.loadModel();
end

function update()
  t1 = unix.time();
  t = t1-t0;
  t_diff = t - t_old;
  t_old = t;
  obs_cnt = math.floor( t_diff * 30 + .5 ); -- Round it

  local ball = wcm.get_ball();


  if( x ~= nil and obs_count == 1) then
    -- Kill outliers
    if( math.abs(ball.x - x) > outlier_dx ) then
      return;
    end
    if( math.abs(ball.y - y) > outlier_dy ) then
      return;
    end
  end

  -- Update measurement
  x, y, vx, vy, ep, evp = ballfilter.ballme( ball.x, ball.y, obs_cnt );
  vx = 30*vx;
  vy = 30*vy;
  px = x + vx*dt;
  py = y + vy*dt;
--  z = ball.z; -- I think this is wrong right now...
  z = 0;

  -- Prediction
  isdodge = ballfilter.predictmove( x,y,z,vx,vy,px,py,ep,evp )

end

function exit()
end

function getVelocity()
  return vx, vy, isdodge;
end

function getObservationData()
  return x, y, vx, vy, ep, evp;
end

