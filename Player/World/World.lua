module(..., package.seeall);

require('PoseFilter');
require('Filter2D');
require('Body');
require('vector');
require('util');
require('wcm')
require('vcm');
require('gcm');
require('mcm');

local log = require 'log';
if Config.log.enableLogFiles then
    --log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;

-- intialize sound localization if needed
useSoundLocalization = Config.world.enable_sound_localization or 0;
if (useSoundLocalization > 0) then
  require('SoundFilter');
end

--various configuration and setup
mod_angle = util.mod_angle;
goal_led = {0,0,0}
ball_led={1,0,0}
use_kalman_velocity = Config.use_kalman_velocity or 0;
uOdometry0 = vector.new({0, 0, 0});
count = 0;
cResample = Config.world.cResample; 
playerID = Config.game.playerID;
odomScale = Config.world.odomScale;
odomScale2 = Config.world.odomScale2;
wcm.set_robot_odomScale(odomScale);

--for manual placement
lifted1 = 0;
lifted2 = 0;
liftedT = 0;

--Get starting sideline pose
startPose = Config.world.initPositionSidelines[playerID]

if use_kalman_velocity>0 then
  Velocity = require('kVelocity');	
else
  require('Velocity');	
end

--Use ground truth pose and ball information for webots?
use_gps_only = Config.use_gps_only or 0;
gps_enable = Body.gps_enable or 0;

--Use team vision information when we cannot find the ball ourselves
tVisionBall = 0;
use_team_ball = Config.team.use_team_ball or 0;
team_ball_timeout = Config.team.team_ball_timeout or 0;
team_ball_threshold = Config.team.team_ball_threshold or 0;

--For NSL, eye LED is not allowed during match
led_on = 1; --Default is ON

--Initialize ball filter
ballFilter = Filter2D.new();
ball = {};
ball.t = 0;  --Detection time
ball.x = 1.0;
ball.y = 0;
ball.vx = 0;
ball.vy = 0;
ball.p = 0; 

--Initialize pose
pose = {};
pose.x = 0;
pose.y = 0;
pose.a = 0;
pose.tGoal = 0; --Goal detection time

--Track gcm state
gameState = 0;


--Inititalizing particle filter
function init_particles()
  local goalDefend=get_goal_defend();
  local dir = goalDefend[1]/math.abs(goalDefend[1]);

  --Coach
  if gcm.get_team_role() == 5 then 
    half = gcm.get_game_half()    
    if half==0 then --First half, coach our side      
      PoseFilter.initialize_unified(
        vector.new({goalDefend[1]/2, -Config.world.yMax*1.05,  math.pi/2}),
        vector.new({goalDefend[1]/2,  Config.world.yMax*1.05, -math.pi/2}));      
    else --second half, coach on the other side!
      PoseFilter.initialize_unified(
        vector.new({-goalDefend[1]/2, -Config.world.yMax*1.05,  math.pi/2}),
        vector.new({-goalDefend[1]/2,  Config.world.yMax*1.05, -math.pi/2}));        
    end

  --All other players
  else
     --check to see if we are initializing for the ready state or not
     if wcm.get_robot_penalty() == 0 or Config.world.forceSidelinePos == 1 then
	   spread = Config.world.initPositionSidelinesSpread
           startPoseOriented = {dir*startPose[1],dir*startPose[2],dir*startPose[3]};
           PoseFilter.initialize(startPoseOriented,spread);
     else
           --use gyro to determine which direction we are facing and unpenalize from that side
	   PoseFilter.initialize_unPennalized({1.5, 0.1, 10*math.pi/180});
     end
  end
end

--Start World processing
function entry()
  count = 0;
  wcm.set_robot_penalty(0);
    init_particles();
  Velocity.entry();
end

