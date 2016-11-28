require('Config');	-- For Ball and Goal Size
require ('wcm')
require ('vcm');

T_thr = Config.vision.corner.T_thr or 0.15;
-- dist_threshold, 1 for L corner, 2 for T corner
dist_threshold= Config.vision.corner.dist_threshold or {25, 15};
angle_threshold = Config.vision.corner.angle_threshold or 10 * math.pi/180; --10 degrees, to test
length_threshold = Config.vision.corner.min_length or 6;
--threshold for the distance from the intersection to the given endpoint
distCornerThresh = 15; --test to see what the best threshold is


--gets the intersection of the normals (?) of two lines given their endpoints?
--sequence of inputs doesn't matter (in terms of coordinates, should always be x, y, x, y etc.)
function get_intersect(xi1,yi1,xi2,yi2,xj1,yj1,xj2,yj2)
  --in case any of them are nil
  if (xi1 and yi1 and xi2 and yi2 and xj1 and yj1 and xj2 and yj2) then 
    --line is define as Ax+By+C=0 where A=1 or A=0,B=1
    if yi1 == yi2 then Ai=0; Bi=1; Ci=-yi1; else
      Ai=1; Bi=(xi2-xi1)/(yi1-yi2); Ci=-xi1-Bi*yi1;
    end
   if yj1 == yj2 then Aj=0; Bj=1; Cj=-yj1; else
      Aj=1; Bj=(xj2-xj1)/(yj1-yj2); Cj=-xj1-Bj*yj1;
   end
    --two lines intersect if Ai*Bj!=Aj*Bi
    if Aj*Bi == Ai*Bj then return nil else 
      xinter = (Bi*Cj-Bj*Ci)/(Ai*Bj-Aj*Bi);
      yinter = (Aj*Ci-Ai*Cj)/(Ai*Bj-Aj*Bi);
      return {xinter, yinter}
    end
  else
    return;
  end
end

--returns the length of a line using its two endpoints and the distance formula
function get_line_length_line(line,i)
  xi1=line.endpoint[i][1];
  xi2=line.endpoint[i][2];
  yi1=line.endpoint[i][3];
  yi2=line.endpoint[i][4];
  return math.sqrt((xi1-xi2)^2+(yi1-yi2)^2);
end

--returns the distance between two points
function distance_formula(x1, y1, x2, y2)
  return math.sqrt((x2 - x1) ^2 + (y2 - y1)^2);
end


--returns type of # of intersections (1 is T, 2 is L) and the v values, 
--when this function is called, the two lines are assumed to not be parallel
function isTCorner(line, i, j)
  --finds the endpoints of the two lines
  xi1=line.endpoint[i][1];
  xi2=line.endpoint[i][2];
  yi1=line.endpoint[i][3];
  yi2=line.endpoint[i][4];
  xj1=line.endpoint[j][1];
  xj2=line.endpoint[j][2];
  yj1=line.endpoint[j][3];
  yj2=line.endpoint[j][4];

  --keeps track of the number of lines with an endpoint close to the intersect (aka, the type of corner)
  num_intersect_corners = 0;

  --this value tells us which line the intersection is an endpoint of so that in the case when we have one intersection with an endpoint
  --we can check which one and eliminate an edge case where the robot will see a T corner when parts of both lines are truncated
  --1 is i, 2 is j
  local intersecting_line = 0;

  --vc0 is corner coordinates
  vc0 = {};
  --For L-detection, v10 and v20 are non-corner coordinates
  --For T-detection, v10 and v20 are the endpoints of the line without a corner
  v10 = {};
  v20 = {};
  --For L-Detection, return {-1, -1}, a bogus coordinate
  --For T-Detection, return the second non-corner endpoint of the line with the corner as one of the endpoints
  vt0 = {};

  --Keeps track of which point is not near the "corner"
  ipoint = {};
  jpoint = {};

  --should never be nil because the two lines we use should be perpendicular
  --the corner is given by the coordinates (x, y)
  if (xi1 == xi2) then
    x = xi1;
    mj = (yj2 - yj1)/(xj2 - xj1);
    bj = yj1 - mj * xj1;
    y = mj * x + bj;
  elseif (xj1 == xj2) then
    x = xj1;
    mi = (yi2 - yi1)/(xi2 - xi1);
    bi = yi1 - mi * xi1;
    y = mi * x + bi;
  else 
    mi = (yi2 - yi1)/(xi2 - xi1);
    bi = yi1 - mi * xi1;
    mj = (yj2 - yj1)/(xj2 - xj1);
    bj = yj1 - mj * xj1;
    x = (bj - bi)/(mi - mj);
    y = mi * x + bi;
  end
  
  vc0 = {x, y};

  --compares the distance from the intersection point to the distance from endpoint threshold
  --first chunk checks if the first line has endpoints close to the center
  if (distance_formula(x, y, xi1, yi1) < distCornerThresh) then 
    num_intersect_corners = num_intersect_corners + 1;
    intersecting_line = 1;
    ipoint = {xi2, yi2};
  elseif (distance_formula(x, y, xi2, yi2) < distCornerThresh) then
    num_intersect_corners = num_intersect_corners + 1;
    intersecting_line = 1;
    ipoint = {xi1, yi1};
  end
  --this chunk checks if the second line has endpoints close to the center
  if (distance_formula(x, y, xj1, yj1) < distCornerThresh) then
    num_intersect_corners = num_intersect_corners + 1;
    intersecting_line = 2;
    jpoint = {xj2, yj2};
  elseif (distance_formula(x, y, xj2, yj2) < distCornerThresh) then
    num_intersect_corners = num_intersect_corners + 1;
    intersecting_line = 2;
    jpoint = {xj1, yj1};
  end

  --if it still could be a T-Corner, we check to see if the intersection is within the bounds of the non-endpoint line
  --if it fails this test, we assume that it is not a corner at all
  if (num_intersect_corners == 1) then
    if intersecting_line == 2 then
      if (((xi2 <= x and x <= xi1) or (xi1 <= x and x <= xi2)) and ((yi2 <= y and y <= yi1) or (yi1 <= y and y <= yi2))) then
        --T-Corner with j as the line with one endpoint as the corner point, so check if the endpoint is between endpoints of line i
        v10 = {xi1, yi1};
        v20 = {xi2, yi2};
        vt0 = jpoint;
        return num_intersect_corners, vc0, v10, v20, vt0;
      else
        num_intersect_corners = 0;
      end
    elseif intersecting_line == 1 then
      if (((xj2 <= x and x <= xj1) or (xj1 <= x and x <= xj2)) and ((yj2 <= y and y <= yj1) or (yj1 <= y and y <= yj2))) then
        --T-Corner with i as the line with one endpoint as the corner point, so check if the endpoint is between endpoints of line j
        v10 = {xj1, yj1};
        v20 = {xj2, yj2};
        vt0 = ipoint;
        return num_intersect_corners, vc0, v10, v20, vt0;
      else
        num_intersect_corners = 0;
      end
    end
  elseif (num_intersect_corners == 2) then
    --L-corner
    v10 = ipoint;
    v20 = jpoint;
    vt0 = {-1, -1};
    return num_intersect_corners, vc0, v10, v20, vt0;
  end
  --if we reach here, then we do not see a corner, so we return that we don't see a corner and a bunch of filler values
  return num_intersect_corners, vc0, {-1, -1}, {-1, -1}, {-1, -1};
