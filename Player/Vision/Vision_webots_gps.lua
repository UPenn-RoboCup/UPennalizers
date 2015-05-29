module(..., package.seeall);

require('carray');
require('vector');
require('Config');
-- Enable Webots specific
if (string.find(Config.platform.name,'Webots')) then
  webots = 1;
end

require('ImageProc');
require('HeadTransform');
require('vcm');
require('mcm');
require('Body')


use_gps_only = Config.use_gps_only or 0;


colorOrange = Config.color.orange;
colorYellow = Config.color.yellow;
colorCyan = Config.color.cyan;
colorField = Config.color.field;
colorWhite = Config.color.white;

yellowGoalCountThres = Config.vision.yellow_goal_count_thres;

saveCount = 0;

use_point_goal = Config.vision.use_point_goal or 0;
subsampling = Config.vision.subsampling or 0;
subsampling2 = Config.vision.subsampling2 or 0;

-- debugging settings
vcm.set_debug_enable_shm_copy(Config.vision.copy_image_to_shm);
vcm.set_debug_store_goal_detections(Config.vision.store_goal_detections);
vcm.set_debug_store_ball_detections(Config.vision.store_ball_detections);
vcm.set_debug_store_all_images(Config.vision.store_all_images);

-- Timing
count = 0;
lastImageCount = {0,0};
t0 = unix.time()

function entry()
  --Temporary value.. updated at body FSM at next frame
  vcm.set_camera_bodyHeight(Config.walk.bodyHeight);
  vcm.set_camera_bodyTilt(0);
  vcm.set_camera_height(Config.walk.bodyHeight+Config.head.neckZ);
	vcm.set_camera_ncamera(Config.camera.ncamera);
  vcm.set_camera_reload_LUT(0);
  vcm.set_camera_lut_filename("");
  vcm.set_camera_command(-1)  --turn on camera switching at beginning
  HeadTransform.entry()-- Start the HeadTransform machine
end


function update_shm_fov(sel)
  --This function projects the boundary of current labeled image
  local sa = Config.vision.scaleA
  cidx = sel + 1 
  local fovC={Config.camera.width[cidx]/2/sa,Config.camera.height[cidx]/2/sa}
  local fovBL={0,Config.camera.height[cidx]/sa}
  local fovBR={Config.camera.width[cidx]/sa,Config.camera.height[cidx]/sa}
  local fovTL={0,0}
  local fovTR={Config.camera.width[cidx]/sa,0}
  vcm['set_image'..cidx..'_fovC'](vector.slice(HeadTransform.projectGround(HeadTransform.coordinatesA(fovC,0.1)),1,2))
  vcm['set_image'..cidx..'_fovTL'](vector.slice(HeadTransform.projectGround(HeadTransform.coordinatesA(fovTL,0.1)),1,2))
  vcm['set_image'..cidx..'_fovTR'](vector.slice(HeadTransform.projectGround(HeadTransform.coordinatesA(fovTR,0.1)),1,2))
  vcm['set_image'..cidx..'_fovBL'](vector.slice(HeadTransform.projectGround(HeadTransform.coordinatesA(fovBL,0.1)),1,2))
  vcm['set_image'..cidx..'_fovBR'](vector.slice(HeadTransform.projectGround(HeadTransform.coordinatesA(fovBR,0.1)),1,2))
end

function exit()
  HeadTransform.exit();
end

