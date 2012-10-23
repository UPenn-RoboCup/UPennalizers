require 'velocityfilter'

--[[
x, y, vx, vy, ep, evp = ballfilter.ballme( ball.v[1], ball.v[2], obs_cnt );
vx = 30*vx;
vy = 30*vy;
px = x + vx*dt;
py = y + vy*dt;

-- Prediction
isdodge = ballfilter.predictmove(x,y,vx,vy,px,py,ep,evp);
--]]

for i=1,10 do
  print( velocityfilter.get_ball( i/30, 10, 1 ) );
end


