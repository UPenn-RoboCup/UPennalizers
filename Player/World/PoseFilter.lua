module(..., package.seeall);

require('Config');
require('vector');
require('vcm');
require('gcm');
require('util');
require('Body');

--for logging
local log = require 'log';
if Config.log.enableLogFiles then
    --log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;
log_pos_thresh = 0.1;
log_angle_thresh = 10*math.pi/180;


--load config parameters
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
Tcorner = Config.world.Tcorner;
Tgoalie_corner = Config.world.Tgoalie_corner;
circlePos = Config.world.circle;

--Triangulation method selection
use_new_goalposts= Config.world.use_new_goalposts or 0;
if Config.game.playerID > 1 then
  triangulation_threshold=Config.world.triangulation_threshold or 4.0;
  position_update_threshold = Config.world.position_update_threshold or 6.0;
  goal_angle_update_threshold = Config.world.angle_update_threshold or 3;
else
  -- smaller threshold for the goalie
  triangulation_threshold=Config.world.triangulation_threshold_goalie or 3.0;
  position_update_threshold = Config.world.position_update_threshold_goalie or 3.0;
  goal_angle_update_threshold = Config.world.angle_update_threshold_goalie or math.huge;
end

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
rLCornerFilter = Config.world.rLCornerFilter or 0.01;
aLCornerFilter = Config.world.aLCornerFilter or 0.03;
rTCornerFilter = Config.world.rTCornerFilter or 0.01;
aTCornerFilter = Config.world.aTCornerFilter or 0.03;
rSpotFilter = Config.world.rSpotFilter or 0.03;
aSpotFilter = Config.world.aSpotFilter or 0.06;
aCircleFilter = Config.world.aCircleFilter or 0.02;
rCircleFilter = Config.world.rCircleFilter or 0.01;
--wLineFilter = Config.world.wLineFilter 
--wLineBounds = Config.world.wLineBounds 
rLineFilterTop = Config.world.rLineFilterTop;
aLineFilterTop = Config.world.aLineFilterTop;
rLineFilterBtm = Config.world.rLineFilterBtm;
aLineFilterBtm = Config.world.aLineFilterBtm;

--Sigma values for one landmark observation
rSigmaSingle1 = Config.world.rSigmaSingle1 or .15;
rSigmaSingle2 = Config.world.rSigmaSingle2 or .10;
aSigmaSingle = Config.world.aSigmaSingle or 50*math.pi/180;

--Sigma values for goal observation
rSigmaDouble1 = Config.world.rSigmaSingle1 or .25;
rSigmaDouble2 = Config.world.rSigmaSingle2 or .20;
aSigmaDouble = Config.world.aSigmaSingle or 50*math.pi/180;

--noise parameters for odometry
daNoise = Config.world.daNoise or 2.0*math.pi/180.0;
drNoise = Config.world.drNoise or 0.01;

--allocate particles
xp = .5*xMax*vector.new(util.randn(n)); -- x coordinate of each particle
yp = .5*yMax*vector.new(util.randn(n)); -- y coordinate
ap = 2*math.pi*vector.new(util.randu(n)); -- angle
wp = vector.zeros(n); -- weight
yawErr = 2*math.pi*vector.new(util.randu(n)); --offset from internal yaw value


---Initializes a gaussian distribution of particles centered at p0
--@param p0 center of distribution
--@param dp scales how wide the distrubution is
function initialize(p0, dp)
  p0 = p0 or {0, 0, 0};
  dp = dp or {.5*xMax, .5*yMax, 2*math.pi};

  xp = p0[1]*vector.ones(n) + dp[1]*(vector.new(util.randu(n))-0.5*vector.ones(n));
  yp = p0[2]*vector.ones(n) + dp[2]*(vector.new(util.randu(n))-0.5*vector.ones(n));
  ap = p0[3]*vector.ones(n) + dp[3]*(vector.new(util.randu(n))-0.5*vector.ones(n));

  curYaw = -Body.get_sensor_imuAngle(3);
  for i=1,n do
  	yawErr[i] = ap[i] - curYaw;
  end
  wp = vector.zeros(n);
  
  --log.info("Particles Initialized")
  
end

--Initialze for manual placement (not used currently)
--@param p0 center of distribution
--@param dp scales how wide the distrubution is
function initialize_manual_placement(p0, dp)
  p0 = p0 or {0, 0, 0};
  dp = dp or {.5*xLineBoundary, .5*yLineBoundary, 2*math.pi};

  log.info('re-init partcles for manual placement');
  xp = wcm.get_goal_defend()[1]/2*vector.ones(n);
  yp = p0[2]*vector.ones(n) + dp[2]*(vector.new(util.randn(n))-0.5*vector.ones(n));
  wp = vector.zeros(n);
  curYaw = -Body.get_sensor_imuAngle(3);
  yawErr = (math.atan2(wcm.get_goal_attack()[2],wcm.get_goal_attack()[1])-curYaw)*vector.ones(n);
  ap = update_angles();