end



local update = function(self, color, p_vision, line)
  self.detect = 0;

  --not enough lines for a corner
  if line.detect==0 or line.nLines<2 then 
    return ;
  end
 
  if vcm.get_circle_detect() == 1 then
    p_vision:add_debug_message("Circle detected do not detect corner");
    return ;
  end
 
  linepair={};
  linepaircount=0;
  linepairvc0={};
  linepairv10={};
  linepairv20={};
  linepairvt0={};
  linepairangle={};
  linepairtype={};
  
  --angle variance analysis
  -- saves time by preventing a corner search if the lines are extremely weird angles
  angle_set = {}
  angle_sum = 0;
  for i=1,line.nLines do
    angle_set[i] = math.abs(180*(line.angle[i]%(math.pi/2))/math.pi);
    if angle_set[i] > 45 then
      angle_set[i] = 90-angle_set[i];
    end
    angle_sum = angle_sum+angle_set[i];
  end
  angle_avg = angle_sum/line.nLines;
  angle_sum_sq = 0
  angle_variance = 0
  for i=1,line.nLines do
    angle_sum_sq = angle_sum_sq + (angle_set[i]-angle_avg)^2
  end
  angle_variance = math.sqrt(angle_sum_sq/line.nLines);
  if line.nLines>2 and angle_variance>5 then
    p_vision:add_debug_message(string.format("variance too large:%.2f. No corner\n",angle_variance));
    return
  end

  --use a table to store all possible intersects
  --intersectT stores all the intersections between the lines
  intersectT={}
  for i=1,line.nLines-1 do
    intersectT[i]={};
  end
   -- Search for perpendicular lines: only adds the intersection if the angle is close to being perpendicular
  --p_vision:add_debug_message(string.format("\nCorner: total %d lines\n",line.nLines))
  for i=1,line.nLines-1 do
    for j=i+1,line.nLines do
      local ang=math.abs(util.mod_angle(line.angle[i]-line.angle[j]));
      if math.abs(ang-math.pi/2)<angle_threshold then
        --p_vision:add_debug_message(string.format("Corner Angle: %f \n", math.abs(ang-math.pi/2) * 180/math.pi));
        ip = line.endpoint[i];
        jp = line.endpoint[j];
        intersect = get_intersect(
          ip[1],ip[3],ip[2],ip[4],jp[1],jp[3],jp[2],jp[4]);
        intersectT[i][j] = intersect;
      end
    end
  end
  

  --add the values to the arrays defined at the beginning of update
  for i=1,line.nLines-1 do
    for j=i+1,line.nLines do
      if intersectT[i][j] then
        --check to see what type of corner the intersection creates (if applicable)
        --also gets the "V" values in labelB, before headTransform
        num_intersect_corners, vc0, v10, v20, vt0 = isTCorner(line, i, j);
        if (num_intersect_corners == 1) then
          --T-Corner
          cornertype = 2;
        elseif (num_intersect_corners == 2) then
          --L-Corner
          cornertype = 1;
        else
          --otherwise, not a corner
          return ;
        end
        if get_line_length_line(line,i)>length_threshold and
            get_line_length_line(line,j)>length_threshold then
          linepaircount=linepaircount+1;
          linepair[linepaircount]={i,j};
          linepairvc0[linepaircount]=vc0;
          linepairv10[linepaircount]=v10;
          linepairv20[linepaircount]=v20;
          linepairangle[linepaircount]=ang;
          linepairtype[linepaircount]=cornertype;
          linepairvt0[linepaircount]=vt0;
        end
      end
    end
  end

  --if there are no pairs of lines detected, then we abort
  if linepaircount==0 then 
    p_vision:add_debug_message("No Lines Intersect");
    return ;
  end

  --this section finds the closest corner, which is then called as the "best corner"
  --only displays one corner, which is the closest corner that it sees
  best_corner=1;
  min_corner_dist = math.huge;

  --Pick the closest corner
  for i=1,linepaircount do
    vc0=linepairvc0[i];
    vc = HeadTransform.coordinatesB({vc0[1],vc0[2]});
    vc = HeadTransform.projectGround(vc,0);
    corner_dist=vc[1]*vc[1]+vc[2]*vc[2];
    if min_corner_dist>corner_dist then
      min_corner_dist = corner_dist;
      best_corner=i;
    end
  end

  --adds the closest corner to the vcm (shared memory)
  self.linepair=linepair[best_corner]
  self.type=linepairtype[best_corner];

  vc0=linepairvc0[best_corner];
  v10=linepairv10[best_corner];
  v20=linepairv20[best_corner];
  vt0=linepairvt0[best_corner];

  vc = HeadTransform.coordinatesB({vc0[1],vc0[2]});
  vc = HeadTransform.projectGround(vc,0);

  v1 = HeadTransform.coordinatesB({v10[1],v10[2]});
  v1 = HeadTransform.projectGround(v1,0);

  v2 = HeadTransform.coordinatesB({v20[1],v20[2]});
  v2 = HeadTransform.projectGround(v2,0);

  --position in labelB
  self.vc0=vc0;
  self.v10=v10;
  self.v20=v20;
  p_vision:add_debug_message(string.format("Old Code: vc0: (%f, %f) v10: (%f, %f) v20: (%f, %f), vt0 (%f, %f)", vc0[1], vc0[2], v10[1], v10[2], v20[1], v20[2], vt0[1], vt0[2]));

  --position in xy
  self.v = vc;
  self.v1 = v1;
  self.v2 = v2;
