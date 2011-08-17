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

headZ = Config.head.camOffsetZ;

function detect()
  --TODO: test line detection
  line = {};
  line.detect = 0;

  if (Vision.colorCount[colorWhite] < 200) then 
    --print('under 200 white pixels');
    return line;
  end
  if (Vision.colorCount[colorField] < 5000) then 
    --print('under 5000 green pixels');
    return line; 
  end

  --max width 8
  linePropsB = ImageProc.field_lines(Vision.labelB.data, Vision.labelB.m, Vision.labelB.n, 8); 
  if (not linePropsB) then 
    --print('linePropsB nil')
    return line; 
  end
  if (linePropsB.count < 15) then 
    --print('linePropsB count under 15: '..linePropsB.count)
    return line; 
  end
  line.propsB = linePropsB;

  local vendpoint = {};
  vendpoint[1] = HeadTransform.coordinatesB(vector.new({linePropsB.endpoint[1], linePropsB.endpoint[3]}));
  vendpoint[2] = HeadTransform.coordinatesB(vector.new({linePropsB.endpoint[2], linePropsB.endpoint[4]}));

  -- height check
  if (vendpoint[1][3] >= 0.3 or vendpoint[2][3] >= 0.3) then 
    --print('failed head check');
    return line; 
  end 

  if (vendpoint[1][3] < -headZ) then
    vendpoint[1] = (-headZ/vendpoint[1][3])*vendpoint[1];
  end
  if (vendpoint[2][3] < -headZ) then
    vendpoint[2] = (-headZ/vendpoint[2][3])*vendpoint[2];
  end

  line.angle = math.atan2(vendpoint[2][2] - vendpoint[1][2], vendpoint[2][1] - vendpoint[1][1]);
  vcentroid = HeadTransform.coordinatesB(linePropsB.centroid, 1);

  -- Project to ground plane
  if (vcentroid[3] < -headZ) then
    vcentroid = (-headZ/vcentroid[3])*vcentroid;
  end

  line.v = vcentroid;
  line.vcentroid = vcentroid;
  line.vendpoint = vendpoint;
  --print('detected line: '..line.v[1]..', '..line.v[2]);

  line.detect = 1;
  return line;
end