end


--Initializes particles to two locations with different variances
--@param p1: mode 1 {x, y, a}
--@param dp1: variance 1 {dx, dy, da}
--@param p2: mode 2 {x, y, a}
--@param dp2: variance 2 {dx, dy, da}
--@param frac: fraction of particles to initialze to mode 1 (0-1)
--@param dir: direction of goal +1 or -1
function initializeBimodal(p1,dp1,p2,dp2,frac,dir)

	--need to shift angle by pi if facing the positive direction
	if dir > 0 then 
		modAng = math.pi;
	else
		modAng = 0;
	end

	--initialize all partices
	for i= 1,n do
		
		--change which mode we are using based on fraction
		if i/n < frac then
			xp[i] = dir*(p1[1]+dp1[1]*(math.random()-0.5));
			yp[i] = dir*(p1[2]+dp1[2]*(math.random()-0.5));
			ap[i] = mod_angle(p1[3]+dp1[3]*(math.random()-0.5) + modAng);
		else
			xp[i] = dir*(p2[1]+dp2[1]*(math.random()-0.5));
			yp[i] = dir*(p2[2]+dp2[2]*(math.random()-0.5));
			ap[i] = mod_angle(p2[3]+dp2[3]*(math.random()-0.5) + modAng);
		end
	end
	
	--calculate yawErr based on desired angle and current yaw reading
	curYaw = -Body.get_sensor_imuAngle(3);
	for i=1,n do
		yawErr[i] = ap[i] - curYaw;
	end
	wp = vector.zeros(n);
	
	log.info("Bi-Modal initialization")
	
end


--initalize to the side of the field where we are penalized
--@param dp: the spread of the particles {dx, dy, da}
function initialize_unPennalized(dp)

	log.info("Re-initializing from penalty")	
	
	--read current yaw value and estimate angles
	apTmp = update_angles()
	
	local side1 = 0; --positive y side
	local side2 = 0; --negative y side
	local goalDefend=wcm.get_goal_defend();
   	local dir = goalDefend[1]/math.abs(goalDefend[1]);
	
	--count up votes for which direction we are facing
	for i=1,n do
		if apTmp[i] > 0 then
			side1 = side1+1;
		else
			side2 = side2+1;
		end
	end 

	--figure out which side we are on
	if side1>side2 then
		--we are facing positive y side (but on negative sideline when unpenalized)
		p = {3*goalDefend[1]/4,-Config.world.yLineBoundary,math.pi/2};
		log.debug("Returning from left side")
	else
		--we are facing negative y side (but on positive sideline when unpenalized)
		p = {3*goalDefend[1]/4,Config.world.yLineBoundary,-math.pi/2};
		log.debug("Returning from right side")
	end

	--now initialize with correct parameters
	initialize(p,dp);
end

--Initialize to both sides of the field if we don't know which side we are entering from
--@param p0: particle center 1 {x, y, a}
--@param p1: particle center 2 {x, y, a}
--@param dp: variance {dx, dy, da}
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
  dp = dp or {.1*xMax, .1*yMax, math.pi/8};

  curYaw = -Body.get_sensor_imuAngle(3);

  for i=1,n/2 do        
    
    local normalRand = util.randn2()
    xp[i]=p0[1]+dp[1]*normalRand[1]; 
    yp[i]=p0[2]+dp[2]*normalRand[2];
    yawErr[i] = (p0[3]+dp[3]*(math.random()-.5)-curYaw);
    
    normalRand = util.randn2()
    xp[i+n/2]=p1[1]+dp[1]*normalRand[1];
    yp[i+n/2]=p1[2]+dp[2]*normalRand[2];    
    yawErr[i+n/2] = (p1[3]+dp[3]*(math.random()-.5)-curYaw);
  end
  wp = vector.zeros(n);
  ap = update_angles();
end

--Particle initialization at bodySet 
--When bodySet, all players should face opponents' goal
--So reduce weight of  particles that faces our goal
function initialize_heading(aGoal)  
  log.info('init_heading particles');
  dp = dp or {.15*xMax, .15*yMax, math.pi/6};
  curYaw = -Body.get_sensor_imuAngle(3);
  yawErr = (aGoal-curYaw)*vector.ones(n) + dp[3]*vector.new(util.randu(n));
  ap = update_angles();
  wp = vector.zeros(n);
