require('Config');	-- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');	-- For Projection

use_point_goal=Config.vision.use_point_goal;
headInverted=Config.vision.headInverted;

local debug = false

local update = function(self, color, p_vision)
  self.detect = 0;

  --[[
  if (p_vision.colorCount[Config.color.white] < 100) then 
    return; 
  end
  if (p_vision.colorCount[Conig.color.field] < 5000) then 
    return; 
  end
  --]]
  local spotPropsB = ImageProc.field_spots(p_vision.labelB.data, p_vision.labelB.m, p_vision.labelB.n);
  if (not spotPropsB) then 
    if debug then
      print('NO SPOT DETECTED')
    end
    return; 
  end
  self.propsB = spotPropsB[1];
  if (self.propsB.area < 6) then 
    if debug then
      print('AREA CHECK FAIL')
    end
    return;
  end

  -- get the color statistics of the region (in the large size image)
  local bboxA = vcm.bboxStats(Config.color.white, self.propsB.boundingBox, _, p_vision.scaleB);
  spotStats = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, 
                                        p_vision.labelA.n, color, bboxA);

  -- check the major and minor axes
  -- the spot is symmetrical so the major and minor axes should be the same
  --debugprint('Spot: checking ratio');

  if (spotStats.axisMinor < .2*spotStats.axisMajor) then
    if debug then
      print('ASPECT RATIO CHECK FAIL')
    end
    return;
  end
  self.propsA = spotStats;

  local	vcentroid = HeadTransform.coordinatesA(spotStats.centroid, 1);
  vcentroid = HeadTransform.projectGround(vcentroid,0);
  vcentroid[4] = 1;
  self.v = vcentroid;
  if debug then
     print('SPOT:', self.v)
  end
  --debugprint('Spot found');

  self.detect = 1;
  if debug then
    print('SPOT DETECTED!!')
  end
  return self
end

local detectSpot = {}

local update_shm = function(self, parent_vision)
  vcm.set_landmark_detect(self.detect)
  if self.detect == 1 then
    vcm.set_landmark_v(self.v)
    vcm.set_landmark_color(Config.color.white)
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
