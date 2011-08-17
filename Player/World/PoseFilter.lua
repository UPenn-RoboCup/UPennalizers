module(..., package.seeall);

require('Config');
require('vector');
require 'util'

n = Config.world.n;
xLineBoundary = Config.world.xLineBoundary;
yLineBoundary = Config.world.yLineBoundary;
xMax = Config.world.xMax;
yMax = Config.world.yMax;

goalWidth = Config.world.goalWidth;
postYellow = Config.world.postYellow;
postCyan = Config.world.postCyan;
landmarkYellow = Config.world.landmarkYellow;
landmarkCyan = Config.world.landmarkCyan;
spot = Config.world.spot;
ballYellow = Config.world.ballYellow;
ballCyan = Config.world.ballCyan;
landmarkYellow = Config.world.landmarkYellow;
landmarkCyan = Config.world.landmarkCyan;

rGoalFilter = Config.world.rGoalFilter;
aGoalFilter = Config.world.aGoalFilter;
rPostFilter = Config.world.rPostFilter;
aPostFilter = Config.world.aPostFilter;


xp = .5*xMax*vector.new(util.randn(n));
yp = .5*yMax*vector.new(util.randn(n));
ap = 2*math.pi*vector.new(util.randu(n));
wp = vector.zeros(n);

function initialize(p0, dp)
  p0 = p0 or {0, 0, 0};
  dp = dp or {.5*xMax, .5*yMax, 2*math.pi};

  xp = p0[1]*vector.ones(n) + dp[1]*vector.new(util.randn(n));
  yp = p0[2]*vector.ones(n) + dp[2]*vector.new(util.randn(n));
  ap = p0[3]*vector.ones(n) + dp[3]*vector.new(util.randu(n));
  wp = vector.zeros(n);
end

function reset_heading()
  ap = 2*math.pi*vector.new(util.randu(n));
  wp = vector.zeros(n);
end

function get_pose()
  local wmax, imax = max(wp);
  return xp[imax], yp[imax], mod_angle(ap[imax]);
end

function get_sv(x0, y0, a0)
  -- weighted sample variance of current particles
  local xs = 0.0;
  local ys = 0.0;
  local as = 0.0;
  local ws = 0.0001;

  for i = 1,n do
    local dx = x0 - xp[i];
    local dy = y0 - yp[i];
    local da = mod_angle(a0 - ap[i]);
    xs = xs + wp[i]*dx^2;
    ys = ys + wp[i]*dy^2;
    as = as + wp[i]*da^2;
    ws = ws + wp[i];
  end

  return math.sqrt(xs)/ws, math.sqrt(ys)/ws, math.sqrt(as)/ws;
end

function landmark_ra(xlandmark, ylandmark)
  local r = vector.zeros(n);
  local a = vector.zeros(n);
  for i = 1,n do
    local dx = xlandmark - xp[i];
    local dy = ylandmark - yp[i];
    r[i] = math.sqrt(dx^2 + dy^2);
    a[i] = math.atan2(dy, dx) - ap[i];
  end
  return r, a;
end

function landmark_observation(pos, v, rLandmarkFilter, aLandmarkFilter)
  local r = math.sqrt(v[1]^2 + v[2]^2);
  local a = math.atan2(v[2], v[1]);
  local rSigma = .15*r + 0.10;
  local aSigma = 5*math.pi/180;
  local rFilter = rLandmarkFilter or 0.02;
  local aFilter = aLandmarkFilter or 0.04;

  --Calculate best matching landmark pos to each particle
  local dxp = {};
  local dyp = {};
  local dap = {};
  for ip = 1,n do
    local dx = {};
    local dy = {};
    local dr = {};
    local da = {};
    local err = {};
    for ipos = 1,#pos do
      dx[ipos] = pos[ipos][1] - xp[ip];
      dy[ipos] = pos[ipos][2] - yp[ip];
      dr[ipos] = math.sqrt(dx[ipos]^2 + dy[ipos]^2) - r;
      da[ipos] = mod_angle(math.atan2(dy[ipos],dx[ipos]) - (ap[ip] + a));
      err[ipos] = (dr[ipos]/rSigma)^2 + (da[ipos]/aSigma)^2;
    end
    local errMin, imin = min(err);

    --Update particle weights:
    wp[ip] = wp[ip] - errMin;

    dxp[ip] = dx[imin];
    dyp[ip] = dy[imin];
    dap[ip] = da[imin];
  end

  --Filter toward best matching landmark position:
  for ip = 1,n do
    xp[ip] = xp[ip] + rFilter * (dxp[ip] - r * math.cos(ap[ip] + a));
    yp[ip] = yp[ip] + rFilter * (dyp[ip] - r * math.sin(ap[ip] + a));
    ap[ip] = ap[ip] + aFilter * dap[ip];

    -- check boundary
    xp[ip] = math.min(xMax, math.max(-xMax, xp[ip]));
    yp[ip] = math.min(yMax, math.max(-yMax, yp[ip]));
  end