end

--Flip particle direction when the robot is confused
--We shouldn't ever need this anymore since we are using the gyro
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
--  local wmax, imax = max(wp);
  ap = update_angles();
--  curYaw = -Body.get_sensor_imuAngle(3);
--  print('Max ap:',mod_angle(ap[imax])*180/math.pi)
--  print('Max yawErr:',mod_angle(yawErr[imax])*180/math.pi)
--  print('cur Yaw:', mod_angle(curYaw)*180/math.pi)
--  return xp[imax], yp[imax], mod_angle(ap[imax]);

--weighted average of particles reduces jumping of position
--as opposed to simply picking best one
--In future we should maybe consider doing a weighted average
--over clusters
return weighted_average()

end

--updates ap vector to be consistent with gyro
function update_angles()
  curYaw = -Body.get_sensor_imuAngle(3);
  new_ap = vector.zeros(n)
  for i = 1,n do
     new_ap[i] = mod_angle(curYaw + yawErr[i]);
  end
  return new_ap
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
function landmark_observation(pos, v, rLandmarkFilter, aLandmarkFilter, angle_threshold, dont_update_position)

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
  end
  --Filter toward best matching landmark position:
  for ip = 1,n do
    if not (dont_update_position==1) and r<position_update_threshold then
      --print(type(xp), type(dxp), type(ap))
      xp[ip] = xp[ip] + rFilter * (dxp[ip] - r * math.cos(ap[ip] + a));
      yp[ip] = yp[ip] + rFilter * (dyp[ip] - r * math.sin(ap[ip] + a));
    end
    if r > angle_threshold then
      yawErr[ip] = yawErr[ip] + aFilter * dap[ip];
    end
    -- check boundary
    xp[ip] = math.min(xMax, math.max(-xMax, xp[ip]));
    yp[ip] = math.min(yMax, math.max(-yMax, yp[ip]));
  end
  ap = update_angles();
  
end



---Update particles according to a goal detection
--@param pos All possible positions of the goals
--For example, each post location is an entry in pos
--@param v x and y coordinates of detected goal relative to robot
--function goal_observation(pos, v)
---------------------------------------------------------------------------
-- Now we have two ambiguous goals to check
-- So we separate the triangulation part and the update part
------------------------------------------------------------
---------------

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


--new triangulation for same colored goals
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
  -- postfix=0;

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


--Update particles according to an object with orientation.
--i.e. corners, center line, spot and line 
--@param pos All possible positions of the objects
--For example, each corner location is an entry in pos
--@param v x and y coordinates of detected object relative to robot
--@param a the relative orientation of the object (observed by robot)

