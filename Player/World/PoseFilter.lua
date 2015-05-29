module(..., package.seeall);

require('Config');
require('vector');
require('vcm');
require('gcm');
require('util');

n = Config.world.n;
xLineBoundary = Config.world.xLineBoundary;
yLineBoundary = Config.world.yLineBoundary;
xMax = Config.world.xMax;
yMax = Config.world.yMax;

goalWidth = Config.world.goalWidth;
postYellow = Config.world.postYellow;
postCyan = Config.world.postCyan;
spotWhite = Config.world.spot;
ballYellow = Config.world.ballYellow;
ballCyan = Config.world.ballCyan;
Lcorner = Config.world.Lcorner;
Lgoalie_corner = Config.world.Lgoalie_corner;

--Triangulation method selection
use_new_goalposts= Config.world.use_new_goalposts or 0;
if Config.game.playerID > 1 then
  triangulation_threshold=Config.world.triangulation_threshold or 4.0;
  position_update_threshold = Config.world.position_update_threshold or 6.0;
else
  -- smaller threshold for the goalie
  triangulation_threshold=Config.world.triangulation_threshold_goalie or 3.0;
  position_update_threshold = Config.world.position_update_threshold_goalie or 3.0;
end
angle_update_threshold = Config.world.angle_update_threshold or 0.6;

--For single-colored goalposts
postUnified = {postYellow[1],postYellow[2],postCyan[1],postCyan[2]};
postLeft={postYellow[1],postCyan[1]}
postRight={postYellow[2],postCyan[2]}

--position and angle update rates
rGoalFilter = Config.world.rGoalFilter or 0.02;
aGoalFilter = Config.world.aGoalFilter or 0.05;
rPostFilter = Config.world.rPostFilter or 0.01;
aPostFilter = Config.world.aPostFilter or 0.03;
rPostFilter2 = Config.world.rPostFilter2 or 0.01;
aPostFilter2 = Config.world.aPostFilter2 or 0.03;
rCornerFilter = Config.world.rCornerFilter or 0.01;
aCornerFilter = Config.world.aCornerFilter or 0.03;
if(gcm.get_team_role() == 0) then
    rCornerFilter = rCornerFilter + 0.02;
    aCornerFilter = aCornerFilter + 0.02;
end

--Sigma values for one landmark observation
rSigmaSingle1 = Config.world.rSigmaSingle1 or .15;
rSigmaSingle2 = Config.world.rSigmaSingle2 or .10;
aSigmaSingle = Config.world.aSigmaSingle or 50*math.pi/180;

--Sigma values for goal observation
rSigmaDouble1 = Config.world.rSigmaSingle1 or .25;
rSigmaDouble2 = Config.world.rSigmaSingle2 or .20;
aSigmaDouble = Config.world.aSigmaSingle or 50*math.pi/180;

daNoise = Config.world.daNoise or 2.0*math.pi/180.0;
drNoise = Config.world.drNoise or 0.01;

dont_reset_orientation = Config.world.dont_reset_orientation or 0;



xp = .5*xMax*vector.new(util.randn(n)); -- x coordinate of each particle
yp = .5*yMax*vector.new(util.randn(n)); -- y coordinate
ap = 2*math.pi*vector.new(util.randu(n)); -- angle
wp = vector.zeros(n); -- weight

---Initializes a gaussian distribution of particles centered at p0
--@param p0 center of distribution
--@param dp scales how wide the distrubution is
function initialize(p0, dp)
  p0 = p0 or {0, 0, 0};
  dp = dp or {.5*xMax, .5*yMax, 2*math.pi};

  xp = p0[1]*vector.ones(n) + dp[1]*(vector.new(util.randn(n))-0.5*vector.ones(n));
  yp = p0[2]*vector.ones(n) + dp[2]*(vector.new(util.randn(n))-0.5*vector.ones(n));
  ap = p0[3]*vector.ones(n) + dp[3]*(vector.new(util.randu(n))-0.5*vector.ones(n));
  wp = vector.zeros(n);
end

function initialize_manual_placement(p0, dp)
  p0 = p0 or {0, 0, 0};
  dp = dp or {.5*xLineBoundary, .5*yLineBoundary, 2*math.pi};

  print('re-init partcles for manual placement');
  ap = math.atan2(wcm.get_goal_attack()[2],wcm.get_goal_attack()[1])*vector.ones(n);
  xp = wcm.get_goal_defend()[1]/2*vector.ones(n);
  yp = p0[2]*vector.ones(n) + dp[2]*(vector.new(util.randn(n))-0.5*vector.ones(n));
  wp = vector.zeros(n);
