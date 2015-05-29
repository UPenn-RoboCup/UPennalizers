require('Config');      -- For Ball and Goal Size require('ImageProc');
require('HeadTransform');       -- For Projection
require('Body');
require('vcm');
require('mcm');

bottom_boudary_check = Config.vision.ball.bottom_boudary_check or 0
check_for_ground = Config.vision.ball.check_for_ground;
check_for_field = Config.vision.ball.check_for_field or 0;
field_margin = Config.vision.ball.field_margin or 0;


---Detects a ball of a given color.
--@param color The color to use for detection, represented by an int
--@return Table containing whether a ball was detected
--If a ball is detected, also contains additional stats about the ball
local update = function(self, color, p_vision)
  local colorCount = p_vision.colorCount;
  headAngle = Body.get_head_position();
  local top_camera = false  
  self.detect = 0;
  --p_vision:add_debug_message(string.format("\nBall %d: pixel count: %d\n", p_vision.camera_index,
--JZ    colorCount[color] ));
--  print(string.format("\nBall: pixel count: %d\n", colorCount[color]));

  -- threshold check on the total number of ball pixels in the image
  --if (colorCount[color] < self.th_min_color) then  	
  --  p_vision:add_debug_message("pixel count fail");
  --  return
  --end
  self.color_count = colorCount[color];
  -- find connected components of ball pixels
  local ballPropsB
  if p_vision.camera_index==1 then top_camera=true end

  ballPropsB = ImageProc.connected_regions(  
    p_vision.labelB.data, p_vision.labelB.m, 
    p_vision.labelB.n, color);
  if (not ballPropsB or #ballPropsB == 0) then return end

  if top_camera then 
    p_vision:add_debug_message('===Top Ball check===\n')
  else 
    p_vision:add_debug_message('===Bottom Ball check===\n') 
  end
  local check_passed
-- Check all blobs until hit a ball that no longer passes area check 
 
  if top_camera==false then
          --the number is PURELY a hack --Dickens
    horizonboundary = math.max(math.min(1.2*(math.abs(headAngle[1])-0.5),1),0)
    bottomboundary = math.max(0, -1.9*headAngle[2])*p_vision.labelA.n
    if headAngle[1] > 0 then
      leftboundary = horizonboundary*p_vision.labelA.m
      rightboundary = p_vision.labelA.m
    else
      leftboundary = 0
      rightboundary = (1-horizonboundary)*p_vision.labelA.m   
    end
    if(math.abs(headAngle[1])>math.pi/3) then
      print("L vs R vs B: "..leftboundary.." "..rightboundary.." "..bottomboundary)
    end
  end
  for i=1,#ballPropsB do
    check_passed = true;
    if check_passed then
-- Add one more check to filter out jersey ball on bottom camera
      p_vision:add_debug_message(string.format("Ball: checking blob %d/%d\n",i,#ballPropsB));

      self.propsB = ballPropsB[i];
      local bboxA = vcm.bboxStats(color, ballPropsB[i].boundingBox, _, p_vision.scaleB);
      self.propsA = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, 
                                          p_vision.labelA.n, color, bboxA);
      self.bboxA = vcm.bboxB2A(ballPropsB[i].boundingBox, p_vision.scaleB);
      if top_camera == false and bottom_boudary_check == 1 then
        if math.abs(headAngle[1])>math.pi/3 then
          if (self.propsA.centroid[1]<leftboundary or self.propsA.centroid[2]>rightboundary)
            and self.propsA.centroid[2]>bottomboundary then
            check_passed = false
            print ("boundary problem!!")
            print ("centroid: "..self.propsA.centroid[1].." "..self.propsA.centroid[2].."\n") 
          end
        end 
      end
      
      local fill_rate = self.propsA.area / vcm.bboxArea(self.propsA.boundingBox)
      local aspect_ratio = self.propsA.axisMajor / self.propsA.axisMinor
      if (self.propsA.axisMinor == 0) then aspect_ratio = self.propsA.axisMajor / 0.00001 end
          
      if self.propsA.area > self.th_max_color2 then  --Max color check 
        p_vision:add_debug_message('Ball area '..self.propsA.area..'>'..self.th_max_color2..' fail\n');
        check_passed = false;        
      elseif self.propsA.area < self.th_min_color2 then --Min color check
        p_vision:add_debug_message('Ball area '..self.propsA.area..'<'..self.th_min_color2..' fail\n');      
        check_passed = false;        
--        print('min area failed '..self.propsA.area..' minimum was '..self.th_min_color2)
      elseif fill_rate < self.th_min_fill_rate then      --Fill rate check
        p_vision:add_debug_message('Fill rate'..fill_rate..'<'..self.th_min_fill_rate..' fail\n')
        check_passed = false;      
      else
        --Now we have somewhat solid blob somewhere. Get the position of it
        local dArea = math.sqrt((4/math.pi)* self.propsA.area);-- diameter of the area
        local ballCentroid = self.propsA.centroid;-- Find the centroid of the ball
        local scale = math.max(dArea/self.diameter, self.propsA.axisMajor/self.diameter)
        v = HeadTransform.coordinatesA(ballCentroid, scale) -- Coordinates of ball
        v_inf = HeadTransform.coordinatesA(ballCentroid,0.1) --far-projected coordinate of the ball 
        p_vision:add_debug_message(string.format("Ball v0: %.2f %.2f %.2f\n",v[1],v[2],v[3]));  
        if top_camera and check_passed then
            --Horizon check
          --print('passed ball: '..math.sqrt(v[1]*v[1] + v[2]*v[2])..' height is '..v[3])
          -- Distance - height check
          exp_height = 0.0764*math.sqrt(v[1]*v[1] + v[2]*v[2])
          height_diff = math.abs(v[3] - exp_height)
          local height_err = 0.20 
          if math.abs(v[3]) > exp_height and false then
             -- print('reached new distance height check')
             -- print('distance is'..math.sqrt(v[1]*v[1] + v[2]*v[2]))
             -- print('height diff '..height_diff..' height err is '..height_err)
              p_vision:add_debug_message('Height-distance check fail\n')
              check_passed=false;
          else
             -- print('height_diff passed'..height_diff)
          end    
          ball_dist_inf = math.sqrt(v_inf[1]*v_inf[1] + v_inf[2]*v_inf[2])
          height_th_inf = self.th_height_max + ball_dist_inf * math.tan(10*math.pi/180)
          if v_inf[3] > height_th_inf then        
             p_vision:add_debug_message(string.format('Horizon check fail, %.2f>%.2f\n',v_inf[3],height_th_inf));
             check_passed = false;
          end

          --Global ball position check
          pose = wcm.get_pose();
          posexya=vector.new( {pose.x, pose.y, pose.a} );
          ballGlobal=util.pose_global({v[1],v[2],0},posexya);
          if ballGlobal[1]>Config.world.xMax * self.fieldsize_factor or
             ballGlobal[1]<-Config.world.xMax * self.fieldsize_factor or
             ballGlobal[2]>Config.world.yMax * self.fieldsize_factor or
             ballGlobal[2]<-Config.world.yMax * self.fieldsize_factor then
            if (v[1]*v[1] + v[2]*v[2] > self.max_distance*self.max_distance) then          
              p_vision:add_debug_message("On-the-field check fail\n");
              check_passed = false;
            end
          end
          --Ball height check
          local ball_dist = math.sqrt(v[1]*v[1] + v[2]*v[2])
          local height_th = self.th_height_max + ball_dist * math.tan(8*math.pi/180)
          if check_passed and v[3] > 0.3 then
               -- print('v3 is '..v[3])
               -- print('reached')
               check_passed = false
          end
         -- local height_th = self.th_height_max + ball_dist * math.tan(3*math.pi/180)
         -- if check_passed and v[3] > 0.07 then
         --       check_passed = false
         -- end 
          
          p_vision:add_debug_message(string.format('Height check: %.2f / %.2f\n',v[3],height_th))
          if check_passed and v[3] > height_th then
            p_vision:add_debug_message(string.format('Height check fail\n',v[3],height_th))
            check_passed = false;      
          elseif check_for_ground>0  then  -- ground check
            -- is ball cut off at the bottom of the image?
            local vmargin=p_vision.labelA.n-ballCentroid[2];
            if vmargin > dArea * 2.0 then  -- bounding box below the ball
              local fieldBBox = {};
              fieldBBox[1] = ballCentroid[1] + self.th_ground_boundingbox[1];
              fieldBBox[2] = ballCentroid[1] + self.th_ground_boundingbox[2];
              fieldBBox[3] = ballCentroid[2] + .5*dArea + self.th_ground_boundingbox[3];
              fieldBBox[4] = ballCentroid[2] + .5*dArea + self.th_ground_boundingbox[4];
              -- color stats for the bbox
              local fieldBBoxStats = ImageProc.color_stats(p_vision.labelA.data, 
                                    p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox);
              p_vision:add_debug_message(string.format("Green check:%d %d\n", fieldBBoxStats.area, self.th_min_green1));
              if (fieldBBoxStats.area < self.th_min_green1) then
                -- if there is no field under the ball 
                -- it may be because its on a white line
                local whiteBBoxStats = ImageProc.color_stats(p_vision.labelA.data,
                                    p_vision.labelA.m, p_vision.labelA.n, Config.color.white, fieldBBox);
                if (whiteBBoxStats.area < self.th_min_green2) then
                  p_vision:add_debug_message(string.format("Green check fail %d %d\n", whiteBBoxStats.area, self.th_min_green2));
                  check_passed = false;
                end
              end --end white line check
            end --end bottom margin check
          end --End ball height, ground check
        end --End top camera check
          --print('reached for cam') 
        if check_passed then          --Pink check (ball in jersey)
          self.pink = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, 
                                           p_vision.labelA.n, self.jersey, bboxA);
       -- print(self.pink.area..'is the pink pixels')
          local fill_rate_pink = self.pink.area / vcm.bboxArea(self.propsA.boundingBox);
          local cidx = p_vision.camera_index;
          local exp_fillrate = 100*0.0461*(v[1]*v[1]+v[2]*v[2])^0.4192;
          local fillrate_diff = math.abs(fill_rate_pink - exp_fillrate);
          local fillrate_err = .3 * (exp_fillrate);       
          if fill_rate_pink > self.th_max_fill_rate_pink[cidx] then
           -- print('fill_rate_pink is '..fill_rate_pink..' and max allowed is '..self.th_max_fill_rate_pink[cidx])
           -- print('fill_rate_pink test failed')
            p_vision:add_debug_message('Pink fillrate '..fill_rate_pink..'>'..self.th_max_fill_rate_pink[cidx]..'\n');
            check_passed = false; 
          elseif fillrate_diff > fillrate_err and cidx == 1 and false then
            print('fillrate_diff is '..fillrate_diff..' and the fillrate_err '..fillrate_err)        
            p_vision:add_debug_message('Pink fillrate diff'
                 ..fillrate_diff..'>'..fillrate_err..'\n');          
            check_passed = false;
          else
            --print('passed all tests')
          end    
        end
        if check_passed == true and top_camera then
         -- print('height'..v[3]..'allowed'..exp_height)
         -- print('distance'..math.sqrt(v[1]*v[1]+v[2]*v[2]))
        end
      end --End all check    
    end --End top camera          
    if check_passed then break end
  end --End propsB loop
  if not check_passed then return end

  --SJ: we subtract foot offset 
  --bc we use ball.x for kick alignment
  --and the distance from foot is important
  v[1]=v[1]-mcm.get_footX()
  local ball_shift = Config.ball_shift or {0,0}   --Compensate for camera tilt
  v[1]=v[1] + ball_shift[1]
  v[2]=v[2] + ball_shift[2]

  --Ball position ignoring ball size (for distant ball observation)
  local v_inf=HeadTransform.projectGround(v_inf,self.diameter/2);
  v_inf[1]=v_inf[1]-mcm.get_footX()
  wcm.set_ball_v_inf({v_inf[1],v_inf[2]});  

  self.v = v;
  self.detect = 1;
  self.r = math.sqrt(self.v[1]^2 + self.v[2]^2);

  -- How much to update the particle filter
  self.dr = 0.25*self.r;
  self.da = 10*math.pi/180;

  p_vision:add_debug_message(string.format("Ball detected\nv: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
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
  self.th_max_color2=Config.vision.ball.th_max_color2[cidx];
  self.th_min_fill_rate=Config.vision.ball.th_min_fill_rate;
  self.th_height_max=Config.vision.ball.th_height_max;
  self.th_ground_boundingbox=Config.vision.ball.th_ground_boundingbox[cidx];
  self.th_min_green1=Config.vision.ball.th_min_green1[cidx];
  self.th_min_green2=Config.vision.ball.th_min_green2[cidx];
  self.th_headAngle = Config.vision.ball.th_headAngle or -10*math.pi/180;
  self.max_distance = Config.vision.ball.max_distance or 2.5;
  self.fieldsize_factor = Config.vision.ball.fieldsize_factor or 2.0;
  self.th_max_fill_rate_pink = Config.vision.ball.th_max_fill_rate_pink;
  self.jersey = Config.vision.ball.pink;
  return self
end

return detectBall