function oriented_object_observation(pos,v,angle,rLandmarkFilter,aLandmarkFilter)
  local poses = {}; -- possible positions of the robot
  local r = math.sqrt(v[1]^2+v[2]^2);
  local arel = math.atan2(v[2],v[1]);
  local myPosX,myPosY,myPosA = get_pose(); --current pose of robot
  local posexya = {myPosX,myPosY,myPosA};
  
  local lowest_error = {};
  local dX = {};
  local dY = {};
  local dA = {};
  local best_feature = {};
  
  for i=1,#pos do
    poses[i] = {};
    local xpos = pos[i][1];
    local ypos = pos[i][2];
    local apos = pos[i][3];
    poses[i].a = mod_angle(apos - angle);
    local aObj = poses[i].a + arel;
    local xrel = r*math.cos(aObj);
    local yrel = r*math.sin(aObj);
    
    local poseRel = util.pose_relative(pos[i],posexya)
    local objAng = math.atan2(poseRel[2],poseRel[1]);
    if math.abs(objAng) < math.pi/2 then inFront = 1; else inFront = 0; end -- is object in front or behind
    poses[i].x = xpos - xrel;
    poses[i].y = ypos - yrel;
    poses[i].front = inFront;
    
    --[[if i == chkObj then
        print('In front:',inFront)
        print('PoseRel:',unpack(poseRel));
    end]]--
    
  end
  
  local rSigma = rSigmaSingle1 * r + rSigmaSingle2;
  local aSigma = aSigmaSingle;
  local rFilter = rLandmarkFilter or 0.02;
  local aFilter = aLandmarkFilter or 0.04;
  local dirPenalty = 100;

  for ip = 1,n do
    local xErr = {};
    local yErr = {};
    local aErr = {};
    local err = {};
    for i=1,#pos do 
      xErr[i] = poses[i].x - xp[ip];
      yErr[i] = poses[i].y - yp[ip];
      aErr[i] = mod_angle(poses[i].a - ap[ip]);
      local rErr = math.sqrt(xErr[i]^2+yErr[i]^2)
      err[i] = (rErr/rSigma)^2 + (aErr[i]/aSigma)^2 + dirPenalty*(1-poses[i].front);
      
     --[[if ip == chkparticle and i == chkObj then
            print('Dir penalty:', dirPenalty*(1-poses[i].front))
            print('Err:', err[i]);
      end]]--
      
    end
    errmin, imin = min(err); 
    wp[ip] = wp[ip] - errmin;
    xp[ip] = xp[ip] + rFilter*xErr[imin];
    yp[ip] = yp[ip] + rFilter*yErr[imin]; 
    yawErr[ip] = yawErr[ip] + aFilter*aErr[imin];
    
    --for debug printing
    best_feature[ip] = imin;
    lowest_error[ip] = errmin
    dX[ip] = rFilter*xErr[imin];
    dY[ip] = rFilter*yErr[imin];
    dA[ip] = aFilter*aErr[imin]; 
    
  end
  ap = update_angles(); 
  
  --extract data for printing
  most_common_feature,num_entries,frac = mode(best_feature);
  avg_err = mean(lowest_error);
  avg_dX = mean(dX);
  avg_dY = mean(dY);
  avg_dA = mean(dA);
  
  --take log
  if math.abs(avg_dX) > log_pos_thresh or math.abs(avg_dY) > log_pos_thresh or math.abs(avg_dA) > log_angle_thresh then 
      log.warn('Large average particle change')
      log.warn("Most common feature: ",most_common_feature)
      log.warn("Feature fraction: ",frac)
      log.warn("Average error: ",avg_err)
      log.warn("Average dX: ",avg_dX)
      log.warn("Average dY: ",avg_dY)
      log.warn("Average dA: ",avg_dA)
  else
      log.trace("Most common feature: ",most_common_feature)
      log.trace("Feature fraction: ",frac)
      log.trace("Average error: ",avg_err)
      log.trace("Average dX: ",avg_dX)
      log.trace("Average dY: ",avg_dY)
      log.trace("Average dA: ",avg_dA)
  end
    
end
  

--Update particles based on detected circle position.
--@param v x and y coordinates of detected object relative to robot
--@param a the relative orientation of the object (observed by robot)
--@param rCircleFilter: how much to adjust the position based on circle observation
--@param aCircleFilter: how much to adjust the angle based on circle observation
function oriented_circle(v, a,rCircleFilter,aCircleFilter)
  
  local lowest_error = {};
  local dX = {};
  local dY = {};
  local dA = {} 
  
  --we know circle is at (0,0)
  local poses = {}; -- possible positions of the robot
  local r = math.sqrt(v[1]^2+v[2]^2);
  local arel = math.atan2(v[2],v[1]);
  --case 1:
  poses[1] = {};
  local ra1 = mod_angle(-math.pi/2-a-arel);
  poses[1].a = mod_angle(math.pi/2-a);
  poses[1].x = r*math.cos(ra1);
  poses[1].y = r*math.sin(ra1);
  
  --case 2:
  poses[2] = {};
  local ra2 = mod_angle(math.pi/2-a-arel);
  poses[2].a = mod_angle(-math.pi/2-a);
  poses[2].x = r*math.cos(ra2);
  poses[2].y = r*math.sin(ra2);
  
  local rSigma = rSigmaSingle1 * r + rSigmaSingle2;
  local aSigma = aSigmaSingle;
  local rFilter = rCircleFilter;
  local aFilter = aCircleFilter;
  --update particles
  for ip = 1,n do
    local xErr = {};
    local yErr = {};
    local aErr = {};
    local err = {};
    for i=1,2 do 
      xErr[i] = poses[i].x - xp[ip];
      yErr[i] = poses[i].y - yp[ip];
      aErr[i] = mod_angle(poses[i].a - ap[ip]);
      local rErr = math.sqrt(xErr[i]^2+yErr[i]^2)
      err[i] = (rErr/rSigma)^2 + (aErr[i]/aSigma)^2;
    end
    errmin, imin = min(err); 
    --print('imin:' .. imin);
    wp[ip] = wp[ip] - errmin;
    xp[ip] = xp[ip] + rFilter*xErr[imin];
    yp[ip] = yp[ip] + rFilter*yErr[imin];
   
    yawErr[ip] = yawErr[ip] + aFilter*aErr[imin];
    
    --for debugging
    lowest_error[ip] = errmin
    dX[ip] = rFilter*xErr[imin];
    dY[ip] = rFilter*yErr[imin];
    dA[ip] = aFilter*aErr[imin];
    
  end
  ap = update_angles();
  
  --extract data for printing
  avg_err = mean(lowest_error);
  avg_dX = mean(dX);
  avg_dY = mean(dY);
  avg_dA = mean(dA);
  
  --take log
  if math.abs(avg_dX) > log_pos_thresh or math.abs(avg_dY) >log_pos_thresh or math.abs(avg_dA) > log_angle_thresh then 
      log.warn('Large average particle change')
      log.warn("Average error: ",avg_err)
      log.warn("Average dX: ",avg_dX)
      log.warn("Average dY: ",avg_dY)
      log.warn("Average dA: ",avg_dA)
  else
      log.trace("Average error: ",avg_err)
      log.trace("Average dX: ",avg_dX)
      log.trace("Average dY: ",avg_dY)
      log.trace("Average dA: ",avg_dA)
  end
  
