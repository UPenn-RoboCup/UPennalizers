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


function check_blob(color1,propsB)
  local propsA= Vision.bboxStats(color1, propsB.boundingBox);
  local dArea = propsA.area;
  local check_passed = true;
  --Area check
  if dArea<min_areaA then
    check_passed = false;
  else
    fill_rate = dArea / Vision.bboxArea(propsA.boundingBox);
    if fill_rate < min_fill_extent then 
      check_passed = false;
    end
  end
  local blob={};
  if check_passed then
    blob.detect = 1;
    blob.area = dArea;
    blob.centroid = propsA.centroid;
  else
    blob.detect = 0;
  end
  return blob;
end

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

  --Check
  blobs1={};
  blobs2={};
  blob_index1 = 0;
  blob_index2 = 0;
  for i=1,#landmarkPropsB1 do
    cblob = check_blob(color1,landmarkPropsB1[i]);
    if cblob.detect==1 then
      blob_index1 = blob_index1 + 1;
      blobs1[blob_index1]={
	cblob.area, cblob.centroid};
    end
  end
  for i=1,#landmarkPropsB2 do
    cblob = check_blob(color2,landmarkPropsB2[i]);
    if cblob.detect==1 then
      blob_index2 = blob_index2 + 1;
      blobs2[blob_index2]={
	cblob.area, cblob.centroid};
    end
  end

  if blob_index1 < 2 or blob_index2 < 1 then
    vcm.add_debug_message("Fitered blob number check fail\n");
    return landmark; 
  end 

max_blob_num = 5;

  blob_index1 = math.min(max_blob_num, blob_index1);
  blob_index2 = math.min(max_blob_num, blob_index2);

  --Find good pairs of blobs with color1
  blob_pair_index = 0;
  blob_pairs={};

  for i=1,blob_index1-1 do
    for j=i+1, blob_index1 do
      local check_passed = true;
      --Centroid X position check
      if math.abs(blobs1[i][2][1]-blobs1[j][2][1]) > th_centroid then
        check_passed = false;
      end
      --Area ratio check
      if blobs1[i][1]/blobs1[j][1]> th_arearatio or 
         blobs1[j][1]/blobs1[i][1]> th_arearatio then
        check_passed = false;
      end
      if check_passed then
        blob_pair_index = blob_pair_index + 1;
        blob_pairs[blob_pair_index] = {i,j};
      end
    end
  end

  if blob_pair_index<1 then
    vcm.add_debug_message("No good blob pairs\n");
    return landmark; 
  end

  --Check all blobs with color2
  for i=1,blob_pair_index do
    for j=1, blob_index2 do
      local check_passed = true;
      b1_index1 = blob_pairs[i][1];
      b1_index2 = blob_pairs[i][2];

      --Check area ratio
      area11 = blobs1[b1_index1][1];
      area12 = blobs1[b1_index2][1];
      area2=blobs2[j][1];

      if area11/area2> th_arearatio or 
         area2/area11> th_arearatio then
        check_passed = false;
      end
      if area12/area2> th_arearatio or 
         area2/area12> th_arearatio then
        check_passed = false;
      end

      --Check distance ratio
      cent11 = vector.new(blobs1[b1_index1][2]);
      cent12 = vector.new(blobs1[b1_index2][2]);
      cent2 = vector.new(blobs2[j][2]);

      local a21 = cent2-cent11;
      local a32 = cent12-cent2;
      local d21 = math.sqrt(a21[1]^2+a21[2]^2);
      local d32 = math.sqrt(a32[1]^2+a32[2]^2);
      
      if d21/d32 > th_distratio or d32/d21>th_distratio then
        check_passed = false;
      end

      --Check angle
      local cosvalue = (a21[1]*a32[1]+a21[2]*a32[2])/d21/d32;
      if cosvalue<math.cos(th_angle) then
        check_passed = false;
      end
      if check_passed then
        height = 0.45; --each  stripe is 15cm
        landmark.detect = 1;
        landmark.centroid = cent2;	
	landmark.cent11 = cent11;
	landmark.cent12 = cent12;
        landmark.scale =  math.max( d32*3/height,d21*3/height);
      end
    end
  end

  if landmark.detect==0 then
    return landmark;
  end


  -- Find the global coordinates of the landmark
  --(hArea1+hArea2+hArea3)/height];
  v = HeadTransform.coordinatesA(
	landmark.centroid, landmark.scale);

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
      vcm.set_landmark_centroid1(landmark.cent11);
      vcm.set_landmark_centroid2(landmark.centroid);
      vcm.set_landmark_centroid3(landmark.cent12);
  end

  return landmark;
end