--Initialize particles when the robots are manually placed
function init_particles_manual_placement()
  
  --change direction based on goalDefend
   local goalDefend=get_goal_defend();
   local dir = goalDefend[1]/math.abs(goalDefend[1]);

  -- goalie initialized to different place
  if gcm.get_team_role() == 0 then
  
    pGoalie = Config.world.pGoalie;
    dpGoalie = Config.world.dpGoalie;    
    if goalDefend[1] > 0 then
      PoseFilter.initialize({pGoalie[1],pGoalie[2],math.pi}, dpGoalie);
    else
      PoseFilter.initialize({-pGoalie[1],pGoalie[2],0}, dpGoalie);
    end

  --regular players get initialized on the field
  else

    --If it is our kickoff, one player might be near circle
    if gcm.get_game_kickoff() == 1   then
	    
	    --parameters for bimodal distibution
	    pCircle = Config.world.pCircle;
	    dpCircle = Config.world.dpCircle;
	    pLine = Config.world.pLine;
	    dpLine = Config.world.dpLine;
	    fraction = Config.world.fraction;

	    PoseFilter.initializeBimodal(pLine,dpLine,pCircle,dpCircle,fraction,dir);	    

    --If it isn't our kickoff, then we are on the penalty box line (3.9 m from middle)
    else
	    --parameters for only on line
        pLine = Config.world.pLine;
	    dpLine = Config.world.dpLine;
	    if dir > 0 then 
	      PoseFilter.initialize({pLine[1],pLine[2],math.pi},dpLine);
	    else
	      PoseFilter.initialize({-pLine[1],pLine[2],0},dpLine);
	    end
    end

    if (useSoundLocalization > 0) then
      SoundFilter.reset();
    end
  end
end


--Update filter with how locomotion believes we moved
function update_odometry()

  count = count + 1;
  
  --Get odometry estimate from walk
  uOdometry, uOdometry0 = mcm.get_odometry(uOdometry0);

  --scale odometry estimate (forwards and backwards are different)
  if uOdometry[1] > 0 then
      uOdometry[1] = odomScale[1]*uOdometry[1];
      uOdometry[2] = odomScale[2]*uOdometry[2];
      uOdometry[3] = odomScale[3]*uOdometry[3];
  else
      uOdometry[1] = odomScale2[1]*uOdometry[1];
      uOdometry[2] = odomScale2[2]*uOdometry[2];
      uOdometry[3] = odomScale2[3]*uOdometry[3]; 
  end

  --Update filters with odomoetry data
  ballFilter:odometry(uOdometry[1], uOdometry[2], uOdometry[3]);
  PoseFilter.odometry(uOdometry[1], uOdometry[2], uOdometry[3]);
  if (useSoundLocalization > 0) then
    SoundFilter.odometry(uOdometry[1], uOdometry[2], uOdometry[3]);
    SoundFilter.update();
  end
end

-- update localization without vision (for odometry testing)
function update_pos()  
  if count % cResample == 0 then
    PoseFilter.resample();
  end
  pose.x,pose.y,pose.a = PoseFilter.get_pose();
  update_shm();
end

--Run checks on all vision data for localization filter corrections
function update_vision()