end

--Adjust particles based on observing both goalposts
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
        yawErr[ip] = yawErr[ip] + aFilter*aErr2;
      else
        wp[ip] = wp[ip] - err1;
        xp[ip] = xp[ip] + rFilter*xErr1;
        yp[ip] = yp[ip] + rFilter*yErr1;
        yawErr[ip] = yawErr[ip] + aFilter*aErr1;
      end
    end
  elseif dGoal<position_update_threshold then
    -- print("dGoal in mid-range\n")
    
    --Goal midrange, use a point update
    --Goal too far, use a point estimate
    goalpos1={(pos1[1][1]+pos1[2][1])/2, (pos1[1][2]+pos1[2][2])/2}
    goalpos2={(pos2[1][1]+pos2[2][1])/2, (pos2[1][2]+pos2[2][2])/2}
    goalv={(v[1][1]+v[2][1])/2, (v[1][2]+v[2][2])/2}
    landmark_observation({goalpos1,goalpos2},goalv, 
      rUnknownPostFilter, aUnknownGoalFilter,
      goal_angle_update_threshold);
  else --Goal VERY far, just update angle only
    -- print("dGoal farther than position update thres\n")

    goalpos1={(pos1[1][1]+pos1[2][1])/2, (pos1[1][2]+pos1[2][2])/2}
    goalpos2={(pos2[1][1]+pos2[2][1])/2, (pos2[1][2]+pos2[2][2])/2}
    goalv={(v[1][1]+v[2][1])/2, (v[1][2]+v[2][2])/2}
    landmark_observation({goalpos1,goalpos2},goalv, 
      rUnknownGoalFilter, aUnknownGoalFilter,
      goal_angle_update_threshold,1);
  end
  ap = update_angles();
end

--Returns location of goal we are defending
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

--Adjust particles based on post observation if we don't know which side of the goal it is on
function post_unified_unknown(v)
  if (rPostFilter>0 and aPostFilter>0) then
       landmark_observation(postUnified, v[1], 
          rPostFilter, aPostFilter,goal_angle_update_threshold);
  end
end

--Adjust particles based on observation of the left goal post
function post_unified_left(v)
  if (rPostFilter2>0 and aPostFilter2>0) then
       landmark_observation(postLeft, v[1], 
          rPostFilter2, aPostFilter2, goal_angle_update_threshold);
   end
end

--Adjust particles based on observation of the right goal post
function post_unified_right(v)
  if (rPostFilter2>0 and aPostFilter2>0) then
      landmark_observation(postRight, v[1], 
        rPostFilter2, aPostFilter2, goal_angle_update_threshold); 
  end
end

--Adjust particles based on observation of both goalposts
function goal_unified(v)
  if (rGoalFilter>0 and aGoalFilter>0) then
        goal_observation_unified(postCyan,postYellow, v);
    log.info('Goal Update');
  end
end


--Adjust particles based on observation of a L corner
function cornerL(v,a)
  if (rLCornerFilter>0 and aLCornerFilter>0) then
      log.info('L Corner Update')
	  if(Config.game.playerID == 1) then
	    oriented_object_observation(Lgoalie_corner,v,a,rLCornerFilter,aLCornerFilter);
	  else
	    oriented_object_observation(Lcorner,v,a,rLCornerFilter,aLCornerFilter);
	  end
   end
end


--Adjust particles based on observation of a T corner
function cornerT(v,a)
  if (rTCornerFilter>0 and aTCornerFilter>0) then
      log.info('T Corner Update')
	  if(Config.game.playerID == 1) then
	    oriented_object_observation(Tgoalie_corner,v,a,rTCornerFilter,aTCornerFilter);
	  else
	    oriented_object_observation(Tcorner,v,a,rTCornerFilter,aTCornerFilter);
	  end
   end
