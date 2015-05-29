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
-- define detection task for each camera

vision = {};
vision.ballColor = color.orange;
vision.goal1Color = color.yellow;
vision.goal2Color = color.yellow;
vision.maxFPS = 30;
vision.scaleA = {2, 2};
vision.scaleB = {2, 2};


vision.enable_line_detection = 1;
vision.enable_corner_detection = 0;
-- use this to enable spot detection
vision.enable_spot_detection = 0;
-- use this to enable midfield landmark detection
vision.enable_midfield_landmark_detection = 0;
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
----------------------------
--OP specific
----------------------------
-- Use tilted bounding box?
vision.use_tilted_bbox = 0;
-- Store and send subsampled image?
vision.subsampling = 0; --1/2 sized image
vision.subsampling2 = 0; --1/4 sized image

--Vision parameter values
--For VGA resolution
vision.ball={};
vision.ball.diameter = 0.065;
--labelA for bottom camera is 1/4 the size of that for top camera
--decrease the threshold by 2 to be conservative
vision.ball.th_min_color = {24,6}; -- 200, 50 or even bigger
vision.ball.th_min_color2 = {3,4};
vision.ball.th_max_color2 = {600,450};
vision.ball.th_max_color3 = {30,40};
vision.ball.th_min_fill_rate = 0.3 --0.35;
vision.ball.th_height_max  = 0;--.15
--bouding box w/h shrinked by 2
vision.ball.th_ground_boundingbox = {{-30,30,0,20},{-15,15,0,10}};
vision.ball.th_min_green1 = {400,100};
vision.ball.th_min_green2 = {150,37};
vision.ball.th_max_fill_rate_pink = {.15,0.08}; -- pink fill rate
vision.ball.pink = color.robotpink;
vision.ball.check_for_ground = 1;
vision.ball.bottom_boudary_check = 1;

--Vision check values
--For VGA resolution
vision.goal={};
vision.goal.th_min_color_count=100;
vision.goal.th_nPostB = 5;
vision.goal.th_min_area = 40;
vision.goal.th_min_orientation = 75*math.pi/180;
vision.goal.th_min_fill_extent={0.3,0.6};
vision.goal.th_aspect_ratio={2.5, 15};
vision.goal.th_edge_margin= 5;
vision.goal.th_bottom_boundingbox=0.9;
vision.goal.th_ground_boundingbox={-15,15,-15,10}; 
vision.goal.th_min_green_ratio = 0.1;
vision.goal.th_min_bad_color_ratio = 0.1;
vision.goal.th_goal_separation = {0.2,2.0}; 
vision.goal.th_min_area_unknown_post = 200;
vision.goal.use_centerpost = 1;
vision.goal.check_for_ground = 0;
vision.goal.distanceFactorYellow = 1.15
vision.goal.distanceFactorYellowGoalie = 1

vision.line={};
vision.line.max_width = 10; -- 15
vision.line.connect_th = 2;
vision.line.max_gap=1;
vision.line.min_length=5; --10
vision.line.min_angle_diff = 3;
vision.line.max_angle_diff = 90;


vision.corner={};
vision.corner.dist_threshold = 15;
vision.corner.length_threshold = 5;
vision.corner.min_center_dist = 1.5;
vision.centercircle_check = 1;
vision.corner.enable_distance_filter = 1;
vision.corner.distance_filter_threshold = 1.5;