end

function initialize_unified(p0,p1,dp)
  init_override = Config.world.init_override or 0;
  if init_override == 1 then --High kick challenge
    for i=1,n do
      xp[i]=0;
      yp[i]=0;
      ap[i]=5*math.pi/180  * (math.random()-.5);
    end
    wp = vector.zeros(n);
    return;
  end
  --Particle initialization for the same-colored goalpost
  --Half of the particles at p0
  --Half of the particles at p1
  p0 = p0 or {0, 0, 0};
  p1 = p1 or {0, 0, 0};
  --Low spread  
  dp = dp or {.15*xMax, .15*yMax, math.pi/6};
  dp = dp or {.1*xMax, .1*yMax, math.pi/8};

  for i=1,n/2 do    
    -- xp[i]=p0[1]+dp[1]*(math.random()-.5); 
    -- yp[i]=p0[2]+dp[2]*(math.random()-.5);

    local normalRand = util.randn2()
    xp[i]=p0[1]+dp[1]*normalRand[1]; 
    yp[i]=p0[2]+dp[2]*normalRand[2];
    ap[i]=p0[3]+dp[3]*(math.random()-.5);

    -- xp[i+n/2]=p1[1]+dp[1]*(math.random()-.5);
    -- yp[i+n/2]=p1[2]+dp[2]*(math.random()-.5);
    
    normalRand = util.randn2()
    xp[i+n/2]=p1[1]+dp[1]*normalRand[1];
    yp[i+n/2]=p1[2]+dp[2]*normalRand[2];    
    ap[i+n/2]=p1[3]+dp[3]*(math.random()-.5);
  end
  wp = vector.zeros(n);
end

function initialize_heading(aGoal)
  --Particle initialization at bodySet 
  --When bodySet, all players should face opponents' goal
  --So reduce weight of  particles that faces our goal
  print('init_heading particles');
  dp = dp or {.15*xMax, .15*yMax, math.pi/6};
  ap = aGoal*vector.ones(n) + dp[3]*vector.new(util.randu(n));
  wp = vector.zeros(n);
end

---Sets headings of all particles to random angles with 0 weight
--@usage For when robot falls down
function reset_heading()
  if dont_reset_orientation == 0 then
    ap = 2*math.pi*vector.new(util.randu(n));
    wp = vector.zeros(n);
  else

  end
end

function flip_particles()
  xp = -xp;
  yp = -yp;
    for i = 1, n do
      if ap[i] <= math.pi then
        ap[i] = ap[i] + math.pi;
      else
        ap[i] = ap[i] - math.pi;
      end
    end
end 

---Returns best pose out of all particles
function get_pose()
  local wmax, imax = max(wp);
  return xp[imax], yp[imax], mod_angle(ap[imax]);
end

---Caluclates weighted sample variance of current particles.
--@param x0 x coordinates of current particles
--@param y0 y coordinates of current particles
--@param a0 angles of current particles
--@return weighted sample variance of x coordinates, y coordinates, and angles
function get_sv(x0, y0, a0)
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

---Calcualtes distance and angle from each particle to landmark
--@param xlandmark x coordinate of landmark in world frame
--@param ylandmark y coordinate of landmark in world frame
--@return r distance from landmark to each particle
--@return a angle between landmkark and each particle
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