end

--update angle and position perpedicular to line (as opposed to just particle weights)
--@param v The x and y position of the center of the line
--@param a The angle of the line with respect to the robot
function line3(v,a,rFilter,aFilter)

    local lowest_error1 = {};
    local lowest_error2 = {};
    local dX = {};
    local dY = {};
    local dA = {};

    --distance to line
    x = v[1]; --forwards
    y = v[2]; -- +right, -left
    --angle is 0->pi with angle always counterclockwise from player to line

    --find perpedicular distance to line
    perpDist = x*math.sin(a);   
    local lineAng = (math.pi/2-a); -- adjust angle slightly to make errors work better
    
    --set filter weights 
    local rSigma = rSigmaSingle1 * perpDist + rSigmaSingle2;
    local aSigma = aSigmaSingle;   
    
    
    --all possible lines - ignore sides of penalty box
    possibleLines = {Config.world.Lcorner[1][1],  --Our endline
                     Config.world.Lcorner[3][1],  --Opponents endline
                     Config.world.Lcorner[5][1],  --Our penalty box
                     Config.world.Lcorner[7][1],  --opponents penalty box
                     Config.world.Lcorner[17][1], --center line
                     Config.world.Lcorner[1][2],  --Left sideline
                     Config.world.Lcorner[2][2]}; --Right sideline
    
    --consider all 4 orientations
    possibleAngles = {mod_angle(lineAng), 
                      mod_angle(lineAng+math.pi/2),
                      mod_angle(lineAng+math.pi),
                      mod_angle(lineAng+3*math.pi/2)};
    
    --update particles
    for ip = 1,n do
        local aErrSigned = {};
        local aErr = {};
       
        --find angle error for each direction
        for i=1,4 do
            aErr[i] = math.abs(ap[ip] - possibleAngles[i]);  
            aErrSigned[i] = ap[ip] - possibleAngles[i];          
        end  -- + turn right, - turn left
        
        --find most likely angle and update yaw error
        errmin, imin = min(aErr)
        yawErr[ip] = yawErr[ip] - aFilter*aErrSigned[imin];
        wp[ip] = wp[ip] - errmin;
        
        lowest_error1[ip] = errmin
        dA[ip] = -aFilter*aErrSigned[imin];        
        
        --Now that angles are updated, we can do distance to line
        --Need to figure out which line we are looking at, we can use angle we updated to 
        --narrow down search - then use perpDist to line for small position change
        if rFilter >= 0.01 then

            --initialize
			xErr = {};
			yErr = {};
			err = {};
			
			--need to adjust angle for finding which line we are looking at	
			lineDir = mod_angle(possibleAngles[imin]-lineAng); 
				
            for i=1,7 do
                --if we are facing the left sideline
                if lineDir >=  math.pi/4 and 
                   lineDir < 3*math.pi/4 then
                   if i == 6 or i == 7 then --vertical line
                        xErr[i] = 0;
                        yErr[i] = (possibleLines[i]-perpDist)-yp[ip];
                   else -- horizontal line
                        xErr[i] = math.huge;
                        yErr[i] = math.huge;
                   end
                --if we are facing forwards
                elseif lineDir >= -math.pi/4 and 
                       lineDir  <  math.pi/4 then
                  if i == 6 or i == 7 then --vertical line
                        xErr[i] = math.huge;
                        yErr[i] = math.huge;
                   else -- horizontal line
                        xErr[i] = (possibleLines[i]-perpDist)-xp[ip];
                        yErr[i] = 0;
                   end
                --if we are facing right sideline
                elseif lineDir >= -3*math.pi/4 and 
                       lineDir  <  math.pi/4 then
                    if i == 6 or i == 7 then --vertical line
                        xErr[i] = 0;
                        yErr[i] = (possibleLines[i]+perpDist)-yp[ip];
                   else -- horizontal line
                        xErr[i] = math.huge;
                        yErr[i] = math.huge;
                   end
                --if we are facing backwards
                else
                   if i == 6 or i == 7 then --vertical line
                        xErr[i] = math.huge;
                        yErr[i] = math.huge;
                   else -- horizontal line
                        xErr[i] = (possibleLines[i]+perpDist)-xp[ip];
                        yErr[i] = 0;
                   end 
                end --end if direction
                
                --either xErr or yErr will always be 0
                err[i] = (math.sqrt(xErr[i]^2+yErr[i]^2)/rSigma)^2;
                
             end --end for all lines
             
            --pick lowest error and update
            --either xErr or yErr will always be 0
            errmin, imin = min(err); 
            wp[ip] = wp[ip] - errmin;
            xp[ip] = xp[ip] + rFilter*xErr[imin];
            yp[ip] = yp[ip] + rFilter*yErr[imin];
            
            --for debugging
            lowest_error2[ip] = errmin
            dX[ip] = rFilter*xErr[imin];
            dY[ip] = rFilter*yErr[imin];
            
        end --end if rFilter >= 0.01   
           
    end --end for all particles
    
    --make sure angles get updated too
    ap = update_angles(); 
    
    --extract data for printing
      avg_err1 = mean(lowest_error1)
      avg_err2 = mean(lowest_error2)
      avg_dX = mean(dX);
      avg_dY = mean(dY);
      avg_dA = mean(dA);
      
      --take log
      if math.abs(avg_dX) > log_pos_thresh or math.abs(avg_dY) > log_pos_thresh or math.abs(avg_dA) > log_angle_thresh then 
          log.warn('Large average particle change')
          log.warn("Average error (angle): ",avg_err1)
          log.warn("Average dA: ",avg_dA)
          log.warn("Average error (xy): ",avg_err2)
          log.warn("Average dX: ",avg_dX)
          log.warn("Average dY: ",avg_dY)
     else
          log.trace("Average error (angle): ",avg_err1)
          log.trace("Average dA: ",avg_dA)
          log.trace("Average error (xy): ",avg_err2)
          log.trace("Average dX: ",avg_dX)
          log.trace("Average dY: ",avg_dY)
     end
      
     
