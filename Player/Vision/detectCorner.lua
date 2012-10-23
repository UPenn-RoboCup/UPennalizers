module(..., package.seeall);

require('Config');	-- For Ball and Goal Size
require ('wcm')
T_thr = 0.15;
dist_threshold = Config.vision.corner.dist_threshold or 30;
length_threshold = Config.vision.corner.min_length or 6;
min_center_dist = Config.vision.corner.min_center_dist or 1.5;

centercircle_check = Config.vision.corner.centercircle_check or 0;

--get the cross point of two line segements. 
--(x1, y1) (x2, y2) are endpoints for the first line, (x3, y3) (x4, y4) are endpoints for the other line
function get_crosspoint(x1,y1,x2,y2,x3,y3,x4,y4)
  k1 = (y2 - y1)/(x2 - x1);
  k2 = (y4 - y3)/(x4 - x3);
  if (k1 == k2) then
    return {0,0}
  end
  local x = (y3 - y1 + k1*x1 -k2*x3)/(k1 - k2);
  local y = k1*(x - x2) + y2;
  return {x,y};
end



function get_min_dist_line(x1,y1,x2,y2,x,y)
  -- nearest point: k(x1,y1) + (1-k)(x2,y2)
  -- dist: k^2 ((x1-x2)^2+(y1-y2)^2) +  
  --           2k ((x1-x2)(x2-x) + (y1-y2)+(y2-y))  + C
  k = -((x1-x2)*(x2-x) + (y1-y2)*(y2-y))/((x1-x2)^2+(y1-y2)^2);
  if k>T_thr and k<1-T_thr then
    clx = k*x1+(1-k)*x2;
    cly = k*y1+(1-k)*y2;
    dist = (clx-x)^2 + (cly-y)^2;
    return clx,cly,dist;
  else
    return 0,0,999;
  end
end



function get_min_dist(line,i,j)
  xi1=line.v[i][1][1];
  xi2=line.v[i][2][1];
  yi1=line.v[i][1][2];
  yi2=line.v[i][2][2];

  xj1=line.v[j][1][1];
  xj2=line.v[j][2][1];
  yj1=line.v[j][1][2];
  yj2=line.v[j][2][2];

  Cross = get_crosspoint (xi1,yi1,xi2,yi2,xj1,yj1,xj2,yj2);
  
  --L shape detection 
  
  dist11 = (xi1-xj1)*(xi1-xj1) + (yi1-yj1)*(yi1-yj1);
  dist12 = (xi1-xj2)*(xi1-xj2) + (yi1-yj2)*(yi1-yj2);
  dist21 = (xi2-xj1)*(xi2-xj1) + (yi2-yj1)*(yi2-yj1);
  dist22 = (xi2-xj2)*(xi2-xj2) + (yi2-yj2)*(yi2-yj2);

  --T shape detection

  --line i to j1
  xc_i_j1,yc_i_j1,disti_j1=get_min_dist_line(xi1,yi1,xi2,yi2,xj1,yj1);

  --line i to j2
  xc_i_j2,yc_i_j2,disti_j2=get_min_dist_line(xi1,yi1,xi2,yi2,xj2,yj2);

  --line j to i1
  xc_j_i1,yc_j_i1,distj_i1=get_min_dist_line(xj1,yj1,xj2,yj2,xi1,yi1);

  --line j to i2
  xc_j_i2,yc_j_i2,distj_i2=get_min_dist_line(xj1,yj1,xj2,yj2,xi2,yi2);

  mindist = math.min (dist11,dist12,dist21,dist22,
	disti_j1, disti_j2, distj_i1, distj_i2);

  if mindist==dist11 then
    return mindist, 
	Cross,	--corner position
	{xi2,yi2},			--other line endpoint 1
	{xj2,yj2},			--other line endpoint 2
	1,
  'i2j2';			
  elseif mindist==dist12 then
    return mindist, 
	Cross,
	{xi2,yi2},			--other line endpoint 1
	{xj1,yj1},
	1,
  'i2j1';
  elseif mindist==dist21 then
    return mindist,
	Cross,
	{xi1,yi1},			--other line endpoint 1
	{xj2,yj2},
	1,
  'i1j2';
  elseif mindist==dist22 then
    return mindist, 
	Cross,
	{xi1,yi1},			--other line endpoint 1
	{xj1,yj1},
	1,
  'i1j1';	
  elseif mindist==disti_j1 then
    return mindist, 
	Cross,	--corner point
	{xi1,yi1},			
	{xi2,yi2},	
	2,
  'i';	
  elseif mindist==disti_j2 then
    return mindist, 
	Cross,	--corner point
	{xi1,yi1},			
	{xi2,yi2},	
	2,
  'i';	
  elseif mindist==distj_i1 then
    return mindist, 
	Cross,	--corner point
	{xj1,yj1},			
	{xj2,yj2},	
	2,
  'j';	
  else
    return mindist, 
	Cross,	--corner point
	{xj1,yj1},			
	{xj2,yj2},	
	2,
  'j';	
  end
end


function get_line_length(line,i)
  xi1=line.endpoint[i][1];
  xi2=line.endpoint[i][2];
  yi1=line.endpoint[i][3];
  yi2=line.endpoint[i][4];
  return math.sqrt((xi1-xi2)^2+(yi1-yi2)^2);
end