end

function goal_observation(pos, v)
  -- Use angle between posts (most accurate)
  -- as well as combination of post distances to triangulate
  local aPost = {};
  aPost[1] = math.atan2(v[1][2], v[1][1]);
  aPost[2] = math.atan2(v[2][2], v[2][1]);
  local daPost = mod_angle(aPost[1]-aPost[2]);

  -- Radius of circumscribing circle
  local sa = math.sin(math.abs(daPost));
  local ca = math.cos(daPost);
  local rCircumscribe = goalWidth/(2*sa);

  -- Post distances
  local d2Post = {};
  d2Post[1] = v[1][1]^2 + v[1][2]^2;
  d2Post[2] = v[2][1]^2 + v[2][2]^2;
  local ignore, iMin = min(d2Post);

  -- Position relative to center of goal:
  local sumD2 = d2Post[1] + d2Post[2];
  local dGoal = math.sqrt(.5*sumD2);
  local dx = (sumD2 - goalWidth^2)/(4*rCircumscribe*ca);
  local dy = math.sqrt(math.max(.5*sumD2-.25*goalWidth^2-dx^2, 0));

  -- Predicted pose:
  local x = pos[iMin][1];
  x = x - sign(x) * dx;
  local y = pos[iMin][2];
  y = sign(y) * dy;
  local a = math.atan2(pos[iMin][2] - y, pos[iMin][1] - x) - aPost[iMin];

  local rSigma = .25*dGoal + 0.20;
  local aSigma = 5*math.pi/180;

  local rFilter = rGoalFilter;
  local aFilter = aGoalFilter;

  for ip = 1,n do
    local xErr = x - xp[ip];
    local yErr = y - yp[ip];
    local rErr = math.sqrt(xErr^2 + yErr^2);
    local aErr = mod_angle(a - ap[ip]);
    local err = (rErr/rSigma)^2 + (aErr/aSigma)^2;
    wp[ip] = wp[ip] - err;

    --Filter towards goal:
    xp[ip] = xp[ip] + rFilter*xErr;
    yp[ip] = yp[ip] + rFilter*yErr;
    ap[ip] = ap[ip] + aFilter*aErr;
  end
end

function ball_yellow(v)
  goal_observation(ballYellow, v);
end

function ball_cyan(v)
  goal_observation(ballCyan, v);
end

function goal_yellow(v)
  goal_observation(postYellow, v);
end

function goal_cyan(v)
  goal_observation(postCyan, v);
end

function post_yellow_unknown(v)
  landmark_observation(postYellow, v[1], rPostFilter, aPostFilter);
end

function post_yellow_left(v)
  landmark_observation({postYellow[1]}, v[1], rPostFilter, aPostFilter);
end

function post_yellow_right(v)
  landmark_observation({postYellow[2]}, v[1], rPostFilter, aPostFilter);
end

function post_cyan_unknown(v)
  landmark_observation(postCyan, v[1], rPostFilter, aPostFilter);
end

function post_cyan_left(v)
  landmark_observation({postCyan[1]}, v[1], rPostFilter, aPostFilter);
end

function post_cyan_right(v)
  landmark_observation({postCyan[2]}, v[1], rPostFilter, aPostFilter);
end

function line(v, a)
  -- line center
  x = v[1];
  y = v[2];
  r = math.sqrt(x^2 + y^2);

  w0 = .25 / (1 + r/2.0);

  -- TODO: wrap in loop for lua
  for ip = 1,n do
    -- pre-compute sin/cos of orientations
    ca = math.cos(ap[ip]);
    sa = math.sin(ap[ip]);

    -- compute line weight
    local wLine = w0 * (math.cos(4*(ap[ip] + a)) - 1);
    wp[ip] = wp[ip] + wLine;

    local xGlobal = v[1]*ca - v[2]*sa + xp[ip];
    local yGlobal = v[1]*sa + v[2]*ca + yp[ip];

    wBounds = math.max(xGlobal - xLineBoundary, 0) + 
              math.max(-xGlobal - xLineBoundary, 0) + 
              math.max(yGlobal - yLineBoundary, 0) +
              math.max(-yGlobal - yLineBoundary, 0);
    wp[ip] = wp[ip] - (wBounds/.20);
  end