--  p_vision:add_debug_message(string.format("vc0: %f, v10: %f, v20: %f", vc0, v10, v20));

  --the angle of the corner is defined as the average of the two lines (-pi, pi)
  --self.type: 1 is "L" corner , 2 is "T" corner
  if self.type==1 then
    local angle1=math.atan2(v1[2]-vc[2],v1[1]-vc[1]);
    local angle2=math.atan2(v2[2]-vc[2],v2[1]-vc[1]);
    if angle1*angle2>=0 or math.abs(angle2)+math.abs(angle1)<=math.pi then
      self.angle=(angle1+angle2)/2;
    else
      local angle=(angle1+angle2)/2;
      if angle>0 then self.angle=angle-math.pi
      else self.angle=angle+math.pi end
    end 
  elseif self.type == 2 then
    vt = HeadTransform.coordinatesB({vt0[1],vt0[2]});
    vt = HeadTransform.projectGround(vt,0);
    self.angle=math.atan2(vt[2]-vc[2],vt[1]-vc[1])
  end

  p_vision:add_debug_message(string.format("angle of corner: %d\n",self.angle*180/math.pi));

  if self.type==1 then
    p_vision:add_debug_message("L-corner detected\n");
  elseif self.type == 2 then
    p_vision:add_debug_message("T-corner detected\n");
  end

  self.detect = 1;
  return ;
end

local update_shm = function(self, parent_vision)
  vcm.set_corner_detect(self.detect);
  if (self.detect == 1) then
    vcm.set_corner_type(self.type)
    vcm.set_corner_vc0(self.vc0)
    vcm.set_corner_v10(self.v10)
    vcm.set_corner_v20(self.v20)
    vcm.set_corner_v(self.v)
    vcm.set_corner_v1(self.v1)
    vcm.set_corner_v2(self.v2)
    vcm.set_corner_angle(self.angle)
  end
end

local detectCorner = {}

function detectCorner.entry(parent_vision)
  print('init Corner detection')
  local self = {}
  self.update = update
  self.update_shm = update_shm
  self.detect = 0
  return self
end

return detectCorner
