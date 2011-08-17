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

function detect(color1, color2)
  --Detection code for center landmark poles

  local landmark = {}
  landmark.detect = 0;

  if (colorCount[color1] < 12) then 
    return spot; 
  end
  if (colorCount[color2] < 6) then 
    return spot; 
  end

  landmarkPropsB1= ImageProc.connected_regions(labelB.data, labelB.m, labelB.n, color1);
  landmarkPropsB2= ImageProc.connected_regions(labelB.data, labelB.m, labelB.n, color2);

  if (#landmarkPropsB1 < 2 or #landmarkPropsB2 < 1) then 
    return landmark; 
  end

  landmark.propsA1= bboxStats(color1, landmarkPropsB1[1].boundingBox);
  landmark.propsA2= bboxStats(color2, landmarkPropsB2[1].boundingBox);
  landmark.propsA3= bboxStats(color1, landmarkPropsB1[2].boundingBox);
  --debugprint('Landmark: connected region area check\n')

  local dArea1 = landmark.propsA1.area;
  local dArea2 = landmark.propsA2.area;
  local dArea3 = landmark.propsA3.area;        

  --Area check
  if (dArea1 < 6 or dArea2 < 6 or dArea3 < 6) then 
    return landmark; 
  end
  --Area ratio check
  if (dArea1/dArea2 > 2 or dArea2/dArea1>2) then 
    return landmark;
  end
  if (dArea2/dArea3 > 2 or dArea3/dArea2>2) then 
    return landmark;
  end
  if (dArea1/dArea3 > 2 or dArea3/dArea1>2) then 
    return landmark;
  end

  --Fill rate check

  --debugprint('Landmark: connected region fill extent check\n')
  --Config.vision.landmarkfillextent

  if (dArea1 < Config.vision.landmarkfillextent * bboxArea(landmark.propsA1.boundingBox))	then 
    return landmark;
  end

  if (dArea2 < Config.vision.landmarkfillextent * bboxArea(landmark.propsA2.boundingBox))	then 
    return landmark;
  end

  if (dArea3 < Config.vision.landmarkfillextent * bboxArea(landmark.propsA3.boundingBox))	then 
    return landmark;
  end


  local landmarkCentroid1 = landmark.propsA1.centroid;
  local landmarkCentroid2 = landmark.propsA2.centroid;
  local landmarkCentroid3 = landmark.propsA3.centroid;    
  local a21 = landmarkCentroid2 - landmarkCentroid1;
  local a32 = landmarkCentroid3 - landmarkCentroid2;
  local d21 = math.sqrt(a21[1]^2 + a21[2]^2);
  local d32 = math.sqrt(a32[1]^2 + a32[2]^2);

  --Distance ratio check
  if (d21/d32 > 2.0 or d32/d21 > 2.0) then
    return landmark;
  end

  --Center angle check
  local cosvalue = (a21[1]*a32[1] + a21[2]*a32[2])/d21/d32;
  if cosvalue < math.cos(45*math.pi/180) then 
    return landmark;
  end

  --Do we need all those checks?
  --[[ this is matlab code
  -- tilt check
  if abs(landmark.propsA1.orientation) < 60*pi/180, return;end
  a1=landmarkCentroid1-landmarkCentroid2;
  a2=landmarkCentroid2-landmarkCentroid3;    
  a3=landmarkCentroid1-landmarkCentroid3;
  debugprint('Landmark orientation check\n');

  if atan2(abs(a3(1)),abs(a3(2)))>VISIONDATA.landmarkorientationmax, return;end    

  debugprint('Landmark position ratio check\n');
  dAreaAve=(dArea1+dArea2+dArea3)/3;
  if max(norm(a1)/dAreaAve,dAreaAve/norm(a1))>VISIONDATA.landmarkposratio return;end
  if max(norm(a2)/dAreaAve,dAreaAve/norm(a2))>VISIONDATA.landmarkposratio return;end
  debugprint('Landmark axis ratio check\n');
  hArea1=landmark.propsA1.axisMajor;
  hArea2=landmark.propsA2.axisMajor;	
  hArea3=landmark.propsA3.axisMajor;    
  if max(hArea1/hArea2,hArea2/hArea1)>2.0 then return;end
  if max(hArea2/hArea3,hArea3/hArea2)>2.0 then return;end
  --]]

  -- TODO: make height into a config parameter
  height = 0.45; --each  stripe is 15cm
  scale = math.max(d32*3/height, d21*3/height);
  --(hArea1+hArea2+hArea3)/height];
  v = HeadTransform.coordinatesA(landmarkCentroid2, scale);
  --debugprint('Landmark height:%.2f\n',v(3));
  landmark.detect = 1;
  landmark.v = v;
  return landmark;
end
