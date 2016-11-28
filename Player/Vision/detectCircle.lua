require('Config');
require('wcm');
require('HeadTransform');
require('util');

var_threshold = Config.vision.circle.var_threshold or 0.06;
angle_threshold = 10 * math.pi/180; --10 degrees, to test

function get_line_length_circle(line,i)
  xi0 = line.v[i][1][1];
  yi0 = line.v[i][1][2];
  xi1 = line.v[i][2][1];
  yi1 = line.v[i][2][2];

  return math.sqrt((xi0-xi1)^2+(yi0-yi1)^2);
end

function distance(x1,y1,x2,y2)
         return math.sqrt((x1-x2)^2+(y1-y2)^2);
end

function normal_line(line,i)   
  xv0 = line.v[i][1][1];
  yv0 = line.v[i][1][2];
  xv1 = line.v[i][2][1];
  yv1 = line.v[i][2][2];
  
  if yv1~=yv0 and xv1~=xv0 then
  --m =(yv1-yv0)/(xv1-xv0);
  m = (xv1-xv0)/(-yv1+yv0);
  else m = 1000;
  end
  minv = -1/m;
  x_mean = (-yv0-yv1)/2;
  y_mean = (xv0+xv1)/2;
  
  
  x_new0 = x_mean-1;
  x_new1 = x_mean +1;
  y_new0 = y_mean-1*minv;
  y_new1 = y_mean+1*minv;
 
 return x_new0,x_new1,y_new0,y_new1;
 
end

--gets the intersection of the normal lines
function get_intersect(xi1,yi1,xi2,yi2,xj1,yj1,xj2,yj2)
  --the sequence of the input does not matter, but still needs to correctly be (x1, y1) then (x2, y2) etc.
  --line is define as Ax+By+C=0 where A=1 or A=0,B=1
  if yi1 == yi2 then Ai=0; Bi=1; Ci=-yi1; else
    Ai=1; Bi=(xi2-xi1)/(yi1-yi2); Ci=-xi1-Bi*yi1;
  end
  if yj1 == yj2 then Aj=0; Bj=1; Cj=-yj1; else
    Aj=1; Bj=(xj2-xj1)/(yj1-yj2); Cj=-xj1-Bj*yj1;
  end
  --print(string.format("L1: %.2fX + %.2fY + %.2f = 0\n",Ai,Bi,Ci))
  --print(string.format("L2: %.2fX + %.2fY + %.2f = 0\n",Aj,Bj,Cj))
  --two lines intersect if Ai*Bj!=Aj*Bi
  if Aj*Bi == Ai*Bj then return nil else 
    xinter = (Bi*Cj-Bj*Ci)/(Ai*Bj-Aj*Bi);
    yinter = (Aj*Ci-Ai*Cj)/(Ai*Bj-Aj*Bi);
    return {xinter, yinter}
  end
end


function intersection_point(line,i,j)
  xi0 = line.v[i][1][1];
  yi0 = line.v[i][1][2];
  xi1 = line.v[i][2][1];
  yi1 = line.v[i][2][2];

  xj0 = line.v[j][1][1];
  yj0 = line.v[j][1][2];
  xj1 = line.v[j][2][1];
  yj1 = line.v[j][2][2];

  xi_new0,xi_new1,yi_new0,yi_new1 = normal_line(line,i);
  inter = get_intersect(xi_new0,yi_new0,xi_new1,yi_new1,-yj0,xj0,-yj1,xj1);   
  return inter;
  
end

--takes in two lines and returns the acute angle between them in radians
function getCircleAngle(line, i, j)
  --get the angles of the lines relative to the robot
  ai = line.angle[i];
  aj = line.angle[j];

  --find the positive angle between the two
  adif = math.abs(ai - aj);

  --make sure that the angle is acute, not obtuse
  if (adif > math.pi/2) then
    adif = adif - math.pi/2;
  end

  return adif;
end



local update = function(self,p_vision,line)
   self.detect = 0;
if line.detect == 0 or line.nLines<3 then
     p_vision:add_debug_message("not enough lines for circle check\n"); 
   return;
end

arc = {};
length = {};
dist = {};

--variable to keep track of how many parallel lines we have: we start with 1
local num_parallel = {};

--compare each pair of lines
--find the angle between the two lines, and check if the lines are parallel (within a certain threshold)
--if there are too many parallel lines (3 for now), then this cannot be a circle
for i = 1, line.nLines do
  num_parallel[i] = 1;
  for j = 1, line.nLines do
    --if the angle of the two lines is ~ 0, then we say they are parallel
    if (j ~= i) and (getCircleAngle(line, i, j) < angle_threshold) then
      num_parallel[i] = num_parallel[i] + 1;
    end
  end
end

parallel_lines, par_idx = util.max(num_parallel); 

if (parallel_lines >= 3) then
  p_vision:add_debug_message("No Circle: too many parallel lines");
  return ;
end


for i=1,line.nLines do   
     length[i]=get_line_length_circle(line,i);
     --p_vision:add_debug_message(string.format("Length %d : %f", i, length[i]));

end

longest,idx = util.max(length);
--print('idx:' .. idx);
--print('xv0:' .. line.v[idx][1][1] .. 'yv0:' .. line.v[idx][1][2] .. 'xv1:' .. line.v[idx][2][1] .. 'yv1:' .. line.v[idx][2][2]);


linecount = 0;

x_total = 0;
y_total = 0;
dist_sum = 0;


centerLineExists = 1; --1 if the longest line is longer than the other lines by a certain amount

for i = 1, line.nLines do
  --length difference less than threshold for all lines that aren't the max disqualify center line
  --0.3 is a threshold, the max diff between longest and next longest lines for the line to be considered a center line
  if (i ~= idx) and (longest - length[i] < 0.3) then  
    centerLineExists = 0;
  end