--For using gps stuff
  --update ground truth
  if gps_enable>0 then

    gps_pose0=Body.get_sensor_gps();

    --GPS is attached at torso, so we should discount body offset
    uBodyOffset = mcm.get_walk_bodyOffset();
    gps_pose = util.pose_global(-uBodyOffset,gps_pose0);

    gps_pose_xya={}
    gps_pose_xya.x=gps_pose[1];
    gps_pose_xya.y=gps_pose[2];
    gps_pose_xya.a=gps_pose[3];
    gps_attackBearing = get_attack_bearing_pose(gps_pose_xya);

    wcm.set_robot_gpspose(gps_pose);
    wcm.set_robot_gps_attackbearing(gps_attackBearing);
  else
    gps_pose = {pose.x,pose.y,pose.a};
    wcm.set_robot_gpspose({pose.x,pose.y,pose.a});
    wcm.set_robot_gps_attackbearing(get_attack_bearing());
  end

  --We may use ground truth data only (for behavior testing)
  if use_gps_only>0 then
    --print("WEREINTROUBLE")
    --Use GPS pose instead of using particle filter

    pose.x,pose.y,pose.a=gps_pose[1],gps_pose[2],gps_pose[3];
    --Use GPS ball pose instead of ball filter
    ballGlobal=wcm.get_robot_gps_ball();    
    ballLocal = util.pose_relative(ballGlobal,gps_pose);
    ball.x, ball.y = ballLocal[1],ballLocal[2];
    wcm.set_ball_v_inf({ball.x,ball.y}); --for bodyAnticipate

    ball_gamma = 0.3;
    if vcm.get_ball_detect()==1 then
      ball.t = Body.get_time();
      ball.p = (1-ball_gamma)*ball.p+ball_gamma;
      -- Update the velocity
      Velocity.update(ball.x,ball.y,ball.t);
      ball.vx, ball.vy, dodge  = Velocity.getVelocity();
    else
      ball.p = (1-ball_gamma)*ball.p;
      Velocity.update_noball(Body.get_time());--notify that ball is missing
      ball.vx, ball.vy, dodge  = Velocity.getVelocity();
    end
    if vcm.get_goal_detect()==1 then
      pose.tGoal = Body.get_time()      
    end

    update_shm();
    return;
  end
 
-----------------------
--Actual non-gps stuff

  --add noise while robot is moving
  if count % cResample == 0 and gcm.get_team_role()~=5 then
    PoseFilter.resample();
    if mcm.get_walk_isMoving()>0 then
      PoseFilter.add_noise();
    end
  end

  --Flip particles if a localization flip is detected and not corrected for
  if wcm.get_robot_flipped() == 1 and gcm.get_team_role()~=5 then
    PoseFilter.flip_particles();
    wcm.set_robot_flipped(0);
  end

  --check game state
  gameState = gcm.get_game_state();
  if (gameState == 0) then
    init_particles();
    gcm.set_coach_confirm(0)
    gcm.set_coach_side(0)
  end

  -- Penalized?
  if gcm.in_penalty() then
    wcm.set_robot_penalty(1);
    update_shm();
    if wcm.get_robot_resetOrientation() == 1 then
        print("Resetting Orientation");
        PoseFilter.initialize({0,0,0},{.1,.1,.1});
        wcm.set_robot_resetOrientation(0);
     end
    return 
  elseif gcm.in_penalty() and gcm.get_game_controllerState() == 2 then
      
      if wcm.get_robot_penalty() == 1 then
        wcm.set_robot_penalty(1);  --dont do motion in set penalty if we are already in penalty
        return 
      else
        wcm.set_robot_penalty(-1);  --motion in set penalty
        update_shm();
        return
      end
  else
      if wcm.get_robot_penalty() == 1 then 
         init_particles()
	     wcm.set_robot_penalty(0);
      end
  end

  --For using webots
  webots = Config.webots
  
  --Check for manual initialization
  if (not webots or webots==0) and gcm.get_team_role()~=5 and gcm.get_game_state() ==2 then
        
    --get foot sensor data
    fsrRight = Body.get_sensor_fsrRight()
    fsrLeft = Body.get_sensor_fsrLeft()
    curT = Body.get_time();
        
    --check if we are in the air
    if allLessThanTenth(fsrRight) and allLessThanTenth(fsrLeft) then
        
        --if this is first time we are sensing lifting, note the time
        if lifted1 == 0 then
            lifted1 = 1;
            liftedT = curT;
            
        --if we sensed lifting before, check again to make sure its legit    
        elseif lifted1 == 1 and (curT-liftedT)>0.25 then               
            lifted2 = 1; --now we are sure
            lifted1 = 0; --reset lifted1
        end
    
    --otherwise we are on the ground
    else
        
        --check if we were lifted for long enough to count for manual placement
        if lifted2 == 1 then
            
            --now we are sure we can manually place
            init_particles_manual_placement();
            
            --reset values
            lifted1 = 0;
            lifted2 = 0;
            liftedT = 0;
        
        --if we haven't, then just reset all values
        else
            lifted1 = 0;
            lifted2 = 0;
            liftedT = 0;
        end                 
    end    
  end

  -- ball detection
  ball_gamma = 0.3;
  t=Body.get_time();

  if (vcm.get_ball_detect() == 1) then
    tVisionBall = Body.get_time();
    ball.p = (1-ball_gamma)*ball.p+ball_gamma;
    --TODO: sometimes the read from vcm is NAN
    local v = vcm.get_ball_v();
    local dr = vcm.get_ball_dr();
    local da = vcm.get_ball_da();