---Updates particles with respect to the detection of a landmark
--@param pos Table of possible positions for a landmark
--@param v x and y coordinates of detected landmark relative to robot
--@param rLandmarkFilter How much to adjust particles according to
--distance to landmark
--@param aLandmarkFilter How much to adjust particles according to 
--angle to landmark
function landmark_observation(pos, v, rLandmarkFilter, aLandmarkFilter,dont_update_position)

  -- local p = wcm.get_pose()
  -- if math.sqrt(p.x^2 + p.y^2) < 1 then
  --     dont_update_position = 1
  -- end

  local r = math.sqrt(v[1]^2 + v[2]^2);
  local a = math.atan2(v[2], v[1]);

  local rSigma = rSigmaSingle1 * r + rSigmaSingle2;
  local aSigma = aSigmaSingle;

  local rFilter = rLandmarkFilter or 0.02;
  local aFilter = aLandmarkFilter or 0.04;

  --TODO: If landmark is very far, increase? the rate 
  local rFactor, aFactor = 0,0
  if r > 2 then rFactor = r/2*0.05 end
  if a > math.pi/2 then aFactor = a/(math.pi/2)*0.05 end
  
  -- rFilter = rFilter + rFactor
  -- aFilter = aFilter + aFactor

  --If we see a landmark at very close range
  --A small positional error can change the angle a lot
          --So we do not update angle if the distance is very small 
          if Config.game.playerID == 1 then
            angle_update_threshold = math.huge
          else
            angle_update_threshold = 3
          end

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

              if dont_update_position==1 then --only angle error
                err[ipos] = (da[ipos]/aSigma)^2;
              else --position and angle error
                err[ipos] = (dr[ipos]/rSigma)^2 + (da[ipos]/aSigma)^2;
              end
            end
            local errMin, imin = min(err);

            --Update particle weights:
            wp[ip] = wp[ip] - errMin;
            dxp[ip] = dx[imin];
            dyp[ip] = dy[imin];
            dap[ip] = da[imin];
        --[[
            if ip % 40 == 0 then
                print("drp[ip] "..math.sqrt(dxp[ip]^2 + dyp[ip]^2));
                print("dap[ip] "..dap[ip]);
            end
        ]]--
          end
          --Filter toward best matching landmark position:
          for ip = 1,n do
            --print(string.format("%d %.1f %.1f %.1f",ip,xp[ip],yp[ip],ap[ip]));
            if not (dont_update_position==1) and r < position_update_threshold then
              --print(type(xp), type(dxp), type(ap))
              xp[ip] = xp[ip] + rFilter * (dxp[ip] - r * math.cos(ap[ip] + a));
              yp[ip] = yp[ip] + rFilter * (dyp[ip] - r * math.sin(ap[ip] + a));
            end

            if r > angle_update_threshold then
      ap[ip] = ap[ip] + aFilter * dap[ip];
    end
 
    -- check boundary
    xp[ip] = math.min(xMax, math.max(-xMax, xp[ip]));
    yp[ip] = math.min(yMax, math.max(-yMax, yp[ip]));
  end
end

---Update particles according to a goal detection
--@param pos All possible positions of the goals
--For example, each post location is an entry in pos
--@param v x and y coordinates of detected goal relative to robot
--function goal_observation(pos, v)
---------------------------------------------------------------------------
-- Now we have two ambiguous goals to check
-- So we separate the triangulation part and the update part
---------------------------------------------------------------------------

function triangulate(pos,v)
  --Based on old code

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

  pose={};
  pose.x=x;
  pose.y=y;
  pose.a=a;
 
  aGoal = util.mod_angle((aPost[1]+aPost[2])/2);

  return pose,dGoal,aGoal;
end

function triangulate2(pos,v)

  --New code (for OP)
   local aPost = {};
   local d2Post = {};

   aPost[1] = math.atan2(v[1][2], v[1][1]);
   aPost[2] = math.atan2(v[2][2], v[2][1]);
   d2Post[1] = v[1][1]^2 + v[1][2]^2;
   d2Post[2] = v[2][1]^2 + v[2][2]^2;
   d1 = math.sqrt(d2Post[1]);
   d2 = math.sqrt(d2Post[2]);

   vcm.add_debug_message(string.format(
	"===\n World: triangulation 2\nGoal dist: %.1f / %.1f\nGoal width: %.1f\n",
	d1, d2 ,goalWidth ));


   vcm.add_debug_message(string.format(
	"Measured goal width: %.1f\n",
	 math.sqrt((v[1][1]-v[2][1])^2+(v[1][2]-v[2][2])^2)
	));