end

--case if the center line exists
if (centerLineExists == 1) then
  for i=1,line.nLines do
    if i ~= idx then
       pt = intersection_point(line,i,idx);
      -- print('i:'.. i .. 'pt1:' .. pt[1] .. 'pt2:' .. pt[2]);       
      --if pt[1]>line.v[idx][1][1] and pt[1]<line.v[idx][2][1] then --intersection point not too far
       linecount = linecount+1;
       arc[linecount]=pt;
       x_total = x_total + pt[1];
       y_total = y_total + pt[2];
       dist[linecount]=distance(pt[1],pt[2],(-line.v[i][1][2]-line.v[i][2][2])/2,(line.v[i][1][1]+line.v[i][2][1])/2);        
       dist_sum = dist[linecount]+dist_sum;
       --end
    end
  end 
  x_mean = x_total/linecount;
  y_mean = y_total/linecount;

p_vision:add_debug_message(string.format("Center Coordinates: (%f, %f)", x_mean, y_mean));

  self.x_center = x_mean;
  self.y_center = y_mean;

  dist_mean = dist_sum/linecount;

  sum = 0;
  for i=1,linecount do
      sum=sum+(dist[linecount]-dist_mean)^2;
  end
  var = sum/(linecount*get_line_length_circle(line,idx));
  self.var = var;
  --end of case with center line
else 
  p_vision:add_debug_message("No Center Line Detected \n");
  return;
  --[[
  --begin case where there is no center line detected
  --check the pairs of line to see if too many of them are perpendicular?
  --get the intersection points of the unique pairs of lines
  --The Following is trying to find a circle without "seeing" the center line"
  for i=1, (line.nLines -1) do
    for j=(i + 1), line.nLines do
      local pt = get_intersect(line.v[i][1][1], line.v[i][1][2], line.v[i][2][1], line.v[i][2][2], line.v[j][1][1], line.v[j][1][2], line.v[j][2][1], line.v[j][2][2]);
      if pt then
        x_total = x_total + pt[1];
        y_total = y_total + pt[2];
        linecount = linecount + 1;
        --gets the distance from the intersection point to the middle of the first line
        dist[linecount]=distance(pt[1],pt[2],(-line.v[i][1][2]-line.v[i][2][2])/2,(line.v[i][1][1]+line.v[i][2][1])/2);
       --p_vision:add_debug_message(string.format("dist %i part 1 is %d", linecount, dist[linecount]));
        --gets the distance from the intersection point to the middle of the second line
        dist[linecount]=dist[linecount]+distance(pt[1],pt[2],(-line.v[j][1][2]-line.v[j][2][2])/2,(line.v[j][1][1]+line.v[j][2][1])/2);
        --p_vision:add_debug_message(string.format("dist %i part 2 is %d", linecount, dist[linecount]));
        --dist_sum is the sum of all distances, so distances from intersection to each line
        dist_sum = dist[linecount]+dist_sum;
      end
    end
  end
  p_vision:add_debug_message(string.format("Linecount: %d \n", linecount));
  --average of the x-coordinate and the y-coordinate
  x_mean = x_total/linecount;
  y_mean = y_total/linecount;


  self.x_center = x_mean;
  self.y_center = y_mean;

  --this mean has to be divided by both linecount(total number of unique pairs) and 2 because each pair adds 2 distances
  p_vision:add_debug_message(string.format("dist_sum: %d \n", dist_sum));
  dist_mean = dist_sum/(2 * linecount);
  p_vision:add_debug_message(string.format("dist_mean: %d \n", dist_mean));

  sum = 0;
  for i=1,linecount do
    if (dist[i]) then 
      sum=sum+(dist[i]-dist_mean)^2;
    end
  end
  p_vision:add_debug_message(string.format("Sum: %d \n", sum));
  var = sum/(linecount*2);
  p_vision:add_debug_message(string.format("Variance: %f \n", var));
  self.var = var;
  p_vision:add_debug_message("No Center Line");
  --end case without center line
  ]]
end

if var<var_threshold then
  self.detect = 1;
  self.x_center = x_mean;
  self.y_center = y_mean;
  --v_circle = HeadTransform.coordinatesB({x_mean,y_mean});
  --v_circle = HeadTransform.projectGround(v_circle,0);

  local angle = math.atan2(line.v[idx][1][2]-line.v[idx][2][2],line.v[idx][1][1]-line.v[idx][2][1]);
  if angle<=0 then angle = angle + math.pi end
  self.circle_angle = angle;
  p_vision:add_debug_message("Circle Detected");
p_vision:add_debug_message(string.format("Center Coordinates: (%f, %f)", x_mean, y_mean));
--p_vision:add_debug_message(string.format("V Coordinates: (%f, %f)", v_circle[1], v_circle[2]));
  
  --p_vision:add_debug_message(string.format("circle var:%f, angle:%d",var,angle*180/math.pi));
else
  p_vision:add_debug_message(string.format("circle variance failed: %f\n",var));
--  print(string.format("V: %f", v));
--  print(string.format("A: %f", a));
end

return ;
--end of update
end


local update_shm = function(self, parent_vision)
   vcm.set_circle_detect(self.detect);
    if (self.detect==1) then
    vcm.set_circle_x(self.x_center);
    vcm.set_circle_y(self.y_center);
    vcm.set_circle_var(self.var);
    vcm.set_circle_angle(self.circle_angle);
end
end

local detectCircle = {}

function detectCircle.entry(parent_vision)
print('init Circle detection')
local self = {};
self.update = update;
self.update_shm = update_shm;
self.detect = 0;
return self;
end

return detectCircle
     