--    print('VCM:', v[1], v[2], dr, da)
    ballFilter:observation_xy(v[1], v[2], dr, da);
    --Green insted of red for indicating
    --As OP tend to detect red eye as balls
    ball_led={1,0,0}; 

    -- Update the velocity
    -- use centroid info only
    ball_v_inf = wcm.get_ball_v_inf();
    ball.t = Body.get_time();

    t_locked = wcm.get_ball_t_locked_on();
    th_locked = 1.5;

    if (t_locked > th_locked ) and wcm.get_ball_locked_on() == 1 then
      Velocity.update(ball_v_inf[1],ball_v_inf[2],ball.t);
      ball.vx, ball.vy, dodge  = Velocity.getVelocity();
    else
      Velocity.update_noball(ball.t);--notify that ball is missing
    end
    --print('Ball Seen')
    wcm.set_robot_use_team_ball(0);
  else
    ball.p = (1-ball_gamma)*ball.p;
    Velocity.update_noball(Body.get_time());--notify that ball is missing
    ball_led={0,0,0};
  end

  --log.debug("Ball prob",ball.p)    


  --Goal detection

  if vcm.get_goal_detect() == 1 then
    pose.tGoal = Body.get_time();
    local color = vcm.get_goal_color();
    local goalType = vcm.get_goal_type();
    local v1 = vcm.get_goal_v1();
    local v2 = vcm.get_goal_v2();
    local v = {v1, v2};
    
    if gcm.get_team_role()==5 then
      if gcm.get_coach_confirm()==1 then 
        --Coach position is already confirmed, so don't update
      else
        PoseFilter.post_coach(v1,v2,goalType)
      end
    elseif (goalType == 0) then
      PoseFilter.post_unified_unknown(v);
      goal_led = {1,1,0}
      --Body.set_indicator_goal({1,1,0});
    elseif(goalType == 1) then
      PoseFilter.post_unified_left(v);
      goal_led = {1,1,0}
      --Body.set_indicator_goal({1,1,0});
    elseif(goalType == 2) then
      PoseFilter.post_unified_right(v);
      goal_led = {1,1,0}
      --Body.set_indicator_goal({1,1,0});
    elseif(goalType == 3) then
      PoseFilter.goal_unified(v);
      goal_led = {0,0,1}
      --Body.set_indicator_goal({0,0,1});
    end
  else
    goal_led={0,0,0};
  end

  -- bottom camera line update
  if vcm.get_line2_detect() == 1 and vcm.get_circle_detect() == 0 and vcm.get_corner_detect() == 0 and gcm.get_team_role()~=5 then
    if vcm.get_line_lengthB() > 0.8 then
      local v = vcm.get_line_v();
      local a = vcm.get_line_angle();
      PoseFilter.btmLineUpdate(v, a);--use longest line in the view
    end
  end

  -- top camera line update
 if vcm.get_line1_detect() == 1 and vcm.get_circle_detect() == 0 and vcm.get_corner_detect() == 0 and gcm.get_team_role()~=5 then
    if vcm.get_line_lengthB() > 2.2 and vcm.get_line_lengthB() < 4 then
      local v = vcm.get_line_v();
      local a = vcm.get_line_angle();
      PoseFilter.topLineUpdate(v, a);--use longest line in the view
    end
  end

  --circle detection
  if vcm.get_circle_detect() == 1 and gcm.get_team_role()~=5 then
    local  x = vcm.get_circle_y(); --x and y are flipped because vision reports them backwards
    local  y = vcm.get_circle_x();
    local  v = {};
    local  a = vcm.get_circle_angle();
    v[1]=x;
    v[2]=y;
    --print('Circle Update');
    --print("x:" .. x, "y:" .. y);
    PoseFilter.circle(v,a);
  end

  --corner detection
  if vcm.get_corner_detect() == 1 and gcm.get_team_role()~=5 then    
    --L corner
    if vcm.get_corner_type() == 1 then
        local v=vcm.get_corner_v();
        local a=vcm.get_corner_angle();
        PoseFilter.cornerL(v,a);
    --T corner
    elseif vcm.get_corner_type() == 2 then
        local v=vcm.get_corner_v();
        local a=vcm.get_corner_angle();
        PoseFilter.cornerT(v,a);
    end
  end

  --Spot detection
  if vcm.get_spot_detect() == 1 and gcm.get_team_role()~=5 then
    local color = vcm.get_spot_color();
    local v = vcm.get_spot_v();
    if color == Config.color.white then
      PoseFilter.spot(v);
    end
  end

  --get updated info from filters
  ball.x, ball.y = ballFilter:get_xy();
  pose.x,pose.y,pose.a = PoseFilter.get_pose();

  --Use team vision information when we cannot find the ball ourselves
  team_ball = wcm.get_robot_team_ball();
  team_ball_score = wcm.get_robot_team_ball_score();

  t=Body.get_time();
  if use_team_ball>0 and
    (t-tVisionBall)>team_ball_timeout and
    ball.p < 0.6 and --should be sure we saw the ball before ignoring team
    gcm.get_team_role()>0 and --GOALIE SHOULDNT USE THE TEAM BALL
    team_ball_score > team_ball_threshold then

    ballLocal = util.pose_relative(
	{team_ball[1],team_ball[2],0},{pose.x,pose.y,pose.a}); 
    ball.x = ballLocal[1];
    ball.y = ballLocal[2];
    ball.t = t;
    ball.p = 0;
    ball_led={0,1,1}; 
    wcm.set_robot_use_team_ball(1)
   print("TEAMBALL")
    wcm.set_robot_use_team_ball(1);
  end
  
  --update LEDs and SHM with new info
  update_led();
  update_shm();