end -- end function line3



--update particles based on top line
function topLineUpdate(v,a)   
    if rLineFilterTop > 0 and aLineFilterTop > 0 then
        line3(v,a,rLineFilterTop,aLineFilterTop);
        log.info('top line update')
    end    
end    

--update particles based on bottom line
function btmLineUpdate(v,a)   
    if rLineFilterBtm > 0 and aLineFilterBtm > 0 then
        line3(v,a,rLineFilterBtm,aLineFilterBtm);
        log.info('Btm Line Update')
    end    
end


---Updates particles according to the movement of the robot.
--Moves each particle the distance that the robot has moved
--since the last update./
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
  yawErr = vector.zeros(n);
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


---Return the smallest value of a table and it's index
--@param t table of values
--@return smallest value and it's index
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

--returns mean of a table
function mean(t)
    local sum = 0;
    for i = 1,#t do
        sum = sum + t[i];
    end
    avg = sum/#t;
    return avg
end

--returns mode of a table
--Also gives number of occurrences and fraction of entries that it was
function mode(t)
    local num_distinct = 0
    local num_occurred=vector.zeros(#t)
    local values=vector.zeros(#t)
    for i=1,#t do
        cur_num = t[i];
        match,idx = match_any(cur_num,values)
        if match then
            num_occurred[idx] = num_occurred[idx] + 1;
        else
            num_distinct = num_distinct + 1;
            values[num_distinct] = cur_num;
        end
    end
    
    max_num,max_idx = max(num_occurred);
    max_val = values[max_idx];
    mode_frac = max_num/#t;
    
    return max_val,max_num,mode_frac
    
end


-- check if number n matches any values in function t
--will return true/false and index/-1
function match_any(n,t)
    for i=1,#t do
        if n == t[i] then
            return true, i
        end
    end
    return false, -1
end


--Returns sign of a scalar value
function sign(x)
  if (x > 0) then
    return 1;
  elseif (x < 0) then
    return -1;
  else
    return 0;
  end
end


--Adjust angle to keep it within -pi<=a<=+pi
function mod_angle(a)
  a = a % (2*math.pi);
  if (a >= math.pi) then
    a = a - 2*math.pi;
  end
  return a;
end

---Adds noise to particle x,y coordinates and angle.
function add_noise()
  da = daNoise;
  dr = drNoise;
  xp = xp + dr * vector.new(util.randn(n));
  yp = yp + dr * vector.new(util.randn(n));
  ap = ap + da * vector.new(util.randn(n));
  yawErr = yawErr + da * vector.new(util.randn(n));
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
  yawErr2 = vector.zeros(n);
  nsampleSum = 1;
  
  ni = 1;
  for i = 1,2*n do
    oi = wSum[i][2];
    if oi > n then
      xp2[ni] = xp[nsampleSum];
      yp2[ni] = yp[nsampleSum];
      ap2[ni] = ap[nsampleSum];
      yawErr2[ni] = yawErr[nsampleSum];
      ni = ni + 1;
    else
      nsampleSum = nsampleSum + 1;
    end
  end

  -- always put max particle
  xp2[1] = xp[iMax];
  yp2[1] = yp[iMax];
  yawErr2[1] = yawErr[iMax];

  xp = xp2;
  yp = yp2;
  yawErr = yawErr2;
  ap = update_angles();
  wp = vector.zeros(n);
  
  log.debug("Particles resampled")
end


--Adjust particles based on observation of the spot
function spot(v)
  if (rSpotFilter>0 and aSpotFilter>0) then
     log.info('Spot Update')
     landmark_observation(spotWhite, v, rSpotFilter, aSpotFilter, 0);
  end
end

--Adjust particles based on observation of the circle
function circle(v,a)   
   if (rCircleFilter>0 and aCircleFilter>0) then
      log.info('Circle Update')
      oriented_circle(v,a,rCircleFilter,aCircleFilter); 
   end
end

--Debugging function that will print out min, max, and avg of particle weights
function print_weights()
    local wavg=0;
    local wmax;
    local wmin;
    for i = 1,n do
       wavg = wavg + wp[i];
    end
    wavg = wavg/n;
    wmax,ignore = max(wp);
    wmin,ignore = min(wp); 
    log.debug("Weight average:", wavg);
    log.debug("Weight max:", wmax);
    log.debug("Weight min:", wmin);
end

--function to figure out a confidence measure for localization
--will return value between 0 (not confident) and 1 (very confident)
function get_confidence()
	
	wnorm = normalize_weights();

	--calculate weighted mean
	s_wx = 0;
	s_wy = 0;
	sin = 0;
	cos = 0;
	s_w = 0;
	for i = 1,n do
		s_wx = s_wx + wnorm[i]*xp[i];
		s_wy = s_wy + wnorm[i]*yp[i];
		sin = sin + wnorm[i]*math.sin(ap[i]);
		cos = cos + wnorm[i]*math.cos(ap[i]);
		s_w = s_w + wnorm[i];
	end

	if s_w == 0 then --cant divide by 0...
		confidence = 0;
		return confidence
	else
		x_mean = s_wx/s_w;
		y_mean = s_wy/s_w;
		sin_norm = sin/s_w;
		cos_norm = cos/s_w;
	end

	--calculate std deviation
	s_x = 0;
	s_y = 0;
	for i = 1,n do
		s_x = s_x + (xp[i] - x_mean)^2; 
		s_y = s_y + (yp[i] - y_mean)^2;
	end
	x_stddev = math.sqrt(s_x/n);	
	y_stddev = math.sqrt(s_y/n);
	a_stddev = math.sqrt(-math.log(sin_norm^2+cos_norm^2));

	--estimate confidence
	x_conf = 1-(x_stddev/2);
	y_conf = 1-(y_stddev/2);
	a_conf = 1-(a_stddev/math.pi);
	confidence = x_conf*y_conf*a_conf;
	if confidence < 0 then confidence = 0 end
	if confidence > 1 then confidence = 1 end

	--for debugging
	--print("X Confidence:", x_conf);
	--print("Y Confidence:", y_conf);
	--print("A Confidence:", a_conf);
	--print("Total Confidence:", confidence);

	return confidence;
end


--funciton to normalize wights between 0-1 for use in calculting confidence
function normalize_weights()

	wmin, ignore = min(wp);
	wmax, ignore = max(wp);
	range = wmax - wmin;
	wnorm = vector.zeros(n)

	if range == 0 then 
		for i=1,n do
			wnorm[i] = 1;
		end
		return wnorm
	else
		for i=1,n do
			wnorm[i] = (wp[i]-wmin)/range;
		end
	end
	return wnorm
end

--function to find the weighted average of all of the particles
function weighted_average()

	wnorm = normalize_weights();

	s_wx = 0;
	s_wy = 0;
	sin = 0;
	cos = 0;
	s_w = 0;
	for i = 1,n do
		s_wx = s_wx + wnorm[i]*xp[i];
		s_wy = s_wy + wnorm[i]*yp[i];
		sin = sin + wnorm[i]*math.sin(ap[i]);
		cos = cos + wnorm[i]*math.cos(ap[i]);
		s_w = s_w + wnorm[i];
	end

	x_mean = s_wx/s_w;
	y_mean = s_wy/s_w;
	sin_norm = sin/s_w;
	cos_norm = cos/s_w;
	a_mean = math.atan2(sin_norm,cos_norm);

 	return x_mean, y_mean, a_mean;
end
