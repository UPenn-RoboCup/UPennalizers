module(..., package.seeall);


-- Vision Parameters

--NOW REDEFINED!
color = {};
color.orange = 1;
color.yellow = 2;
color.robotblue = 4;
color.field = 8;
color.white = 16;
color.robotpink = 32;


vision = {};
vision.maxFPS = 30;
vision.scaleA = {2, 2};
vision.scaleB = {2, 2};

vision.ballColor = color.white;
vision.goalColor = color.white;


vision.enable_spot_detection = 1;
vision.enable_top_line_detection = 1;
vision.enable_line_detection = 1;
vision.enable_circle_detection = 1;
vision.enable_corner_detection = 1;

vision.enable_BallOnLine_detection = true;
-- turn off the ball on line detection for goalie to reduce false balls
if Config.game.playerID == 1 then
   vision.enable_BallOnLine_detection = false;
end

-- use this to enable copying images to shm (for colortables, testing)
vision.copy_image_to_shm = 1;
-- use this to enable storing all images
vision.store_all_images = 1;
-- use this to enable storing images where the goal was detected
vision.store_goal_detections = 0;
-- use this to enable storing images where the ball was detected
vision.store_ball_detections = 0;
-- use this to substitute goal check with blue/yellow ball check
vision.use_point_goal = 0;

vision.enable_robot_detection = 0;

vision.enable_freespace_detection = 0;
--use this to print time cosumed by vision functions
vision.print_time = 0; 

vision.enable_team_broadcast = 1;
--use this to turn on team broadcast (wireless monitor)
--If 0, wired monitor will be used.

-- Use tilted bounding box? (OP specific)
vision.use_tilted_bbox = 0;
-- Store and send subsampled image?
vision.subsampling = 0; --1/2 sized image
vision.subsampling2 = 0; --1/4 sized image

vision.coach={};
vision.coach.posex = 2.7; 		-- 0.0;
vision.coach.posey = -5.2;		-- -3.0;
vision.coach.posea = 1.57;		-- 1.57;
vision.coach.table_height = 0.7;	-- 0.6;
vision.coach.home_left = true;

--Vision parameter values
--For VGA resolution
vision.ball={};

  vision.ball.diameter = 0.1; --0.065
  --labelA for bottom camera is 1/4 the size of that for top camera
  --decrease the threshold by 2 to be conservative
  vision.ball.th_min_color = {24,6}; -- 200, 50 or even bigger
  vision.ball.th_min_color2 = {25,70};
  vision.ball.th_max_color2 = {1200,1050};
  vision.ball.th_max_color3 = {30,40};
  vision.ball.th_min_fill_rate_top = 0.35; --0.35;
  vision.ball.th_min_fill_rate_btm = 0.5; --0.3 before Germany
  vision.ball.th_max_fill_rate = 0.9;
  vision.ball.th_height_max  = 0.3;--.15
  --bouding box w/h shrinked by 2
  vision.ball.coach_table_height = 0.6
  vision.ball.th_ground_boundingbox = {{-10,10,-10,15},{-5,5,-5,8}};
  vision.ball.th_min_green1 = {0.4,0.2}; --top btm cam
  vision.ball.th_min_green2 = {0.055555,0.00}; --- btm shadow
  vision.ball.th_max_fill_rate_pink = {.15,0.08}; -- pink fill rate
  vision.ball.pink = color.robotpink;
  vision.ball.check_for_ground = 1;
  vision.ball.bottom_boudary_check = 0;

 --New parameters for new ball
  vision.ball.th_max_aspect_ratio = 1.7; --1.5;
  vision.ball.th_min_aspect_ratio = 0.8;
  vision.ball.th_min_black_rate_btm =0.17; --0.2 before Germany
  vision.ball.th_min_black_rate_top = 0.1;
  vision.ball.th_max_black_rate = 0.8;
  vision.ball.th_min_black_area = 3

  -- Height check parameters
  vision.ball.min_height_btm = -0.08;
  vision.ball.max_height_btm = 0.08;
  vision.ball.min_height_top = -0.2;
  vision.ball.max_height_top = 0.15;

  -- Ball on line detection parameters
  vision.ball.BoL_min_fill_rate = 0.2
  vision.ball.BoL_max_fill_rate = 0.8
  vision.ball.BoL_min_black_rate = 0.09
  vision.ball.BoL_max_black_rate = 0.5
  vision.ball.BoL_min_refined_fill_rate = 0.3
  vision.ball.BoL_max_refined_fill_rate = 0.95
  vision.ball.BoL_min_refined_black_rate = 0.1
  vision.ball.BoL_max_refined_black_rate = 0.7
  vision.ball.BoL_min_fill_rate_B = 0.3
  vision.ball.BoL_max_fill_rate_B = 0.9
  vision.ball.BoL_min_black_rate_B = 0.1
  vision.ball.BoL_min_black_rate_B_far = 0.05
  vision.ball.BoL_max_black_rate_B = 0.7
  vision.ball.BoL_min_green_rate_below = 0.3
  vision.ball.BoL_min_green_rate_below_alone = 0.7
  vision.ball.BoL_min_green_rate_above = 0.4
  vision.ball.BoL_min_green_rate_above_alone = 0.7

