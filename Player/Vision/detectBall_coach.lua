require('Config');      -- For Ball and Goal Size require('ImageProc');
require('HeadTransform');       -- For Projection
require('Body');
require('vcm');
require('mcm');

check_for_ground = Config.vision.ball.check_for_ground;
check_for_field = Config.vision.ball.check_for_field or 0;
field_margin = Config.vision.ball.field_margin or 0;
--function detect(color)
print('Using new coach ball detection File')
enable_obs_challenge = Config.obs_challenge or 0;
---Detects a ball of a given color.
--@param color The color to use for detection, represented by an int
--@return Table containing whether a ball was detected
--If a ball is detected, also contains additional stats about the ball
local update = function(self, color, p_vision)
--  print('ball update')
  local colorCount = p_vision.colorCount;
  headAngle = Body.get_head_position();
  --print("headPitch:",headAngle[2]*180/math.pi);
  
  self.detect = 0;
--JZ  p_vision:add_debug_message(string.format("\nBall %d: pixel count: %d\n", p_vision.camera_index,
--JZ    colorCount[color] ));
--  print(string.format("\nBall: pixel count: %d\n", colorCount[color]));

  -- threshold check on the total number of ball pixels in the image
  --if (colorCount[color] < self.th_min_color) then  	
  --  p_vision:add_debug_message("pixel count fail");
  --  return
  --end
  self.color_count = colorCount[color];

  -- find connected components of ball pixels
  local ballPropsB = ImageProc.connected_regions(
    p_vision.labelB.data, p_vision.labelB.m, 
    p_vision.labelB.n, color);