end

function odometry(dx, dy, da)
  for ip = 1,n do
    ca = math.cos(ap[ip]);
    sa = math.sin(ap[ip]);
    xp[ip] = xp[ip] + dx*ca - dy*sa;
    yp[ip] = yp[ip] + dx*sa + dy*ca;
    ap[ip] = ap[ip] + da;
  end
end

function zero_pose()
  xp = vector.zeros(n);
  yp = vector.zeros(n);
  ap = vector.zeros(n);
end

function max(t)
  local imax = 0;
  local tmax = -math.huge;
  for i = 1,#t do
    if (t[i] > tmax) then
      tmax = t[i];
      imax = i;
    end
  end
  return tmax, imax;
end

function min(t)
  local imin = 0;
  local tmin = math.huge;
  for i = 1,#t do
    if (t[i] < tmin) then
      tmin = t[i];
      imin = i;
    end
  end
  return tmin, imin;
end

function sign(x)
  if (x > 0) then
    return 1;
  elseif (x < 0) then
    return -1;
  else
    return 0;
  end
end

function mod_angle(a)
  a = a % (2*math.pi);
  if (a >= math.pi) then
    a = a - 2*math.pi;
  end
  return a;
end

function addNoise()
  add_noise();
end

function add_noise()
  da = 2.0*math.pi/180.0;
  dr = 0.01;
  xp = xp + dr * vector.new(util.randn(n));
  yp = yp + dr * vector.new(util.randn(n));
  ap = ap + da * vector.new(util.randn(n));
end

function resample()
  -- resample particles

  local wLog = {};
  for i = 1,n do
    -- cutoff boundaries
    wBounds = math.max(xp[i]-xMax,0)+math.max(-xp[i]-xMax,0)+
              math.max(yp[i]-yMax,0)+math.max(-yp[i]-yMax,0);
    wLog[i] = wp[i] - wBounds/0.1;
    xp[i] = math.max(math.min(xp[i], xMax), -xMax);
    yp[i] = math.max(math.min(yp[i], yMax), -yMax);
  end

  --Calculate effective number of particles
  wMax, iMax = max(wLog);
  -- total sum
  local wSum = 0;
  -- sum of squares
  local wSum2 = 0;
  local w = {};
  for i = 1,n do
    w[i] = math.exp(wLog[i] - wMax);
    wSum = wSum + w[i];
    wSum2 = wSum2 + w[i]^2;
  end

  local nEffective = (wSum^2) / wSum2;
  if nEffective > .25*n then
    return; 
  end

  -- cum sum of weights
  -- wSum[i] = {cumsum(i), index}
  -- used for retrieving the sorted indices
  local wSum = {};
  wSum[1] = {w[1], 1};
  for i = 2,n do
     wSum[i] = {wSum[i-1][1] + w[i], i};
  end

  --normalize
  for i = 1,n do
    wSum[i][1] = wSum[i][1] / wSum[n][1];
  end

  --Add n more particles and resample high n weighted particles
  local rx = util.randu(n);
  local wSum_sz = #wSum;
  for i = 1,n do 
    table.insert(wSum, {rx[i], n+i});
  end

  -- sort wSum min->max
  table.sort(wSum, function(a,b) return a[1] < b[1] end);

  -- resample (replace low weighted particles)
  xp2 = vector.zeros(n); 
  yp2 = vector.zeros(n);
  ap2 = vector.zeros(n);
  nsampleSum = 1;
  ni = 1;
  for i = 1,2*n do
    oi = wSum[i][2];
    if oi > n then
      xp2[ni] = xp[nsampleSum];
      yp2[ni] = yp[nsampleSum];
      ap2[ni] = ap[nsampleSum];
      ni = ni + 1;
    else
      nsampleSum = nsampleSum + 1;
    end
  end

  -- always put max particle
  xp2[1] = xp[iMax];
  yp2[1] = yp[iMax];
  ap2[1] = ap[iMax];

  xp = xp2;
  yp = yp2;
  ap = ap2;
  wp = vector.zeros(n);
end
