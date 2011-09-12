module(..., package.seeall);

-- Vision Parameters

color = {};
color.orange = 1;
color.yellow = 2;
color.cyan = 4;
color.field = 8;
color.white = 16;

vision = {};
vision.maxFPS = 30;
vision.scaleB = 4;
vision.ball_diameter = 0.065;
vision.ball_height_max = 0.20; -- -0.20
vision.yellow_goal_count_thres = 150;

-- use this to enable line detection
vision.enable_line_detection = 1;
-- use this to enable spot detection
vision.enable_spot_detection = 0;
-- use this to enable midfield landmark detection
vision.enable_midfield_landmark_detection = 1;
-- Enable Velocity filter
vision.enable_velocity_detection = 0;
-- use this to enable copying images to shm (for colortables, testing)
vision.copy_image_to_shm = 1;
-- use this to enable storing all images
vision.store_all_images = 1;
-- use this to enable storing images where the goal was detected
vision.store_goal_detections = 0;
-- use this to enable storing images where the ball was detected
vision.store_ball_detections = 0;
-- use this to enable ground check 
vision.check_for_ground = 1;

-- use this to substitute goal check with blue/yellow ball check
vision.use_point_goal = 0;

vision.ballColor = color.orange;
vision.goal1Color = color.yellow;
vision.goal2Color = color.cyan;

-- Subsample image?
vision.subsampling = 1;