--Update relative ball position based on absolute position
function update()

  local check_side = function(v,v1,v2)
    --find the angle from the vector v-v1 to vector v-v2
    local vel1 = {v1[1]-v[1],v1[2]-v[2]};
    local vel2 = {v2[1]-v[1],v2[2]-v[2]};
    angle1 = math.atan2(vel1[2],vel1[1]);
    angle2 = math.atan2(vel2[2],vel2[1]);
    return util.mod_angle(angle1-angle2);
  end

  --We are now using ground truth robot and ball pose data
  headAngles = Body.get_head_position();
  --TODO: camera select

  HeadTransform.update(0, headAngles);
  update_shm_fov(0)

  HeadTransform.update(1, headAngles);
  update_shm_fov(1)

  --Get the global coordinates of FOV boundary
  local v_TL1 = vcm.get_image1_fovTL();
  local v_TR1 = vcm.get_image1_fovTR();
  local v_BL1 = vcm.get_image1_fovBL();
  local v_BR1 = vcm.get_image1_fovBR();
  local v_TL2 = vcm.get_image2_fovTL();
  local v_TR2 = vcm.get_image2_fovTR();
  local v_BL2 = vcm.get_image2_fovBL();
  local v_BR2 = vcm.get_image2_fovBR();

  --Get GPS coordinate of robot and ball
  gps_pose = wcm.get_robot_gpspose();


---------------------------------------------------
--Check whether ball is within FOV boundary 
---------------------------------------------------
  ballGlobal=wcm.get_robot_gps_ball();    
  ballLocal = util.pose_relative(ballGlobal,gps_pose)
  local ball_detected_top, ball_detected_bottom = false,false
  if check_side(v_TR1, v_TL1, ballLocal) < 0 and
     check_side(v_TL1, v_BL1, ballLocal) < 0 and
     check_side(v_BR1, v_TR1, ballLocal) < 0 and
     check_side(v_BL1, v_BR1, ballLocal) < 0 then
     ball_detected_top = true
   end
  if check_side(v_TR2, v_TL2, ballLocal) < 0 and
     check_side(v_TL2, v_BL2, ballLocal) < 0 and
     check_side(v_BR2, v_TR2, ballLocal) < 0 and
     check_side(v_BL2, v_BR2, ballLocal) < 0 then
     ball_detected_bottom = true
   end
  if ball_detected_top or ball_detected_bottom then 
    local r = math.sqrt(ballLocal[1]^2+ballLocal[2]^2)
    local dr = 0.25*r
    local da = 10*math.pi/180
    vcm.set_ball_detect(1)
    vcm.set_ball_v({ballLocal[1],ballLocal[2],0})
    vcm.set_ball_dr(dr)
    vcm.set_ball_da(da)
  else vcm.set_ball_detect(0) end



---------------------------------------------------
--Check whether any goalpost is within FOV boundary 
---------------------------------------------------
  local posts_detected,last_post_idx = 0,0
  local posts={
    Config.world.postYellow[1],
    Config.world.postYellow[2],
    Config.world.postCyan[1],
    Config.world.postCyan[2]
  }
  local posts_v={{0,0},{0,0}}
  for i=1,4 do
    --Check if the goalpost is inside FOV of the top camera
    local postLocal = util.pose_relative({posts[i][1],posts[i][2],0},gps_pose)

    if check_side(v_TR1, v_TL1, postLocal) < 0 and
     check_side(v_TL1, v_BL1, postLocal) < 0 and
     check_side(v_BR1, v_TR1, postLocal) < 0 and
     check_side(v_BL1, v_BR1, postLocal) < 0 then

     posts_detected = posts_detected + 1
     posts_v[posts_detected]={postLocal[1],postLocal[2]}
     last_post_idx = i
    end
  end
   if posts_detected==0 then vcm.set_goal_detect(0)
   else
    vcm.set_goal_color(Config.color.yellow)
    vcm.set_goal_detect(1)
    vcm.set_goal_v1(posts_v[1])
    vcm.set_goal_v2(posts_v[2])
    if posts_detected==1 then
      if false then vcm.set_goal_type(0) --Unknown post
      else
        if last_post_idx==1 or last_post_idx==3 then vcm.set_goal_type(1) --LEFT post
        else vcm.set_goal_type(2) end --RIGHT post
      end
    else vcm.set_goal_type(3) end--Two posts    
  end
  
  --TODO: add noise 
  return true
end 