--SJ: still testing 
   postfix=1;
   postfix=0;

   if postfix>0 then

     if d1>d2 then 
       --left post correction based on right post
       -- v1=kcos(a1),ksin(a1)
       -- k^2 - 2k(v[2][1]cos(a1)+v[2][2]sin(a1)) + d2Post[2]-goalWidth^2 = 0
       local ca=math.cos(aPost[1]);
       local sa=math.sin(aPost[1]);
       local b=v[2][1]*ca+ v[2][2]*sa;
       local c=d2Post[2]-goalWidth^2;

       if b*b-c>0 then
         vcm.add_debug_message("Correcting left post\n");
         vcm.add_debug_message(string.format("Left post angle: %d\n",aPost[1]*180/math.pi));

         k1=b-math.sqrt(b*b-c);
         k2=b+math.sqrt(b*b-c);
         vcm.add_debug_message(string.format("d1: %.1f v1: %.1f %.1f\n",
    		d1,v[1][1],v[1][2]));
         vcm.add_debug_message(string.format("k1: %.1f v1_1: %.1f %.1f\n",
		k1,k1*ca,k1*sa ));
         vcm.add_debug_message(string.format("k2: %.1f v1_2: %.1f %.1f\n",
		k2,k2*ca,k2*sa ));
         if math.abs(d2-k1)<math.abs(d2-k2) then
  	        v[1][1],v[1][2]=k1*ca,k1*sa;
         else
	          v[1][1],v[1][2]=k2*ca,k2*sa;
         end
       end
     else 
       --right post correction based on left post
       -- v2=kcos(a2),ksin(a2)
       -- k^2 - 2k(v[1][1]cos(a2)+v[1][2]sin(a2)) + d2Post[1]-goalWidth^2 = 0
       local ca=math.cos(aPost[2]);
       local sa=math.sin(aPost[2]);
       local b=v[1][1]*ca+ v[1][2]*sa;
       local c=d2Post[1]-goalWidth^2;
  
       if b*b-c>0 then
         k1=b-math.sqrt(b*b-c);
         k2=b+math.sqrt(b*b-c);
         vcm.add_debug_message(string.format("d2: %.1f v2: %.1f %.1f\n",
    	d2,v[2][1],v[2][2]));
         vcm.add_debug_message(string.format("k1: %.1f v2_1: %.1f %.1f\n",
  	k1,k1*ca,k1*sa ));
         vcm.add_debug_message(string.format("k2: %.1f v2_2: %.1f %.1f\n",
  	k2,k2*ca,k2*sa ));
         if math.abs(d2-k1)<math.abs(d2-k2) then
            v[2][1],v[2][2]=k1*ca,k1*sa;
         else
            v[2][1],v[2][2]=k2*ca,k2*sa;
         end
       end
     end

   end

   --Use center of the post to fix angle
   vGoalX=0.5*(v[1][1]+v[2][1]);
   vGoalY=0.5*(v[1][2]+v[2][2]);
   rGoal = math.sqrt(vGoalX^2+vGoalY^2);

   if aPost[1]<aPost[2] then
     aGoal=-math.atan2 ( v[1][1]-v[2][1] , -(v[1][2]-v[2][2]) ) ;
   else
     aGoal=-math.atan2 ( v[2][1]-v[1][1] , -(v[2][2]-v[1][2]) ) ;
   end   

   ca=math.cos(aGoal);
   sa=math.sin(aGoal);
   
   local dx = ca*vGoalX-sa*vGoalY;
   local dy = sa*vGoalX+ca*vGoalY;

   local x0 = 0.5*(pos[1][1]+pos[2][1]);
   local y0 = 0.5*(pos[1][2]+pos[2][2]);

   local x = x0 - sign(x0)*dx;
   local y = -sign(x0)*dy;
   local a=aGoal;
   if x0<0 then a=mod_angle(a+math.pi); end
   local dGoal = rGoal;

   pose={};
   pose.x=x;
   pose.y=y;
   pose.a=a;

 --  aGoal = util.mod_angle((aPost[1]+aPost[2])/2);

   return pose,dGoal,aGoal;
end











