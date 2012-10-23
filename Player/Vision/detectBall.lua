module(..., package.seeall);

require('Config');      -- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');       -- For Projection
require('Vision');
require('Body');
require('shm');
require('vcm');
require('mcm');
require('Detection');
require('Debug');

-- Define Color
colorOrange = Config.color.orange;
colorYellow = Config.color.yellow;
colorCyan = Config.color.cyan;
colorField = Config.color.field;
colorWhite = Config.color.white;

diameter = Config.vision.ball.diameter;
th_min_color=Config.vision.ball.th_min_color;
th_min_color2=Config.vision.ball.th_min_color2;
th_min_fill_rate=Config.vision.ball.th_min_fill_rate;
th_height_max=Config.vision.ball.th_height_max;
th_ground_boundingbox=Config.vision.ball.th_ground_boundingbox;
th_min_green1=Config.vision.ball.th_min_green1;
th_min_green2=Config.vision.ball.th_min_green2;

check_for_ground = Config.vision.ball.check_for_ground;
check_for_field = Config.vision.ball.check_for_field or 0;
field_margin = Config.vision.ball.field_margin or 0;

th_headAngle = Config.vision.ball.th_headAngle or -10*math.pi/180;

function detect(color)

--  enable_obs_challenge = Config.obs_challenge or 0;
--  if enable_obs_challenge == 1 then
--    colorCount = Vision.colorCount_obs;
--  else
    colorCount = Vision.colorCount;
--  end

  headAngle = Body.get_head_position();
  --print("headPitch:",headAngle[2]*180/math.pi);
  local ball = {};
  ball.detect = 0;
  vcm.add_debug_message(string.format("\nBall: pixel count: %d\n",
	colorCount[color]));
  
--  print(string.format("\nBall: pixel count: %d\n",
--	      colorCount[color]));


  -- threshold check on the total number of ball pixels in the image
  if (colorCount[color] < th_min_color) then  	
    vcm.add_debug_message("pixel count fail");
    return ball;  	
  end

  -- find connected components of ball pixels
--  if enable_obs_challenge == 1 then
--    ballPropsB = ImageProc.connected_regions_obs(Vision.labelB.data_obs, Vision.labelB.m, 
--                                              Vision.labelB.n, color);
--  else
    ballPropsB = ImageProc.connected_regions(Vision.labelB.data, Vision.labelB.m, 
                                              Vision.labelB.n, color);
