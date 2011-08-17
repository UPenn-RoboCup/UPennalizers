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

-- TODO: Why is this here?
Config.vision.landmarkfillextent = 0.35;

--Detection code for center landmark poles
function detect(color1,color2)
  local DEBUG = 0;

  local landmark={}
  landmark.detect=0;

  -- Check that we have enough of the upper/lower and of the middle colors
  if (Vision.colorCount[color1] < 12) then return landmark; end
  if (Vision.colorCount[color2] < 6) then return landmark; end

  -- Find the blobs of each color
  -- TODO: this eats CPU.  Haven't we already run these connected regions?
  landmarkPropsB1= ImageProc.connected_regions(
  	  Vision.labelB.data,Vision.labelB.m,Vision.labelB.n,color1);
  landmarkPropsB2= ImageProc.connected_regions(
  	  Vision.labelB.data,Vision.labelB.m,Vision.labelB.n,color2);

  -- If we not seen two of the top/bottom color or one of the middle color, then exit
  if #landmarkPropsB1<2 or #landmarkPropsB2<1 then return landmark; end

  -- Find the boundingbox stats of each blob
  -- TODO: These only use the largest of the blobs.  Is this optimal?
  landmark.propsA1= Detection.bboxStats(color1, landmarkPropsB1[1].boundingBox);
  landmark.propsA2= Detection.bboxStats(color2, landmarkPropsB2[1].boundingBox);
  landmark.propsA3= Detection.bboxStats(color1, landmarkPropsB1[2].boundingBox);

  --SJ: Robot can see both goal and landmark at once
  --Need to find out landmarks using position check

   if #landmarkPropsB1>2 then -- Yellow goalpost and YCY landmark case
      local B12 = vector.new(landmarkPropsB1[2].centroid);
      local B13 = vector.new(landmarkPropsB1[3].centroid);
      if math.abs(B12[1]-B13[1])<10 then
         landmark.propsA1= Detection.bboxStats(color1, 
landmarkPropsB1[3].boundingBox);
      end
   end
   if #landmarkPropsB2>1 then --Yellow goalpost and CYC landmark case
      local B11 = vector.new(landmarkPropsB1[1].centroid);
      local B12 = vector.new(landmarkPropsB1[2].centroid);
      local B22 = vector.new(landmarkPropsB2[2].centroid);
--      print(B11[1],B22[1],B12[1]);
      if math.abs(B11[1]-B22[1])<10 and math.abs(B12[1]-B22[1])<10  then
         landmark.propsA2= Detection.bboxStats(color2, 
landmarkPropsB2[2].boundingBox);
      end
   end

  -- Find the area of each blob considered for the landmark
  local dArea1 = landmark.propsA1.area;
  local dArea2 = landmark.propsA2.area;
  local dArea3 = landmark.propsA3.area;        

  -- Area check
  if dArea1<6 or dArea2<6 or dArea3<6 then
    if (DEBUG==1) then print('Fails an area check');end
    return landmark;
  end

  --Area ratio checks
--  print(dArea1/dArea2,dArea2/dArea1);

  if dArea1/dArea2 > 2 or dArea2/dArea1>2 then
    if (DEBUG==1) then print('Fails ratio check 1');end
    return landmark;
  end

  if dArea2/dArea3 > 2 or dArea3/dArea2>2 then
    if (DEBUG==1) then print('Fails ratio check 2');end
    return landmark;
  end
  if dArea1/dArea3 > 2 or dArea3/dArea1>2 then
    if (DEBUG==1) then print('Fails ratio check 3');end
    return landmark;
  end

  --Fill rate check
  if dArea1 < Config.vision.landmarkfillextent*Detection.bboxArea(landmark.propsA1.boundingBox)	then 
    if (DEBUG==1) then print('Fails fill rate check 1');end
    return landmark;
  end

  --Fill rate check (2)
  if dArea2 < Config.vision.landmarkfillextent*Detection.bboxArea(landmark.propsA2.boundingBox)	then
    if (DEBUG==1) then print('Fails fill rate check 2');end
    return landmark;
  end

  --Fill rate check (3)
  if dArea3 < Config.vision.landmarkfillextent*Detection.bboxArea(landmark.propsA3.boundingBox)	then
    if (DEBUG==1) then print('Fails fill rate check 3');end
    return landmark;
  end

  local landmarkCentroid1 = vector.new(landmark.propsA1.centroid);
  local landmarkCentroid2 = vector.new(landmark.propsA2.centroid);
  local landmarkCentroid3 = vector.new(landmark.propsA3.centroid);
  local a21 = landmarkCentroid2-landmarkCentroid1;
  local a32 = landmarkCentroid3-landmarkCentroid2;
  local d21 = math.sqrt(a21[1]^2+a21[2]^2);
  local d32 = math.sqrt(a32[1]^2+a32[2]^2);

  --Distance ratio check
  if d21/d32 > 2.0 or d32/d21>2.0 then
    if (DEBUG==1) then print('Fails distance ratio check');end
    return landmark;
  end

  --Center angle check
  local cosvalue = (a21[1]*a32[1]+a21[2]*a32[2])/d21/d32;
  if cosvalue<math.cos(45*math.pi/180) then
    if (DEBUG==1) then print('Fails angle check');end
    return landmark;
  end

--TODO: Do we need all those checks?
--[[

%tilt check.. we may not need this
%   if abs(landmark.propsA1.orientation) < 60*pi/180, return;end
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

  -- Find the global coordinates of the landmark
  height = 0.45; --each  stripe is 15cm
  scale = math.max( d32*3/height,d21*3/height);
  --(hArea1+hArea2+hArea3)/height];
  v = HeadTransform.coordinatesA(landmarkCentroid2, scale);


  landmark.detect = 1;
  landmark.v = v;
--  print("Landmark detected")
  return landmark;
end