--------OLD ORANGE BALL DETECTION PARAMETERS
--vision.ball.diameter = 0.065; --0.065
--labelA for bottom camera is 1/4 the size of that for top camera
--decrease the threshold by 2 to be conservative
--vision.ball.th_min_color = {24,6}; -- 200, 50 or even bigger
--vision.ball.th_min_color2 = {3,4};
--vision.ball.th_max_color2 = {600,450};
--vision.ball.th_max_color3 = {30,40};
--vision.ball.th_min_fill_rate = 0.3 --0.35;
--vision.ball.th_height_max  = 0.3;--.15
--bouding box w/h shrinked by 2
--vision.ball.coach_table_height = 0.6
--vision.ball.th_ground_boundingbox = {{-30,30,0,20},{-15,15,0,10}};
--vision.ball.th_min_green1 = {400,100};
--vision.ball.th_min_green2 = {150,37};
--vision.ball.th_max_fill_rate_pink = {.15,0.08}; -- pink fill rate
--vision.ball.pink = color.robotpink;
--vision.ball.check_for_ground = 1;
--vision.ball.bottom_boudary_check = 0;


--Vision check values
--For VGA resolution
vision.goal={};
vision.goal.th_min_color_count=100;
vision.goal.th_nPostB = 8;
vision.goal.th_min_area = 80 -- Sagar: It was 150;
vision.goal.th_min_orientation = 75*math.pi/180;
vision.goal.th_min_fill_extent={0.35,0.50};
vision.goal.th_aspect_ratio={2.5, 15};
vision.goal.th_edge_margin= 5;
vision.goal.th_bottom_boundingbox=0.9;
vision.goal.th_ground_boundingbox={-25,25,0,10}; 
vision.goal.th_min_green_ratio = 0.1;
vision.goal.th_max_green_ratio_whole = 0.5;
vision.goal.th_min_bad_color_ratio = 0.1;
vision.goal.th_goal_separation = {0.2,2.0}; 
vision.goal.th_min_area_unknown_post = 200;
vision.goal.check_for_ground_whole = 1;
vision.goal.check_for_ground = 1;
vision.goal.use_centerpost = 1;
vision.goal.distanceFactor = 1.5; --1.15
vision.goal.distanceFactorGoalie = 1
vision.goal.lower_factor = 0.25
vision.goal.height_max = 0.70

vision.line={};
vision.line.max_width = 12; -- 15
vision.line.connect_th = 1.6;
vision.line.lwratio = 1.5;
vision.line.max_gap=0;
vision.line.min_length=7; --10
vision.line.min_angle_diff = 3;
vision.line.max_angle_diff = 90;

vision.spot={}
vision.spot.min_area = 10;
vision.spot.max_area = 150;
vision.spot.aspect_ratio = 0.40;
vision.spot.ground_boundingbox = {-15,15,-15,15};
vision.spot.ground_th = 0.7;
vision.spot.max_black_rate_B = 0.02;
vision.spot.max_black_rate_A = 0.05; -- should be lowered, needs testing

vision.circle = {}
vision.circle.var_threshold = 0.08;

vision.corner={};
vision.corner.dist_threshold = {10, 15};
vision.corner.angle_threshold = 6*math.pi/180; --6 degrees
vision.corner.length_threshold = 6;
vision.corner.T_thr = 0.20;
