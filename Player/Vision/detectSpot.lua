module(..., package.seeall);

require('Config');	-- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');	-- For Projection
require('Vision');

-- Dependency
require('Detection');


-- Define Color
colorOrange = 1;
colorYellow = 2;
colorCyan = 4;
colorField = 8;
colorWhite = 16;

use_point_goal=Config.vision.use_point_goal;
headInverted=Config.vision.headInverted;

function detect()
  --TODO: test spot detection

  spot = {};
  spot.detect = 0;

  if (Vision.colorCount[colorWhite] < 100) then 
    return spot; 
  end
  if (Vision.colorCount[colorField] < 5000) then 
    return spot; 
  end

  local spotPropsB = ImageProc.field_spots(Vision.labelB.data, Vision.labelB.m, Vision.labelB.n);
  if (not spotPropsB) then 
    return spot; 
  end
  spot.propsB = spotPropsB[1];
  if (spot.propsB.area < 6) then 
    return spot;
  end

  -- get the color statistics of the region (in the large size image)
  local spotStats = Vision.bboxStats(colorWhite, spot.propsB.boundingBox);

  -- check the major and minor axes
  -- the spot is symmetrical so the major and minor axes should be the same
  --debugprint('Spot: checking ratio');

  if (spotStats.axisMinor < .2*spotStats.axisMajor) then
    return spot;
  end
  spot.propsA = spotStats;

  local	vcentroid = HeadTransform.coordinatesA(spotStats.centroid, 1);
  vcentroid = HeadTransform.projectGround(vcentroid,0);
  vcentroid[4] = 1;
  spot.v = vcentroid;
  --debugprint('Spot found');

  spot.detect = 1;
  return spot;
end