--  end
--  util.ptable(ballPropsB);
--TODO: horizon cutout
-- ballPropsB = ImageProc.connected_regions(labelB.data, labelB.m, 
--	labelB.n, HeadTransform.get_horizonB(),color);

  if (not ballPropsB or #ballPropsB == 0) then return end

-- Check all blobs until hit a ball that no longer passes area check 
  for i=1,#ballPropsB do
    --p_vision:add_debug_message(string.format("Ball: checking blob %d/%d\n",i,#ballPropsB));

    check_passed = true;
    self.propsB = ballPropsB[i];
    local bboxA = vcm.bboxStats(color, ballPropsB[i].boundingBox, _, p_vision.scaleB);
    self.propsA = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, 
                                        p_vision.labelA.n, color, bboxA);
    --print('self.propsA 73',self.propsA)
    --util.ptable(self.propsA)

    self.bboxA = vcm.bboxB2A(ballPropsB[i].boundingBox, p_vision.scaleB);
    --local fill_rate = self.propsA.area / vcm.bboxArea(self.propsA.boundingBox);
    
        temp_fillrate = self.propsA.area / vcm.bboxArea(self.propsA.boundingBox)
    aspect_ratio = self.propsA.axisMajor / self.propsA.axisMinor
    if (self.propsA.axisMinor == 0) then
        aspect_ratio = self.propsA.axisMajor / 0.00001
    end
    if self.propsA.area > self.th_max_color3 then
        p_vision:add_debug_message('Ball area too large fail\n');
        --print('area is '..self.propsA.area)
        check_passed = false;
        --goto continue;
    elseif self.propsA.area < self.th_min_color2 then
      --Area check
        p_vision:add_debug_message("Ball area too small fail\n");
      return
    elseif (self.propsA.area / vcm.bboxArea(self.propsA.boundingBox)) < self.th_min_fill_rate then
      --Fill rate check
      p_vision:add_debug_message("Fillrate check fail\n");
      check_passed = false;
      --goto continue
    elseif (aspect_ratio>6.5 or aspect_ratio<0.25) then
     -- print('aspect ratio is '..aspect_ratio)
      p_vision:add_debug_message('Aspect ratio check fail\n')
      check_passed = false;
      --goto continue
    else
      --print('fillrate is '..self.propsA.area / vcm.bboxArea(self.propsA.boundingBox))
      local fill_rate = self.propsA.area / vcm.bboxArea(self.propsA.boundingBox);
--JZ      p_vision:add_debug_message(string.format("Area:%d\nFill rate:%2f\n",
--      self.propsA.area,fill_rate));
      -- diameter of the area
      local dArea = math.sqrt((4/math.pi)* self.propsA.area);
      -- Find the centroid of the ball
      local ballCentroid = self.propsA.centroid;
      -- Coordinates of ball
      local scale = math.max(dArea/self.diameter, self.propsA.axisMajor/self.diameter);
      v = HeadTransform.coordinatesA(ballCentroid, scale);
      v_inf = HeadTransform.coordinatesA(ballCentroid,0.1);
      
      --p_vision:add_debug_message(string.format("Ball v0: %.2f %.2f %.2f\n",v[1],v[2],v[3]));

      --Global ball position check
      pose = wcm.get_pose();
      posexya=vector.new( {pose.x, pose.y, pose.a} );
      ballGlobal=util.pose_global({v[1],v[2],0},posexya);
      pos_check_fail = false;

      if ballGlobal[1]>Config.world.xMax * self.fieldsize_factor or
         ballGlobal[1]<-Config.world.xMax * self.fieldsize_factor or
         ballGlobal[2]>Config.world.yMax * self.fieldsize_factor or
         ballGlobal[2]<-Config.world.yMax * self.fieldsize_factor then
         pos_check_fail = false;
         --p_vision:add_debug_message("On-the-field check fail\n");
      end
-----------------------------------------------------------------------
      local exp_area = 200.19 * (v[1]*v[1] + v[2]*v[2])^-1.121
      local area_diff = math.abs(exp_area - self.propsA.area)
      local area_diff_error = 0.2 * (exp_area^2)
      local cidx = p_vision.camera_index;
      if area_diff > area_diff_error and cidx == 1 then
        --print('the area_diff is '..area_diff)
        --print('the area_diff error is'..area_diff_error)
        --print('\n...........\n')
        p_vision:add_debug_message('Calculated area diff check fail\n')
        check_passed = false;
        --goto continue
      end
----------------------------------------------------------------------
      if pos_check_fail and
         (v[1]*v[1] + v[2]*v[2] > self.max_distance*self.max_distance) then
 	--Only check distance if the ball is out of field
        --p_vision:add_debug_message("Distance check fail\n");
        check_passed = false;
        --goto continue
      elseif v[3] + 0.7 > self.th_height_max then
        --Ball height check
        p_vision:add_debug_message("Height check fail\n");
        check_passed = false;
        --goto continue
      elseif check_for_ground>0  then
        -- ground check
        -- is ball cut off at the bottom of the image?
        local vmargin=p_vision.labelA.n-ballCentroid[2];
        --p_vision:add_debug_message("Bottom margin check\n");
--JZ        p_vision:add_debug_message(string.format( "lableA height: %d, centroid Y: %d diameter: %.1f\n",
--JZ  	                                              p_vision.labelA.n, ballCentroid[2], dArea ));
        --When robot looks down they may fail to pass the green check
        --So increase the bottom margin threshold
        if vmargin > dArea * 2.0 then
          -- bounding box below the ball
          local fieldBBox = {};
          fieldBBox[1] = ballCentroid[1] + self.th_ground_boundingbox[1];
          fieldBBox[2] = ballCentroid[1] + self.th_ground_boundingbox[2];
          fieldBBox[3] = ballCentroid[2] + .5*dArea + self.th_ground_boundingbox[3];
          fieldBBox[4] = ballCentroid[2] + .5*dArea + self.th_ground_boundingbox[4];
          -- color stats for the bbox
          local fieldBBoxStats = ImageProc.color_stats(p_vision.labelA.data, 
  	                            p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox);
          -- is there green under the ball?
--JZ          p_vision:add_debug_message(string.format("Green check:%d %d\n", fieldBBoxStats.area, self.th_min_green1));
          if (fieldBBoxStats.area < self.th_min_green1) then
            -- if there is no field under the ball 
      	    -- it may be because its on a white line
            local whiteBBoxStats = ImageProc.color_stats(p_vision.labelA.data,
 	                              p_vision.labelA.m, p_vision.labelA.n, Config.color.white, fieldBBox);
            if (whiteBBoxStats.area < self.th_min_green2) then
              p_vision:add_debug_message(string.format("Green check fail %d %d\n", whiteBBoxStats.area, self.th_min_green2));
              check_passed = false;
              --goto continue
            end
          end --end white line check
        end --end bottom margin check
      end --End ball height, ground check
--------------------------------------------
        -- pink check
        self.pink = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, 
                                        p_vision.labelA.n, self.jersey, bboxA);
        --print('Pink area is '..self.pink.area)
       local fill_rate_pink = self.pink.area / vcm.bboxArea(self.propsA.boundingBox);
       local cidx = p_vision.camera_index;
       local exp_fillrate = 100*0.0461*(v[1]*v[1]+v[2]*v[2])^0.4192;
      -- local exp_fillrate = 0.0375*math.log(v[1]*v[1]+v[2]*v[2])+0.0369;
       local fillrate_diff = math.abs(fill_rate_pink - exp_fillrate);
       local fillrate_err = .3 * (exp_fillrate);
      --print('fill_rate_pink is'..fill_rate_pink..'\n')
        --print('exp_rate is'..exp_fillrate..'\n') 
      if fill_rate_pink > self.th_max_fill_rate_pink[cidx] and false then
         p_vision:add_debug_message('Too much pink in the area\n');
         check_passed = false;
        -- print('unpass fillrate is'..fill_rate_pink..'\n')
         --goto continue
      end 

      if fillrate_diff > fillrate_err and cidx == 1 and false then
        -- print('pink fillrate fails\n')
         --print('unpass fillrate_diff is'..fillrate_diff..'\n')
         --print('unpass exp_fillrate is'..exp_fillrate..'\n')
         --print('unpass fillrate_err is'..fillrate_err..'\n')
         check_passed = false;
         --goto continue
      end
       
      if check_passed then

      --print('height of the robot is '..v[3]+0.7)
       -- print('pass fill_rate_pink is'..fill_rate_pink..'\n')
       -- print('pass exp_fillrate is'..exp_fillrate..'\n')
       -- print('fillrate_err is'..fillrate_err..'\n')
        -- print('pass fillrate_err is'..fillrate_err..'\n')
        -- print('pass distance is'..v[1]*v[1]+v[2]*v[2]..'\n')
      end--
--------------------------------------------
    end --End all check

    if check_passed then
    
      local ballv = {v[1],v[2],0};
--      local ballv = {v_inf[1],v_inf[2],0};
      pose=wcm.get_pose();
      posexya=vector.new( {pose.x, pose.y, pose.a} );
      ballGlobal = util.pose_global(ballv,posexya); 
      if check_for_field>0 then
        if math.abs(ballGlobal[1]) > Config.world.xLineBoundary + field_margin or
          math.abs(ballGlobal[2]) > Config.world.yLineBoundary + field_margin then
          --p_vision:add_debug_message("Field check fail\n");
          check_passed = false;
          --goto continue
        end
      end
    end
    if check_passed then
        --print('Height of ball '..v[3])
        --print('Current distance from ball is '..(v[1]*v[1] + v[2]*v[2])..self.max_distance)

        print('Current area of ball is '..self.propsA.area) 
        break;
    end
    --::continue::
  end --End loop

  if not check_passed then
    return
  end
  
  --SJ: Projecting ball to flat ground makes large distance error
  --We are using declined plane for projection

  local vMag =math.max(0,math.sqrt(v[1]^2+v[2]^2)-0.50);
  local bodyTilt = vcm.get_camera_bodyTilt();
--  print("BodyTilt:",bodyTilt*180/math.pi)
  local projHeight = vMag * math.tan(10*math.pi/180);


  local v=HeadTransform.projectGround(v,self.diameter/2-projHeight);

  --SJ: we subtract foot offset 
  --bc we use ball.x for kick alignment
  --and the distance from foot is important
  v[1]=v[1]-mcm.get_footX()

  local ball_shift = Config.ball_shift or {0,0};
  --Compensate for camera tilt
  v[1]=v[1] + ball_shift[1];
  v[2]=v[2] + ball_shift[2];

  --Ball position ignoring ball size (for distant ball observation)
  local v_inf=HeadTransform.projectGround(v_inf,self.diameter/2);
  v_inf[1]=v_inf[1]-mcm.get_footX()
  wcm.set_ball_v_inf({v_inf[1],v_inf[2]});  

  self.v = v;
--print('height', v[3])
--print('fillrate', temp_fillrate)
print('aspect', aspect_ratio)
  self.detect = 1;
  self.r = math.sqrt(self.v[1]^2 + self.v[2]^2);

  -- How much to update the particle filter
  self.dr = 0.25*self.r;
  self.da = 10*math.pi/180;

 -- p_vision:add_debug_message(string.format(
--	"Ball detected\nv: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
--[[
  print(string.format(
	"Ball detected\nv: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
--]]
  return
end

local update_shm = function(self, p_vision)
  local cidx = p_vision.camera_index
  vcm['set_ball'..cidx..'_detect'](self.detect);
  if (self.detect == 1) then
    vcm['set_ball'..cidx..'_color_count'](self.color_count);
    vcm['set_ball'..cidx..'_centroid'](self.propsA.centroid);
    vcm['set_ball'..cidx..'_axisMajor'](self.propsA.axisMajor);
    vcm['set_ball'..cidx..'_axisMinor'](self.propsA.axisMinor);
    vcm['set_ball'..cidx..'_v'](self.v);
    vcm['set_ball'..cidx..'_r'](self.r);
    vcm['set_ball'..cidx..'_dr'](self.dr);
    vcm['set_ball'..cidx..'_da'](self.da);
  end
  --[[
  vcm.set_ball_detect(self.detect);
  if (self.detect == 1) then
    vcm.set_ball_color_count(self.color_count);
    vcm.set_ball_centroid(self.propsA.centroid);
    vcm.set_ball_axisMajor(self.propsA.axisMajor);
    vcm.set_ball_axisMinor(self.propsA.axisMinor);
    vcm.set_ball_v(self.v);
    vcm.set_ball_r(self.r);
    vcm.set_ball_dr(self.dr);
    vcm.set_ball_da(self.da);
  end
  --]]
end


local detectBall = {}

function detectBall.entry(parent_vision)
  print('init Corner detection')
  local cidx = parent_vision.camera_index;
  local self = {}
  self.update = update
  self.update_shm = update_shm
  self.detect = 0

  self.diameter = Config.vision.ball.diameter;
  self.th_min_color=Config.vision.ball.th_min_color[cidx];
  self.th_min_color2=Config.vision.ball.th_min_color2[cidx];
  self.th_max_color3=Config.vision.ball.th_max_color3[cidx];
  self.th_min_fill_rate=Config.vision.ball.th_min_fill_rate;
  self.th_height_max=Config.vision.ball.th_height_max;
  self.th_ground_boundingbox=Config.vision.ball.th_ground_boundingbox[cidx];
  self.th_min_green1=Config.vision.ball.th_min_green1[cidx];
  self.th_min_green2=Config.vision.ball.th_min_green2[cidx];
  self.th_headAngle = Config.vision.ball.th_headAngle or -10*math.pi/180;
  self.max_distance = Config.vision.ball.max_distance or 7.0;
  self.fieldsize_factor = Config.vision.ball.fieldsize_factor or 2.0;
  self.th_max_fill_rate_pink = Config.vision.ball.th_max_fill_rate_pink;
  self.jersey = Config.vision.ball.pink;



  return self
end

return detectBall
