require('Config');	-- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');	-- For Projection

use_point_goal=Config.vision.use_point_goal;
headInverted=Config.vision.headInverted;
min_area = Config.vision.spot.min_area or 5;
max_area = Config.vision.spot.max_area or 200;
aspect_ratio = Config.vision.spot.aspect_ratio or 0.5;
ground_boundingbox = Config.vision.spot.ground_boundingbox;
ground_th = Config.vision.spot.ground_th;
field_color = Config.color.field;
max_black_rate_B = Config.vision.spot.max_black_rate_B;
max_black_rate_A = Config.vision.spot.max_black_rate_A;

local update = function(self, color, p_vision)
  self.detect = 0;
  local spotPropsB = ImageProc.field_spots(p_vision.labelB.data, p_vision.labelB.m, p_vision.labelB.n, min_area);
  if (not spotPropsB) then 
    p_vision:add_debug_message("No Spot detected\n") 
    return; 
  end
  local function compare_spot_area(spot1, spot2)
    return spot1.area > spot2.area
  end
  table.sort(spotPropsB, compare_spot_area)
  for i = 1,#spotPropsB do
    local valid = true;
    p_vision:add_debug_message(string.format("Spot %d: l=%d; r=%d; t=%d; b=%d\n",
      i,spotPropsB[i].boundingBox[1],spotPropsB[i].boundingBox[2],
      spotPropsB[i].boundingBox[3],spotPropsB[i].boundingBox[4]))
    local bboxB = spotPropsB[i].boundingBox;
    local bboxA = vcm.bboxB2A(bboxB, p_vision.scaleB);
    spotStats = ImageProc.color_stats(p_vision.labelA.data, 
      p_vision.labelA.m, p_vision.labelA.n, color, bboxA);
    spotStats_black = ImageProc.color_stats(p_vision.labelA.data, 
      p_vision.labelA.m, p_vision.labelA.n, Config.color.orange, bboxA);
    local spotArea = vcm.bboxArea(bboxB);
    local spotArea_A = vcm.bboxArea(bboxA);
    local aspect_th = aspect_ratio;
    if spotArea > max_area then
      p_vision:add_debug_message(string.format(
        "Spot large: %d > %d\n",spotArea,max_area));
      aspect_th = aspect_ratio*1.25;      
    end

    if valid then
      local black_stats = ImageProc.color_stats(p_vision.labelB.data, p_vision.labelB.m, p_vision.labelB.n, Config.color.orange, bboxB);
      local black_rate = black_stats.area / spotArea;
      if black_rate > max_black_rate_B then
        p_vision:add_debug_message(string.format("Black rate B fail: %.2f > %.2f\n", black_rate, max_black_rate_B));
        valid = false;
      end

      local black_rate_A = spotStats_black.area / spotArea_A;
      if black_rate_A > max_black_rate_A then
        p_vision:add_debug_message(string.format("Black rate A fail: %.2f > %.2f\n", black_rate_A, max_black_rate_A));
        valid = false;
      end

      p_vision:add_debug_message(string.format("Black rate: B = %.2f A = %.2f\n", black_rate, black_rate_A));

    end
    
    if valid then
      local ratio = spotStats.axisMinor/spotStats.axisMajor;
      if ratio < aspect_th then
        p_vision:add_debug_message(string.format(
          "aspect check fail: %.2f < %.2f\n",ratio,aspect_th));
        valid = false;
      end
    end

    -- get rid of this and just do green checks in all directions
    if valid then
      local horizon=HeadTransform.get_horizonB();
      if bboxB[3] < horizon then
        p_vision:add_debug_message(string.format(
          "horizon check failed: %d < %d\n", bboxB[3], horizon))
        valid = false;
      end
    end

    if valid then
      local groundbbox = {} 
        groundbbox[1]=math.max(bboxA[1]+ground_boundingbox[1],0);
        groundbbox[2]=math.min(bboxA[2]+ground_boundingbox[2],p_vision.labelA.m-1);
        groundbbox[3]=math.max(bboxA[3]+ground_boundingbox[3],0);
        groundbbox[4]=math.min(bboxA[4]+ground_boundingbox[4],p_vision.labelA.n-1);
      local groundstats=ImageProc.color_stats(p_vision.labelA.data, 
        p_vision.labelA.m, p_vision.labelA.n, field_color, groundbbox);
      local ambientarea = vcm.bboxArea(groundbbox)-vcm.bboxArea(bboxA);
      green_ratio = groundstats.area/ambientarea;
      if green_ratio < ground_th then
        p_vision:add_debug_message(string.format(
          "Ground check fail %.2f<%.2f\n",green_ratio,ground_th));
        valid = false;
      end
    end

    if valid then
      if bboxA[3] < 15 then
        p_vision:add_debug_message("Spot too high, could be robot's foot.\n");
        valid = false;
      end
    end

    if valid then
      if vcm.bboxArea(bboxA) > 1100 then
        p_vision:add_debug_message(string.format("Spot too large: %.2f > %.2f\n", vcm.bboxArea(bboxA), 1100));
        valid = false;
      end
    end
    
    if valid then
      self.propsB = spotPropsB[i];
      self.propsA = spotStats;
      self.bboxB = bboxB;
      self.detect = 1;
      local	vcentroid = HeadTransform.coordinatesA(spotStats.centroid, 1);
      vcentroid = HeadTransform.projectGround(vcentroid,0);
      -- vcentroid[4] = 1;
      self.v = vcentroid;
      p_vision:add_debug_message(string.format("Spot detected: (%.2f %.2f)\n", self.v[1],self.v[2]))     
      return self;
    end
  end
    -- get the color statistics of the region (in the large size image)

  -- check the major and minor axes
  -- the spot is symmetrical so the major and minor axes should be the same
  --debugprint('Spot: checking ratio');
  return
end

local detectSpot = {}

local update_shm = function(self, parent_vision)
  vcm.set_spot_detect(self.detect)
  if self.detect == 1 then
    vcm.set_spot_v(self.v)
    vcm.set_spot_bboxB(self.bboxB);
    vcm.set_spot_color(Config.color.white)
  end
end

function detectSpot.entry(parent_vision)
  print('init Spot detection')
  local self = {}
  self.update = update
  self.update_shm = update_shm
  self.detect = 0

  return self
end

return detectSpot
