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

min_areaA = Config.vision.landmark.min_areaA or 6;
min_fill_extent = Config.vision.landmark.min_fill_extent or 0.35;
th_arearatio = Config.vision.landmark.th_arearatio or 2;
th_centroid = Config.vision.landmark.th_centroid or 20;
th_distratio = Config.vision.landmark.th_dist or 2;
th_angle  = Config.vision.landmark.th_angle or 45*math.pi/180;

distanceFactorCyan = Config.vision.landmark.distanceFactorCyan or 1;
distanceFactorYellow = Config.vision.landmark.distanceFactorYellow or 1;

--Detection code for center landmark poles
function detect(color1,color2)

  if color1==colorYellow then vcm.add_debug_message("\nLandmark: Yellow landmark check\n")
  else vcm.add_debug_message("\nLandmark: Blue landmark check\n"); end

  local landmark={}
  landmark.detect=0;

  -- Check that we have enough of the upper/lower and of the middle colors
  if (Vision.colorCount[color1] < 2 * min_areaA) then 
    vcm.add_debug_message(string.format("Color1 count fail, %d\n",Vision.colorCount[color1]));
    return landmark; 
  end
  if (Vision.colorCount[color2] < min_areaA ) then 
    vcm.add_debug_message(string.format("Color2 count fail, %d\n",Vision.colorCount[color2]));
    return landmark; 
  end

  -- Find the blobs of each color
  -- TODO: this eats CPU.  Haven't we already run these connected regions?
  landmarkPropsB1= ImageProc.connected_regions(
  	  Vision.labelB.data,Vision.labelB.m,Vision.labelB.n,color1);
  landmarkPropsB2= ImageProc.connected_regions(
  	  Vision.labelB.data,Vision.labelB.m,Vision.labelB.n,color2);

  -- If we not seen two of the top/bottom color or one of the middle color, then exit
  if #landmarkPropsB1<2 or #landmarkPropsB2<1 then 
    vcm.add_debug_message("Blob number check fail\n");
    return landmark; 
  end

  -- Find the boundingbox stats of each blob
  -- TODO: These only use the largest of the blobs.  Is this optimal?
  landmark.propsA1= Vision.bboxStats(color1, landmarkPropsB1[1].boundingBox);
  landmark.propsA2= Vision.bboxStats(color2, landmarkPropsB2[1].boundingBox);
  landmark.propsA3= Vision.bboxStats(color1, landmarkPropsB1[2].boundingBox);

  --SJ: Robot can see both goal and landmark at once
  --Need to find out landmarks using position check

   --SJ:First check whether the largest blobs line up fine
   B11 = vector.new(landmarkPropsB1[1].centroid);
   B12 = vector.new(landmarkPropsB1[2].centroid);
   B21 = vector.new(landmarkPropsB2[1].centroid);
   if math.abs(B11[1]-B12[1])>th_centroid or
      math.abs(B11[1]-B21[1])>th_centroid or
      math.abs(B12[1]-B21[1])>th_centroid then
     local checked=false;
     if #landmarkPropsB1>2 then -- Yellow goalpost and YCY landmark case
       local B12 = vector.new(landmarkPropsB1[2].centroid);
       local B13 = vector.new(landmarkPropsB1[3].centroid);
       if math.abs(B12[1]-B13[1])<th_centroid then
          landmark.propsA1= Vision.bboxStats(color1, 
	   landmarkPropsB1[3].boundingBox);
	  checked=true;
       end
     end
     --Yellow goalpost and CYC landmark case
     if #landmarkPropsB2>1 and not checked then 
       local B22 = vector.new(landmarkPropsB2[2].centroid);
       if math.abs(B11[1]-B22[1])<th_centroid and 
	math.abs(B12[1]-B22[1])<th_centroid  then
          landmark.propsA2= Vision.bboxStats(color2, 
	   landmarkPropsB2[2].boundingBox);
       end
     end
   end

  -- Find the area of each blob considered for the landmark
  local dArea1 = landmark.propsA1.area;
  local dArea2 = landmark.propsA2.area;
  local dArea3 = landmark.propsA3.area;        





  vcm.add_debug_message(string.format("Area: %d, %d, %d\n",
	dArea1,dArea2,dArea3));

  -- Area check
  if dArea1<min_areaA or dArea2<min_areaA or dArea3<min_areaA then
    vcm.add_debug_message(string.format("Area check fail: %d, %d, %d\n",
	dArea1,dArea2,dArea3));
    return landmark;
  end

  --Area ratio checks
--  print(dArea1/dArea2,dArea2/dArea1);

  if dArea1/dArea2 > th_arearatio or dArea2/dArea1>th_arearatio then
    vcm.add_debug_message(string.format("Area ratio check 1-2 fail at %.1f\n",
	dArea1/dArea2));
    return landmark;
  end

  if dArea2/dArea3 > th_arearatio or dArea3/dArea2>th_arearatio then
    vcm.add_debug_message(string.format("Area ratio check 2-3 fail at %.1f\n",
	dArea1/dArea2));
    return landmark;
  end
  if dArea1/dArea3 > th_arearatio or dArea3/dArea1>th_arearatio then
    vcm.add_debug_message(string.format("Area ratio check 1-3 fail at %d\n",
	dArea1/dArea2));
    return landmark;
  end

  --Fill rate check
  fill_rate1 = dArea1 / Vision.bboxArea(landmark.propsA1.boundingBox);
  fill_rate2 = dArea2 / Vision.bboxArea(landmark.propsA2.boundingBox);
  fill_rate3 = dArea3 / Vision.bboxArea(landmark.propsA3.boundingBox);

  if fill_rate1 < min_fill_extent then 
    vcm.add_debug_message(string.format(
	"Fill rate 1 check fail at %.1f", fill_rate1 ));
    return landmark;
  end

  if fill_rate2 < min_fill_extent then 
    vcm.add_debug_message(string.format(
	"Fill rate 2 check fail at %.1f", fill_rate2 ));
    return landmark;
  end

  if fill_rate3 < min_fill_extent then 
    vcm.add_debug_message(string.format(
	"Fill rate 3 check fail at %.1f", fill_rate3 ));
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
  if d21/d32 > th_distratio or d32/d21>th_distratio then
    vcm.add_debug_message("Distance ratio check fail")
    return landmark;
  end

  --Center angle check
  local cosvalue = (a21[1]*a32[1]+a21[2]*a32[2])/d21/d32;
  if cosvalue<math.cos(th_angle) then
    vcm.add_debug_message("Center angle check fail")
    return landmark;
  end

  -- Find the global coordinates of the landmark
  height = 0.45; --each  stripe is 15cm
  scale = math.max( d32*3/height,d21*3/height);
  --(hArea1+hArea2+hArea3)/height];
  v = HeadTransform.coordinatesA(landmarkCentroid2, scale);

  landmark.detect = 1;
  if color1==colorYellow then 
    v[1]=v[1]*distanceFactorYellow;
    v[2]=v[2]*distanceFactorYellow;
  else
    v[1]=v[1]*distanceFactorCyan;
    v[2]=v[2]*distanceFactorCyan;
  end
  landmark.v = v;

  vcm.add_debug_message("Landmark detected")

  -- added for test_vision.m
  if Config.vision.copy_image_to_shm then
      vcm.set_landmark_centroid1(landmarkCentroid1);
      vcm.set_landmark_centroid2(landmarkCentroid2);
      vcm.set_landmark_centroid3(landmarkCentroid3);
  end

  return landmark;
end