--  end
--  util.ptable(ballPropsB);
--TODO: horizon cutout
-- ballPropsB = ImageProc.connected_regions(labelB.data, labelB.m, 
--	labelB.n, HeadTransform.get_horizonB(),color);


  if (#ballPropsB == 0) then return ball; end

-- Check max 5 largest blobs 
  for i=1,math.min(5,#ballPropsB) do
    vcm.add_debug_message(string.format(
	"Ball: checking blob %d/%d\n",i,#ballPropsB));

    check_passed = true;
    ball.propsB = ballPropsB[i];
    ball.propsA = Vision.bboxStats(color, ballPropsB[i].boundingBox);
    ball.bboxA = Vision.bboxB2A(ballPropsB[i].boundingBox);
    local fill_rate = ball.propsA.area / 
	Vision.bboxArea(ball.propsA.boundingBox);

    vcm.add_debug_message(string.format("Area:%d\nFill rate:%2f\n",
       ball.propsA.area,fill_rate));

    if ball.propsA.area < th_min_color2 then
      --Area check
      vcm.add_debug_message("Area check fail\n");
      check_passed = false;
    elseif fill_rate < th_min_fill_rate then
      --Fill rate check
      vcm.add_debug_message("Fillrate check fail\n");
      check_passed = false;
    else
      -- diameter of the area
      dArea = math.sqrt((4/math.pi)*ball.propsA.area);
     -- Find the centroid of the ball
      ballCentroid = ball.propsA.centroid;
      -- Coordinates of ball
      scale = math.max(dArea/diameter, ball.propsA.axisMajor/diameter);
      v = HeadTransform.coordinatesA(ballCentroid, scale);
      v_inf = HeadTransform.coordinatesA(ballCentroid,0.1);
      
      vcm.add_debug_message(string.format(
	"Ball v0: %.2f %.2f %.2f\n",v[1],v[2],v[3]));

      if v[3] > th_height_max then
        --Ball height check
        vcm.add_debug_message("Height check fail\n");
        check_passed = false;

      elseif check_for_ground>0 and
        headAngle[2] < th_headAngle then
        -- ground check
        -- is ball cut off at the bottom of the image?
        local vmargin=Vision.labelA.n-ballCentroid[2];
        vcm.add_debug_message("Bottom margin check\n");
        vcm.add_debug_message(string.format(
    	  "lableA height: %d, centroid Y: %d diameter: %.1f\n",
  	  Vision.labelA.n, ballCentroid[2], dArea ));
        --When robot looks down they may fail to pass the green check
        --So increase the bottom margin threshold
        if vmargin > dArea * 2.0 then
          -- bounding box below the ball
          fieldBBox = {};
          fieldBBox[1] = ballCentroid[1] + th_ground_boundingbox[1];
          fieldBBox[2] = ballCentroid[1] + th_ground_boundingbox[2];
          fieldBBox[3] = ballCentroid[2] + .5*dArea 
				     + th_ground_boundingbox[3];
          fieldBBox[4] = ballCentroid[2] + .5*dArea 
 				     + th_ground_boundingbox[4];
          -- color stats for the bbox
          fieldBBoxStats = ImageProc.color_stats(Vision.labelA.data, 
  	    Vision.labelA.m, Vision.labelA.n, colorField, fieldBBox);
          -- is there green under the ball?
          vcm.add_debug_message(string.format("Green check:%d\n",
	   	   fieldBBoxStats.area));
          if (fieldBBoxStats.area < th_min_green1) then
            -- if there is no field under the ball 
      	    -- it may be because its on a white line
            whiteBBoxStats = ImageProc.color_stats(Vision.labelA.data,
 	      Vision.labelA.m, Vision.labelA.n, colorWhite, fieldBBox);
            if (whiteBBoxStats.area < th_min_green2) then
              vcm.add_debug_message("Green check fail\n");
              check_passed = false;
            end
          end --end white line check
        end --end bottom margin check
      end --End ball height, ground check
    end --End all check

    if check_passed then    
      ballv = {v[1],v[2],0};
--      ballv = {v_inf[1],v_inf[2],0};
      pose=wcm.get_pose();
      posexya=vector.new( {pose.x, pose.y, pose.a} );
      ballGlobal = util.pose_global(ballv,posexya); 
      if check_for_field>0 then
        if math.abs(ballGlobal[1]) > 
   	  Config.world.xLineBoundary + field_margin or
          math.abs(ballGlobal[2]) > 
	  Config.world.yLineBoundary + field_margin then

          vcm.add_debug_message("Field check fail\n");
          check_passed = false;
        end
      end
    end
    if check_passed then
      break;
    end
  end --End loop

  if not check_passed then
    return ball;
  end
  
  --SJ: Projecting ball to flat ground makes large distance error
  --We are using declined plane for projection

  vMag =math.max(0,math.sqrt(v[1]^2+v[2]^2)-0.50);
  bodyTilt = vcm.get_camera_bodyTilt();
--  print("BodyTilt:",bodyTilt*180/math.pi)
  projHeight = vMag * math.tan(10*math.pi/180);


  v=HeadTransform.projectGround(v,diameter/2-projHeight);

  --SJ: we subtract foot offset 
  --bc we use ball.x for kick alignment
  --and the distance from foot is important
  v[1]=v[1]-mcm.get_footX()

  ball_shift = Config.ball_shift or {0,0};
  --Compensate for camera tilt
  v[1]=v[1] + ball_shift[1];
  v[2]=v[2] + ball_shift[2];

  --Ball position ignoring ball size (for distant ball observation)
  v_inf=HeadTransform.projectGround(v_inf,diameter/2);
  v_inf[1]=v_inf[1]-mcm.get_footX()
  wcm.set_ball_v_inf({v_inf[1],v_inf[2]});  

  ball.v = v;
  ball.detect = 1;
  ball.r = math.sqrt(ball.v[1]^2 + ball.v[2]^2);

  -- How much to update the particle filter
  ball.dr = 0.25*ball.r;
  ball.da = 10*math.pi/180;

  vcm.add_debug_message(string.format(
	"Ball detected\nv: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
--[[
  print(string.format(
	"Ball detected\nv: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
--]]
  return ball;
end

