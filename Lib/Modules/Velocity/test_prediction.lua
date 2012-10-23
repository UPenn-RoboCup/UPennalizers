--http://wiki.garrysmod.com/?title=Patterns
require 'velocityfilter'
ballfilter.loadModel();

-- 0 1:1.013398 2:0.022444 3:1.013647 4:0.034000 5:0.006371 6:0.007038 7:1.016584 8:0.025963 9:1.016915 10:4.868166 11:38.901387

filename = 'Matlab/logfiles/ml_pred_full.txt'
local f = assert(io.open(filename, 'r'))
local pat = "(%d+):(-?%w+.%w+)"

mismatches = 0;
count = 0;
for line in f:lines() do
  local t = {}
  t[1] = 10;
--  print(line)
  local class = tonumber( string.sub(line, 0, 1) );
  local found = string.gfind( line, pat);
  for k, v in found do
    t[tonumber(k)] = tonumber(v)
    if( tonumber(v)==nil ) then t[tonumber(k)]=0;end;
--    print( "Key: "..tonumber(k)..", Value: "..tonumber(v) )
  end

  x = t[1];
  y = t[2];
  z = t[3];
  vx = 30*t[5];
  vy = 30*t[6];
  px = t[7];
  py = t[8];
  ep = t[10];
  evp = t[11];
  
  --print("Predicting...")
  dodge = ballfilter.predictmove( x,y,z,vx,vy,px,py,ep,evp )

  if( class ~= dodge ) then
    mismatches = mismatches + 1;
  end
  count = count + 1;

  if( dodge ~= 0 ) then
    print("Dodge! "..dodge)
  end

end

print("Success rate: "..(1-mismatches/count))

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
  print( ballfilter.ballme( i/30, 10, 1 ) );
end


