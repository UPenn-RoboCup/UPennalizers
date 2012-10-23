module(..., package.seeall);

require('Config');	-- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');	-- For Projection
require('Vision');
require('Debug');
require('shm');
require('vcm');
require('Body');
require('vector');


function detect(color)
  local boundary = {};
  boundary.detect = 1;
  boundary.top = {};
  boundary.bottom = {};

  local nCol = Config.camera.width/2/Config.vision.scaleB; -- Search space column

  -- Search label A column by column for freespace
  for nC = 1 , nCol do
    -- Search box width
    local topB = vector.new({nC,1});
	local bottomB = vector.new({nC,Vision.labelB.n});

    --Project to 2D coordinate
    local topV = HeadTransform.rayIntersectB(topB); 
    local bottomV = HeadTransform.rayIntersectB(bottomB); 

    boundary.top[nC],boundary.top[nC+nCol] = topV[1],topV[2];
    boundary.bottom[nC],boundary.bottom[nC+nCol] = bottomV[1],bottomV[2];
  end -- end for search for columns
  return boundary;
end