end

--Update LEDs to show useful information
function update_led()
  --Turn on the eye light according to team color
  --If gamecontroller is down
  if gcm.get_game_state()~=3 and
     gcm.get_game_gc_latency() > 10.0 then

    if gcm.get_team_color() == 0 then --Blue team
      Body.set_indicator_goal({0,0,0});
      Body.set_indicator_ball({0,0,1});
    else --Red team
      Body.set_indicator_goal({0,0,0});
      Body.set_indicator_ball({0,0,1});
    end
    return;
  end

  --Only disable eye LED during playing
--  if led_on>0 and gcm.get_game_state()~=3 then
  if led_on>0 then
    Body.set_indicator_goal(goal_led);
    Body.set_indicator_ball(ball_led);
    Body.set_indicator_role(gcm.get_team_role());
  else
    Body.set_indicator_goal({0,0,0});
    Body.set_indicator_ball({0,0,0});
    Body.set_indicator_role(-1);
  end
end

-- update shm values
function update_shm()
   
  wcm.set_robot_pose({pose.x, pose.y, pose.a});
  wcm.set_robot_time(Body.get_time());
  wcm.set_robot_confidence(PoseFilter.get_confidence());

  wcm.set_ball_x(ball.x);
  wcm.set_ball_y(ball.y);
  wcm.set_ball_t(ball.t);
  wcm.set_ball_velx(ball.vx);
  wcm.set_ball_vely(ball.vy);
  wcm.set_ball_p(ball.p);

  wcm.set_goal_t(pose.tGoal);
  wcm.set_goal_attack(get_goal_attack());
  wcm.set_goal_defend(get_goal_defend());
  wcm.set_goal_attack_bearing(get_attack_bearing());
  wcm.set_goal_attack_angle(get_attack_angle());
  wcm.set_goal_defend_angle(get_defend_angle());

  wcm.set_goal_attack_post1(get_attack_posts()[1]);
  wcm.set_goal_attack_post2(get_attack_posts()[2]);

  wcm.set_robot_is_fall_down(mcm.get_walk_isFallDown());
  wcm.set_particle_x(PoseFilter.xp);
  wcm.set_particle_y(PoseFilter.yp);
  wcm.set_particle_a(PoseFilter.ap);
  wcm.set_particle_w(PoseFilter.wp);