function detect(line)
  --TODO: test line detection
  corner = {};
  corner.detect = 0;

  if line.detect==0 or line.nLines<2 then 
    return corner;
  end

  linepair={};
  linepaircount=0;
  linepairvc={};
  linepairv1={};
  linepairv2={};
  linepairvc0={};
  linepairv10={};
  linepairv20={};
  linepairangle={}
  linepairdist={}
  linepairtype={}

  -- Check perpendicular lines
  vcm.add_debug_message(string.format("\nCorner: total %d lines\n",line.nLines))

  for i=1,line.nLines-1 do
    for j=i+1,line.nLines do
      ang=math.abs(util.mod_angle(line.angle[i]-line.angle[j]));
      if math.abs(ang-math.pi/2)<20*math.pi/180 then
	--Check endpoint distances in labelB
	mindist, vc, v1, v2, cornertype, info = get_min_dist(line,i,j);

        vcm.add_debug_message(string.format(
		"line %d-%d :angle %d mindist %d type %d\n",
		i,j,ang*180/math.pi, mindist,cornertype));

	if mindist<dist_threshold 
	--get_line_length(line,i)>length_threshold and
	--get_line_length(line,j)>length_threshold 
  then 
  	  linepaircount=linepaircount+1;
  	  linepair[linepaircount]={i,j};
	 
    linepairvc[linepaircount]=vc;
	  linepairv1[linepaircount]=v1;
	  linepairv2[linepaircount]=v2;
    
    local LabelCross = get_crosspoint(line.endpoint[i][1], line.endpoint[i][3],line.endpoint[i][2], line.endpoint[i][4],
                                             line.endpoint[j][1], line.endpoint[j][3],line.endpoint[j][2], line.endpoint[j][4]);
    linepairvc0[linepaircount]= LabelCross;

    
    if (cornertype == 1) then
      if (info == 'i1j1' or info == 'i1j2') then
        linepairv10[linepaircount] = {line.endpoint[i][1], line.endpoint[i][3]};
      else
        linepairv10[linepaircount] = {line.endpoint[i][2], line.endpoint[i][4]};
      end

      if (info == 'i1j1' or info == 'i2j1') then
        linepairv20[linepaircount] = {line.endpoint[j][1], line.endpoint[j][3]};
      else
        linepairv20[linepaircount] = {line.endpoint[j][2], line.endpoint[j][4]};
      end  
    else
      if (info == 'i') then
        linepairv10[linepaircount] = {line.endpoint[i][1], line.endpoint[i][3]};
        linepairv20[linepaircount] = {line.endpoint[i][2], line.endpoint[i][4]};
      else
        linepairv10[linepaircount] = {line.endpoint[j][1], line.endpoint[j][3]};
        linepairv20[linepaircount] = {line.endpoint[j][2], line.endpoint[j][4]};
      end
    end
   


    linepairangle[linepaircount]=ang;
	  linepairdist[linepaircount]=mindist;
	  linepairtype[linepaircount]=cornertype;
	end
       end
    end
  end

  if linepaircount==0 then 
    return corner;
  end

  best_corner=1;
  min_corner_dist = 999;

  --Pick the closest corner
  for i=1,linepaircount do
    vc =linepairvc[i];
    --vc = HeadTransform.coordinatesB({vc0[1],vc0[2]});
    --vc = HeadTransform.projectGround(vc,0);
    corner_dist=vc[1]*vc[1]+vc[2]*vc[2];
    if min_corner_dist>corner_dist then
      min_corner_dist = corner_dist;
      best_corner=i;
    end
  end

  corner.linepair=linepair[best_corner]
  corner.type=linepairtype[best_corner];

  vc0=linepairvc0[best_corner];
  v10=linepairv10[best_corner];
  v20=linepairv20[best_corner];
  
  vc=linepairvc[best_corner];
  v1=linepairv1[best_corner];
  v2=linepairv2[best_corner];

--[[
  vc = HeadTransform.coordinatesB({vc0[1],vc0[2]});
  vc = HeadTransform.projectGround(vc,0);

  v1 = HeadTransform.coordinatesB({v10[1],v10[2]});
  v1 = HeadTransform.projectGround(v1,0);

  v2 = HeadTransform.coordinatesB({v20[1],v20[2]});
  v2 = HeadTransform.projectGround(v2,0);
--]]
  --position in labelB
  corner.vc0=vc0;
  corner.v10=v10;
  corner.v20=v20;

  --position in xy
  corner.v = vc;
  corner.v1 = v1;
  corner.v2 = v2;

  --Center circle rejection
  if (centercircle_check == 1) then  
    pose=wcm.get_robot_pose();
    Relative = {corner.v[1], corner.v[2], 0};
    cornerpos = util.pose_global(Relative,pose);
    center_dist = math.sqrt(cornerpos[1]^2+cornerpos[2]^2);
    if center_dist < min_center_dist then     
      vcm.add_debug_message(string.format(
       "Corner: center circle check fail at %.2f\n",center_dist))
      return corner;
    end
  end
  if corner.type==1 then
     vcm.add_debug_message("L-corner detected\n");
     --print (string.format('Lcorner: position: (%f, %f),  \n', vc[1], vc[2]))
     --print (string.format('endpoint1: (%f, %f), endpoint2: (%f, %f).\n', v1[1], v1[2], v2[1], v2[2]))
     --print (string.format('endpoint1 in label: (%f, %f), endpoint2 in label: (%f, %f).\n', v10[1], v10[2], v20[1], v20[2]))
     else
     vcm.add_debug_message("T-corner detected\n");
     --print (string.format('Tcorner: position: (%f, %f), position in lableB: (%f, %f). \n', vc[1], vc[2], vc0[1], vc0[2]))
     
  end

  corner.detect = 1;
  return corner;
end
