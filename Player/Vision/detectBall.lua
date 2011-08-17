module(..., package.seeall);

require('Config');      -- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');       -- For Projection
require('Vision');
require('Body');

require('shm');
require('vcm');

require('Detection');
require('Debug');

-- Define Color
colorOrange = 1;
colorYellow = 2;
colorCyan = 4;
colorField = 8;
colorWhite = 16;

use_point_goal=Config.vision.use_point_goal;
headInverted=Config.vision.headInverted;

headZ = Config.head.camOffsetZ;


function detect(color)
  local ball = {};
  ball.detect = 0;

  -- threshold check on the total number of ball pixels in the image
  if (Vision.colorCount[color] < 6) then  	
    Debug.vprint(2,1,'total orange pixels threshold fail : '..Vision.colorCount[color]..' < 6');
    return ball;  	
  end

  local diameter = Config.vision.ball_diameter;

  -- find connected components of ball pixels
  ballPropsB = ImageProc.connected_regions(Vision.labelB.data, Vision.labelB.m, Vision.labelB.n, color);
  --ballPropsB = ImageProc.connected_regions(labelB.data, labelB.m, labelB.n, HeadTransform.get_horizonB(), color);

  if (#ballPropsB == 0) then   	
    return ball;  
  end

  -- get largest blob
  ball.propsB = ballPropsB[1];
  ball.propsA = Vision.bboxStats(color, ballPropsB[1].boundingBox);
  ball.bboxA = Vision.bboxB2A(ballPropsB[1].boundingBox);

  -- threshold checks on the region properties
  if ((ball.propsA.area < 6) or (ball.propsA.area < 0.35*Vision.bboxArea(ball.propsA.boundingBox))) then
    Debug.vprint(2,1,'Threshold check fail');
    return ball;
  else
    -- diameter of the area
    dArea = math.sqrt((4/math.pi)*ball.propsA.area);

    -- Find the centroid of the ball
    ballCentroid = ball.propsA.centroid;

    --[[
    print('focalA: '..focalA);
    print('centroid: '..ballCentroid[1]..', '..ballCentroid[2]);
    print('diameter: '..diameter);
    print('dArea: '..dArea);
    print('axisMajor: '..ball.propsA.axisMajor);
    --]]

    -- Coordinates of ball
    scale = math.max(dArea/diameter, ball.propsA.axisMajor/diameter);
    v = HeadTransform.coordinatesA(ballCentroid, scale);
    --[[
    print('scale: '..scale);
    print('v0: '..v[1]..', '..v[2]..', '..v[3]);
    --]]


    --Ball height check
    if v[3] > Config.vision.ball_height_max then
      Debug.vprint(2,1,'Height check fail');
      return ball;
    else   
      if Config.vision.check_for_ground == 1 then
        -- ground check
        -- is ball cut off at the bottom of the image?
        if (ballCentroid[2] < 120 - dArea) then
          -- bounding box 
          fieldBBox = {};
          fieldBBox[1] = ballCentroid[1] - 30;
          fieldBBox[2] = ballCentroid[1] + 30;
          fieldBBox[3] = ballCentroid[2] + .5*dArea;
          fieldBBox[4] = ballCentroid[2] + .5*dArea + 20;

          -- color stats for the bbox
          fieldBBoxStats = ImageProc.color_stats(Vision.labelA.data, Vision.labelA.m, Vision.labelA.n, colorField, fieldBBox);

          -- is there green under the ball?
          if (fieldBBoxStats.area < 400) then
            -- if there is no field under the ball it may be because its on a white line
            whiteBBoxStats = ImageProc.color_stats(Vision.labelA.data, Vision.labelA.m, Vision.labelA.n, colorWhite, fieldBBox);
            if (whiteBBoxStats.area < 150) then
              Debug.vprint(2,1,'ground check fail');
              return ball;
            end 
          end
        end
      end
    end
  end
  

  -- Project to ground plane
  if (v[3] < -headZ) then
    v = (-headZ/v[3])*v;
  end

  --Discount body offset:
  uBodyOffset = mcm.get_walk_bodyOffset();
  v[1] = v[1] - uBodyOffset[1];
  v[2] = v[2] - uBodyOffset[2];

  ball.v = v;
  ball.detect = 1;

  --print('v: '..ball.v[1]..', '..ball.v[2]..', '..ball.v[3]);

  ball.r = math.sqrt(ball.v[1]^2 + ball.v[2]^2);

  -- How much to update the particle filter
  ball.dr = 0.25*ball.r;
  ball.da = 10*math.pi/180;
  Debug.vprint(1,1,'BALL DETECTED');
  return ball;
end