function goal_observation_unified(pos1,pos2,v)
  vcm.add_debug_message("World: Ambiguous two posts")

  --Get pose estimate from two goalpost locations
  if use_new_goalposts==1 then
    pose1,dGoal1=triangulate2(pos1,v);
    pose2,dGoal2=triangulate2(pos2,v);
  else
    pose1,dGoal1=triangulate(pos1,v);
    pose2,dGoal2=triangulate(pos2,v);
  end

  local p = wcm.get_pose()
  local d1 = math.sqrt((p.x - pose1.x)^2 + (p.y - pose1.y)^2)
  local d2 = math.sqrt((p.x - pose2.x)^2 + (p.y - pose2.y)^2)
  local pose = {}
  local dGoal = 0

  if d1 > d2 then
      pose = pose1
      dGoal = dGoal1
  else
      pose = pose2
      dGoal = dGoal2
  end

  if dGoal<triangulation_threshold then 
    -- print("dGoal in triangulation thres\n")
    
    --Goal close, triangulate
    local x1,y1,a1=pose1.x,pose1.y,pose1.a;
    local x2,y2,a2=pose2.x,pose2.y,pose2.a;

    --SJ: I think rSigma is too large / aSigma too small
    --If the robot has little pos error and big angle error
    --It will pulled towared flipped position

    local rSigma = rSigmaDouble1 * dGoal1 + rSigmaDouble2;
    local aSigma = aSigmaDouble;

    local rFilter = rGoalFilter;
    local aFilter = aGoalFilter;

    for ip = 1,n do
      local xErr1 = x1 - xp[ip];
      local yErr1 = y1 - yp[ip];
      local rErr1 = math.sqrt(xErr1^2 + yErr1^2);
      local aErr1 = mod_angle(a1 - ap[ip]);
      local err1 = (rErr1/rSigma)^2 + (aErr1/aSigma)^2;

      local xErr2 = x2 - xp[ip];
      local yErr2 = y2 - yp[ip];
      local rErr2 = math.sqrt(xErr2^2 + yErr2^2);
      local aErr2 = mod_angle(a2 - ap[ip]);
      local err2 = (rErr2/rSigma)^2 + (aErr2/aSigma)^2;

      --SJ: distant goals are more noisy
 
      --Filter towards best matching goal:
      if err1>err2 then
        wp[ip] = wp[ip] - err2;
        xp[ip] = xp[ip] + rFilter*xErr2;
        yp[ip] = yp[ip] + rFilter*yErr2;
        ap[ip] = ap[ip] + aFilter*aErr2;
      else
        wp[ip] = wp[ip] - err1;
        xp[ip] = xp[ip] + rFilter*xErr1;
        yp[ip] = yp[ip] + rFilter*yErr1;
        ap[ip] = ap[ip] + aFilter*aErr1;
      end
    end
  elseif dGoal<position_update_threshold then
    -- print("dGoal in mid-range\n")
    
    --Goal midrange, use a point update
    --Goal too far, use a point estimate
    goalpos1={(pos1[1][1]+pos1[2][1])/2, (pos1[1][2]+pos1[2][2])/2}
    goalpos2={(pos2[1][1]+pos2[2][1])/2, (pos2[1][2]+pos2[2][2])/2}
    goalv={(v[1][1]+v[2][1])/2, (v[1][2]+v[2][2])/2}
    landmark_observation(
	    {goalpos1,goalpos2},
	    goalv , rUnknownPostFilter, aUnknownGoalFilter);
  else --Goal VERY far, just update angle only
    -- print("dGoal farther than position update thres\n")

    goalpos1={(pos1[1][1]+pos1[2][1])/2, (pos1[1][2]+pos1[2][2])/2}
    goalpos2={(pos2[1][1]+pos2[2][1])/2, (pos2[1][2]+pos2[2][2])/2}
    goalv={(v[1][1]+v[2][1])/2, (v[1][2]+v[2][2])/2}
    landmark_observation(
	    {goalpos1,goalpos2},
	    goalv , rUnknownGoalFilter, aUnknownGoalFilter,1);
  end
end

function get_goal_defend()
  if gcm.get_team_color() == 1 then
    -- red defends yellow goal
    return {postYellow[1][1], 0, 0};
  else
    -- blue defends cyan goal
    return {postCyan[1][1], 0, 0};
  end
end

function post_coach(v1,v2,goalType)
  local v_x,v_y = v1[1],v1[2]
  if goalType==3 then
    v_x = (v1[1]+v2[1])/2
    v_y = (v1[2]+v2[2])/2
  end
  v_r = math.sqrt(v_x*v_x + v_y*v_y)

  if v_r<4.0 then
    if v_y<0 then 
      gcm.set_coach_side(
        gcm.get_coach_side()-1)
    elseif v_y>0 then
      gcm.set_coach_side(
        gcm.get_coach_side()+1)
    end
  end
--  print("Coach:",gcm.get_coach_side(),v_r)

  if math.abs(gcm.get_coach_side())>10 then
    print("COACH POSITION CONFIRMED")
    gcm.set_coach_confirm(1)
    local half = gcm.get_game_half()    
    local goalDefend=get_goal_defend();
    if half==0 then
      if gcm.get_coach_side()>0 then --we're on the left desk
        print("COACH ON RIGHT SIDE OF OUR GOAL")
        PoseFilter.initialize(vector.new({goalDefend[1]/2, Config.world.yMax*1.05, -math.pi/2}),{0,0,0})
      else
        print("COACH ON LEFT SIDE OF OUR GOAL")
        PoseFilter.initialize(vector.new({goalDefend[1]/2, -Config.world.yMax*1.05, math.pi/2}),{0,0,0})
      end
    else
      if gcm.get_coach_side()>0 then --we're on the left desk
        print("COACH ON RIGHT SIDE OF ENEMY GOAL")
        PoseFilter.initialize(vector.new({-goalDefend[1]/2, Config.world.yMax*1.05, -math.pi/2}),{0,0,0})
      else
        print("COACH ON RIGHT SIDE OF ENEMY GOAL")
        PoseFilter.initialize(vector.new({-goalDefend[1]/2, -Config.world.yMax*1.05, math.pi/2}),{0,0,0})
      end
    end
  end

