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
colorOrange = Config.color.orange;
colorYellow = Config.color.yellow;
colorCyan = Config.color.cyan;
colorField = Config.color.field;
colorWhite = Config.color.white;

enable_robot_detection = Config.vision.enable_robot_detection or 0;
use_tilted_bbox = Config.vision.use_tilted_bbox or 0;

if enable_robot_detection>0 then
  map_div = Config.vision.robot.map_div;
  gamma = Config.vision.robot.gamma;
  gamma_field = Config.vision.robot.gamma_field;
  r_sigma = Config.vision.robot.r_sigma;
  min_r = Config.vision.robot.min_r;
  max_r = Config.vision.robot.max_r;
  min_j = Config.vision.robot.min_j;
else
  map_div = 10;
  gamma = 0.99;
  gamma_field = 0.95;
  r_sigma = 8;
  min_r = 1.0;
  max_r = 4.0;
  min_j = 5;
end

max_gap = 1;

weight=vector.zeros(6*4*map_div*map_div);
updated=vector.zeros(6*4*map_div*map_div);

function update_robot(v)
  pose=wcm.get_robot_pose();
  vGlobal = util.pose_global(v,pose);
  xindex=math.floor((vGlobal[1]+3)*map_div+0.5);
  yindex=math.floor((vGlobal[2]+2)*map_div+0.5);

  --add gaussian update
  --TODO: use correct log-odds
  sigma =  (v[1]^2+v[2]^2)/r_sigma;

  for i=-3,3 do
    for j=-3,3 do
      ix=math.max(1,math.min(6*map_div,i+xindex));
      iy=math.max(1,math.min(4*map_div,j+yindex));
      w=math.exp(-(i*i+j*j)/sigma);
      index=(ix-1)*(4*map_div) + iy;
      weight[index]=math.min(1,weight[index]+w);
    end
  end

end     

function update_weights()

  --Get approximate boundary of current FOV
  v1=HeadTransform.coordinatesB({1,1,0,0});
  v1=HeadTransform.projectGround(v1,0);
  r1=v1[1]^2+v1[2]^2;
  angle1=math.atan2(v1[2],v1[1]);
  
  v2=HeadTransform.coordinatesB({Vision.labelB.m,1,0,0});
  v2=HeadTransform.projectGround(v2,0);
  r2=v2[1]^2+v2[2]^2;
  angle2=math.atan2(v2[2],v2[1]);

  --midpoint in the bottom
  v3=HeadTransform.coordinatesB({Vision.labelB.m/2,Vision.labelB.n,0,0});
  v3=HeadTransform.projectGround(v3,0);
  r3=v3[1]^2+v3[2]^2;

  pose=wcm.get_robot_pose();

  for j=1,4*map_div do     
    for i=1,6*map_div do     
      posx = i/map_div - 3;
      posy = j/map_div - 2;

      angle=math.atan2(posy-pose[2],posx-pose[1])-pose[3];
      r2_pos = (posy-pose[2])^2 + (posx-pose[1])^2;

      within_fov = false;
      if util.mod_angle(angle1-angle)>0 and 
	util.mod_angle(angle2-angle)<0 then
	--get Approx. r and angle
	r_min = r3;
	r_max = (r1+r2)/2;
	if r2_pos<r_max and r2_pos>r_min then
	  within_fov=true;
	end
      end
      index=(i-1)*(4*map_div) + j;
--TODO: use log-odds 
      if updated[index] ==0 then
        if within_fov then
          gamma_field = 0.8;
          weight[index]=weight[index]*gamma_field;
        else
          weight[index]=weight[index]*gamma;
        end
      else
        updated[index]=0;
      end
    end
  end


end

covered={};
blocked={};

function detect(color)
  local robot = {};
  robot.detect = 0;
  count=0;

  if use_tilted_bbox>0 then
    tiltAngle = HeadTransform.getCameraRoll();
  else
    tiltAngle=0;
  end

  fieldRobots = ImageProc.robots(
	Vision.labelB.data,Vision.labelB.m,Vision.labelB.n,
	colorField+colorWhite+colorOrange,tiltAngle,max_gap);

  for i=1,Vision.labelB.m do
    j=fieldRobots[i];
    v=HeadTransform.coordinatesB({i,j,0,0});
    v=HeadTransform.projectGround(v,0);
    r=math.sqrt(v[1]^2+v[2]^2);
    if j>min_j and r>min_r and r<max_r then 
      update_robot(v);
    end
  end

  vcm.set_robot_lowpoint(fieldRobots);
  update_weights();
  update_shm();
end

function update_shm()
  vcm.set_robot_map(weight);
end