end


function exit()
end


function get_ball()
  return ball;
end

function get_pose()
  return pose;
end

function zero_pose()
  PoseFilter.zero_pose();
end

function get_attack_bearing()
  return get_attack_bearing_pose(pose);
end

--Get attack bearing from pose0
function get_attack_bearing_pose(pose0)
  if gcm.get_team_color() == 1 then
    -- red attacks cyan goal
    postAttack = PoseFilter.postCyan;
  else
    -- blue attack yellow goal
    postAttack = PoseFilter.postYellow;
  end
  -- make sure not to shoot back towards defensive goal:
  local xPose = math.min(math.max(pose0.x, -0.99*PoseFilter.xLineBoundary),
                          0.99*PoseFilter.xLineBoundary);
  local yPose = pose0.y;
  local aPost = {}
  aPost[1] = math.atan2(postAttack[1][2]-yPose, postAttack[1][1]-xPose);
  aPost[2] = math.atan2(postAttack[2][2]-yPose, postAttack[2][1]-xPose);
  local daPost = math.abs(PoseFilter.mod_angle(aPost[1]-aPost[2]));
  attackHeading = aPost[2] + .5*daPost;
  attackBearing = PoseFilter.mod_angle(attackHeading - pose0.a);

  return attackBearing, daPost;
end

function get_goal_attack()
  if gcm.get_team_color() == 1 then
    -- red attacks cyan goal
    return {PoseFilter.postCyan[1][1], 0, 0};
  else
    -- blue attack yellow goal
    return {PoseFilter.postYellow[1][1], 0, 0};
  end
end

function get_goal_defend()
  if gcm.get_team_color() == 1 then
    -- red defends yellow goal
    return {PoseFilter.postYellow[1][1], 0, 0};
  else
    -- blue defends cyan goal
    return {PoseFilter.postCyan[1][1], 0, 0};
  end
end

function get_attack_posts()
  if gcm.get_team_color() == 1 then
    return Config.world.postCyan;
  else
    return Config.world.postYellow;
  end
end

function get_attack_angle()
  goalAttack = get_goal_attack();

  dx = goalAttack[1] - pose.x;
  dy = goalAttack[2] - pose.y;
  return mod_angle(math.atan2(dy, dx) - pose.a);
end

function get_defend_angle()
  goalDefend = get_goal_defend();

  dx = goalDefend[1] - pose.x;
  dy = goalDefend[2] - pose.y;
  return mod_angle(math.atan2(dy, dx) - pose.a);
end

function get_team_color()
  return gcm.get_team_color();
end

function pose_global(pRelative, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  return vector.new{pose[1] + ca*pRelative[1] - sa*pRelative[2],
                    pose[2] + sa*pRelative[1] + ca*pRelative[2],
                    pose[3] + pRelative[3]};
end

function pose_relative(pGlobal, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  local px = pGlobal[1]-pose[1];
  local py = pGlobal[2]-pose[2];
  local pa = pGlobal[3]-pose[3];
  return vector.new{ca*px + sa*py, -sa*px + ca*py, mod_angle(pa)};
end

function allLessThanTenth(table)
  for k,v in pairs(table) do
    if v >= .1 then
      return false
    end
  end
  return true
end

function allZeros(table)
  for k,v in pairs(table) do
    if v~=0 then
      return false
    end
  end
  return true
end