--4 possible coach poses
--  vector.new({goalDefend[1]/2, -Config.world.yMax*1.05,  math.pi/2})
--  vector.new({goalDefend[1]/2,  Config.world.yMax*1.05, -math.pi/2}))      
--  vector.new({goalDefend[1]/2, -Config.world.yMax*1.05,  math.pi/2})
--  vector.new({goalDefend[1]/2,  Config.world.yMax*1.05, -math.pi/2}))        

end

function post_unified_unknown(v)
  landmark_observation(postUnified, v[1], rPostFilter, aPostFilter);
end

function post_unified_left(v)
  landmark_observation(postLeft, v[1], rPostFilter2, aPostFilter2);
end

function post_unified_right(v)
  landmark_observation(postRight, v[1], rPostFilter2, aPostFilter2);
end

function goal_unified(v)
  goal_observation_unified(postCyan,postYellow, v);
end

function corner(v,a)
  if(gcm.get_team_role() == 0) then
    landmark_observation(Lgoalie_corner,v,rCornerFilter,aCornerFilter);
  else
    landmark_observation(Lcorner,v,rCornerFilter,aCornerFilter);
  end
end


function line(v, a)

---Updates weights of particles according to the detection of a line
--@param v x and y coordinates of center of line relative to robot
--@param a angle of line relative to angle of robot
  -- line center
  x = v[1];
  y = v[2];
  r = math.sqrt(x^2 + y^2);

  w0 = .25 / (1 + r/2.0);

  for ip = 1,n do
    -- pre-compute sin/cos of orientations
    ca = math.cos(ap[ip]);
    sa = math.sin(ap[ip]);

    -- compute line weight
    -- Line orientation should be close to 0, +/-pi/2, +/-pi
    -- local wLine = w0 * (math.cos(4*(ap[ip] + a)) - 1);  -- need a math.abs
    -- wp[ip] = wp[ip] + wLine;

    local wLine = w0*math.abs(math.sin(2*(ap[ip] + a)))
    wp[ip] = wp[ip] - wLine;

    local xGlobal = v[1]*ca - v[2]*sa + xp[ip];
    local yGlobal = v[1]*sa + v[2]*ca + yp[ip];

    wBounds = math.max(xGlobal - xLineBoundary, 0) + 
              math.max(-xGlobal - xLineBoundary, 0) + 
              math.max(yGlobal - yLineBoundary, 0) +
              math.max(-yGlobal - yLineBoundary, 0);
    wp[ip] = wp[ip] - (wBounds/.20);
  end
end

---Updates particles according to the movement of the robot.
--Moves each particle the distance that the robot has moved
--since the last update.
--@param dx distance moved in x direction since last update
--@param dy distance moved in y direction since last update
--@param da angle turned since last update
function odometry(dx, dy, da)
  for ip = 1,n do
    ca = math.cos(ap[ip]);
    sa = math.sin(ap[ip]);
    xp[ip] = xp[ip] + dx*ca - dy*sa;
    yp[ip] = yp[ip] + dx*sa + dy*ca;
    ap[ip] = ap[ip] + da;
  end
end

---Set all particles to x,y,a=0,0,0.
--This function does not update the weights
function zero_pose()
  xp = vector.zeros(n);
  yp = vector.zeros(n);
  ap = vector.zeros(n);
end

---Return the largest value of a table and it's index
--@param t table of values
--@return largest value and it's index
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

---Adds noise to particle x,y coordinates and angle.
function add_noise()
  da = daNoise;
  dr = drNoise;
  xp = xp + dr * vector.new(util.randn(n));
  yp = yp + dr * vector.new(util.randn(n));
  ap = ap + da * vector.new(util.randn(n));
end

---Resample particles.
--If enough particles have low enough weights, then
--replaces low-weighted particles with new random particles
--and new particles that are nearby high-weighted particles
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



function spot(v)
  landmark_observation(spotWhite, v, 0.03, 0.06);
end




