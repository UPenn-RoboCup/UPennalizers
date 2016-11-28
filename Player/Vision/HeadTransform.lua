module(..., package.seeall);
require('Config');

require('Transform');
require('vector');
require('matrix');
require('vcm');
require('mcm');
require('Body');

tHead = Transform.eye();
tHeadInv = Transform.eye();
tNeck = Transform.eye();
camPosition = 0;

camOffsetZ = Config.head.camOffsetZ;
pitchMin = Config.head.pitchMin;
pitchMax = Config.head.pitchMax;
yawMin = Config.head.yawMin;
yawMax = Config.head.yawMax;

cameraPos = Config.head.cameraPos;
cameraAngle = Config.head.cameraAngle;

horizonA = 1;
horizonB = 1;
horizonDir = 0;

local cw, ch = Config.camera.width, Config.camera.height
local sA, scaleB = Config.vision.scaleA, Config.vision.scaleB

neckX    = Config.head.neckX; 
neckZ    = Config.head.neckZ; 
footX    = Config.walk.footX; 

function entry(sel)
  sel = sel or 1;
  labelA = {};

  cw, ch = Config.camera.width, Config.camera.height
  sA, scaleB = Config.vision.scaleA, Config.vision.scaleB

  if type(cw)~='number' then cw = cw[sel] end
  if type(ch)~='number' then ch = ch[sel] end
  if type(sA)~='number' then sA = sA[sel] end
  if type(scaleB)~='number' then scaleB = scaleB[sel] end

  labelA.m = cw / sA;
  labelA.n = ch / sA;

  nxA = labelA.m;
  x0A = 0.5 * (nxA - 1);
  nyA = labelA.n;
  y0A = 0.5 * (nyA - 1);
  focalA = Config.camera.focal_length/(Config.camera.focal_base/nxA);

  labelB = {};
  labelB.m = labelA.m/scaleB;
  labelB.n = labelA.n/scaleB;
  nxB = nxA/scaleB;
  x0B = 0.5 * (nxB-1);
  nyB = nyA/scaleB;
  y0B = 0.5 * (nyB-1);
  focalB = focalA/scaleB;

  -- print('HeadTransform LabelB size: ('..labelB.m..', '..labelB.n..')');
  -- print('HeadTransform LabelA size: ('..labelA.m..', '..labelA.n..')');
end


function update(sel,headAngles)
--[[ 	Axes: {perpendicular to chest button, perpendicular to side, perpendicular to floor}
           When robot is facing you, positive direction is up-front-right.

	Transform.rot_() functions: rotX means rotate around first axis,
				    rotY means rotate around second axis,
				    rotZ means rotate around third axis

	headAngles[_]:	[1] is rotation around third axis,
			[2] is rotation around second axis

			For both, looking down the +direction of the axis, +theta is clockwise and -theta is counter-clockwise

	cameraPos[sel][_]:	All are constants, defining camera[sel] position relative to neck

			  [1] is first axis
				[2] is second axis
				[3] is third axis

	cameraAngle[sel][_]:	All are constants, defining camera[sel] angle relative to first axis

				[1] is rotation around first axis  (is 0)
				[2] is rotation around second axis
				[3] is rotation around third axis  (is 0)

	As of 5/20/16:	footX = 0
			bodyHeight = 0.32, which is the height of the center of mass, approximately at the waist
			bodyTilt = 0
			neckX = 0
			neckZ = 0.14, which is the distance from the CoM to the neck joint
			pitch0 = 0

]]


  --Now bodyHeight, Tilt, camera pitch angle bias are read from vcm 
  bodyHeight=vcm.get_camera_bodyHeight();
  bodyTilt=vcm.get_camera_bodyTilt();
  pitch0 =  mcm.get_headPitchBias();

--[[
  vcm.add_debug_message(string.format(
  "HeadTrasnform update:\n bodyHeight %.2f bodyTilt %d pitch0 %d headangle %d %d\n",
	 bodyHeight, bodyTilt*180/math.pi, pitch0*180/math.pi, 
	 headAngles[1]*180/math.pi, 
	(headAngles[2]+pitch0)*180/math.pi));
--]]
  -- cameras are 0 indexed so add one for use here
  sel = sel + 1;
  -- print(string.format("Gyro body angle around 1st = %.2f\n", Body.get_sensor_imuAngle()[1]));
  -- print(string.format("Gyro body angle around 2nd = %.2f\n", Body.get_sensor_imuAngle()[2]));
  -- print(string.format("Gyro body angle around 3rd = %.2f\n", Body.get_sensor_imuAngle()[3]));
  -- print(string.format("headAngles around 3rd = %.2f\n", headAngles[1]));
  -- print(string.format("headAngles around 2nd = %.2f\n", headAngles[2]));
  -- print(string.format("cameraPos[%d][1] = %.2f\n", sel, cameraPos[sel][1]));
  -- print(string.format("cameraPos[%d][2] = %.2f\n", sel, cameraPos[sel][2]));
  -- print(string.format("cameraPos[%d][3] = %.2f\n\n", sel, cameraPos[sel][3]));

  tneck = Transform.rotX(Body.get_sensor_imuAngle()[1]);
  tneck = tneck*Transform.rotY(Body.get_sensor_imuAngle()[2]);
  tNeck = tneck*Transform.trans(-footX,0,bodyHeight); -- (0,0,.32) , 0.32 is CoM
  tNeck = tNeck*Transform.rotY(bodyTilt);        -- (0)
  tNeck = tNeck*Transform.trans(neckX,0,neckZ); --(0, 0, 0.14), 0.14 is CoM to neck joint

  --pitch0 is Robot specific head angle bias (for OP)
  tNeck = tNeck*Transform.rotZ(headAngles[1])*Transform.rotY(headAngles[2]+pitch0); -- try switching Y and Z !!?????
  tHead = tNeck*Transform.trans(cameraPos[sel][1], cameraPos[sel][2], cameraPos[sel][3]);
  tHead = tHead*Transform.rotY(cameraAngle[sel][2]);
  -- print("footX = "..footX);
  -- print("bodyHeight = "..bodyHeight);
  -- print("bodyTilt = "..bodyTilt);
  -- print("neckX = "..neckX);
  -- print("neckZ = "..neckZ);
  -- print("headAngles[1] = "..headAngles[1]);
  -- print("headAngles[2] = "..headAngles[2]);

  --set tHeadInv for later use
  tHeadInv = Transform.inv(tHead);

  --update camera position
  local vHead=vector.new({0,0,0,1});
  vHead=tHead*vHead;
  vHead=vHead/vHead[4];
  vcm.set_camera_height(vHead[3]);

  -- update horizon
  pa = headAngles[2] + cameraAngle[sel][2]; --+ bodyTilt;
  horizonA = (labelA.n/2.0) - focalA*math.tan(pa) - 2;
  horizonA = math.min(labelA.n, math.max(math.floor(horizonA), 0));
  horizonB = (labelB.n/2.0) - focalB*math.tan(pa) - 1;
  horizonB = math.min(labelB.n, math.max(math.floor(horizonB), 0));
  --print('horizon-- pitch: '..pa..'  A: '..horizonA..'  B: '..horizonB);
  -- horizon direction
  local ref = vector.new({1,0,0,1});
  local p0 = vector.new({0,0,0,1});
  local ref1 = vector.new({-1,0,0,1});
  p0 = tHead*p0;
  ref = tHead*ref;
  ref1 = tHead*ref1;
  ref = ref - p0;
  ref1 = ref1 - p0;
  -- print(ref,' ',ref1);
  local v = {};
  v[1] = -math.abs(ref1[1]) * focalA / 4 + x0A; 
  v[2] = ref1[3] * focalA / 4 + y0A;
  v[3] = math.abs(ref[1]) * focalA / 4 + x0A;
  v[4] = ref[3] * focalA / 4 + y0A;
  horizonDir = math.atan2(ref1[3],math.sqrt(ref1[1]^2+ref1[2]^2));
  --print('horizion angle: '..horizonDir*180/math.pi);
end

function rayIntersectA(c)
  local p0 = vector.new({0,0,0,1.0});
  local p1 = vector.new({focalA,-(c[1]-x0A),-(c[2]-y0A),1.0});

  outrange = 0;
  p1 = tHead * p1;
  local p0 = tNeck * p0;
  local v = p1 - p0;
  -- if t < 0, the x value will be projected behind robot, simply reverse it
  -- since it is always very far away
  if (t < 0) then
    t = -t;
  end
  local t = -p0[3]/v[3];
   -- if t < 0, the x value will be projected behind robot, simply reverse it
  -- since it is always very far away
  if (t < 0) then
    t = -t;
    outrange = 1;
  end 
  local p = p0 + t * v;
  local uBodyOffset = mcm.get_walk_bodyOffset();
  p[1] = p[1] + uBodyOffset[1];
  p[2] = p[2] + uBodyOffset[2];
  return p, outrange;
end


function rayIntersectB(c)
  local p0 = vector.new({0,0,0,1.0});
  local p1 = vector.new({focalB,-(c[1]-x0B),-(c[2]-y0B),1.0});

  outrange = 0;
  p1 = tHead * p1;
  local p0 = tNeck * p0;
  local v = p1 - p0;
  local t = -p0[3]/v[3];
  -- if t < 0, the x value will be projected behind robot, simply reverse it
  -- since it is always very far away
  if (t < 0) then
    t = -t;
    outrange = 1;
  end
  local p = p0 + t * v;
  local uBodyOffset = mcm.get_walk_bodyOffset();
  p[1] = p[1] + uBodyOffset[1];
  p[2] = p[2] + uBodyOffset[2];
  return p, outrange;
end

function exit()
end

function get_horizonA()
  return horizonA;
end

function get_horizonB()
  return horizonB;
end

function get_horizonDir()
  return horizonDir;
end

function coordinatesA(c, scale)
  scale = scale or 1;
  local v = vector.new({focalA,
                       -(c[1] - x0A),
                       -(c[2] - y0A),
                       scale});
  v = tHead*v;
  v = v/v[4];

  return v;
end

-- function getScaleA(c, fixedHeight)
--   local cTrans = {focalA,
--                  -(c[1] - x0A),
--                  -(c[2] - y0A)}
--   local scale = (-tHead[3][1]*cTrans[1] - tHead[3][2]*cTrans[2] - tHead[3][3]*cTrans[3]) / (tHead[3][4] - fixedHeight)
  
--   return scale;
-- end


function coordinatesFixedHeightA(c, fixedHeight)
  -- Return homogeneous coordinates based on assumed height 
  local cTrans = {focalA,
                 -(c[1] - x0A),
                 -(c[2] - y0A)}
  local scale = (-tHead[3][1]*cTrans[1] - tHead[3][2]*cTrans[2] - tHead[3][3]*cTrans[3]) / (tHead[3][4] - fixedHeight)
  
  return coordinatesA(c, scale);
end

function coordinatesB(c, scale)
  scale = scale or 1;
  local v = vector.new({focalB,
                        -(c[1] - x0B),
                        -(c[2] - y0B),
                        scale});
  v = tHead*v;
  v = v/v[4];

  return v;
end

function coordinatesFixedHeightB(c, fixedHeight)
  -- Return homogeneous coordinates based on assumed height 
  local cTrans = {focalB,
                 -(c[1] - x0B),
                 -(c[2] - y0B)}
  local scale = (-tHead[3][1]*cTrans[1] - tHead[3][2]*cTrans[2] - tHead[3][3]*cTrans[3]) / (tHead[3][4] - fixedHeight)
  
  return coordinatesB(c, scale);
end

function ikineCam(x, y, z, sel)
  yaw,pitch=ikineCam0(x,y,z,sel);
  yaw = math.min(math.max(yaw, yawMin), yawMax);
  pitch = math.min(math.max(pitch, pitchMin), pitchMax);
  return yaw,pitch;
end

--Camera IK without headangle limit
function ikineCam0(x,y,z,sel)
  --Bottom camera by default (cameras are 0 indexed so add 1)
  sel = (sel or 0) + 1;

  bodyHeight=vcm.get_camera_bodyHeight();
  bodyTilt=vcm.get_camera_bodyTilt();
  pitch0 =  mcm.get_headPitchBias();


  --Look at ground by default
  z = z or 0;

  --Cancel out the neck X and Z offset 
  v = getNeckOffset();
  x = x-v[1]; 
  z = z-v[3]; 

  --Cancel out body tilt angle
  v = Transform.rotY(-bodyTilt)*vector.new({x,y,z,1});
  v=v/v[4];

  x,y,z=v[1],v[2],v[3];
  local yaw = math.atan2(y, x);

  local norm = math.sqrt(x^2 + y^2 + z^2);
--  local pitch = math.asin(-z/(norm + 1E-10));

  --new IKcam that takes camera offset into account
  -------------------------------------------------------------
  -- sin(pitch)x + cos (pitch) z = c , c=camera z offset
  -- pitch = atan2(x,z) - acos(b/r),  r= sqrt(x^2+z^2)
  -- r*sin(pitch) = z *cos(pitch) + c, 
  -------------------------------------------------------------
  local c=cameraPos[sel][3];
  local r = math.sqrt(x^2+y^2);
  local d = math.sqrt(r^2+z^2);
  local p0 = math.atan2(r,z) - math.acos(c/(d + 1E-10));

  pitch=p0;
  pitch = pitch - cameraAngle[sel][2]- pitch0;
  return yaw, pitch;
end

function getCameraRoll()
  --Use camera IK to calculate how much the image is tilted
  headAngles = Body.get_head_position();
  r=3.0;z0=0;z1=0.7;
  x0=r*math.cos(headAngles[1]);
  y0=r*math.sin(headAngles[1]);
  yaw1, pitch1=ikineCam0(x0,y0,z0,bottom);
  yaw2, pitch2=ikineCam0(x0,y0,z1,bottom);
  tiltAngle = math.atan( (yaw2-yaw1)/(pitch1-pitch2) ); 
  return tiltAngle;
end

function getCameraOffset() 
    local v=vector.new({0,0,0,1});
    v=tHead*v;
    v=v/v[4];
    return v;
end

function getNeckOffset()
  bodyHeight=vcm.get_camera_bodyHeight();
  bodyTilt=vcm.get_camera_bodyTilt();

  --SJ: calculate tNeck here
  --So that we can use this w/o run update
  --(for test_vision)
  local tNeck0 = Transform.trans(-footX,0,bodyHeight); 
  tNeck0 = tNeck0*Transform.rotY(bodyTilt);
  tNeck0 = tNeck0*Transform.trans(neckX,0,neckZ);
  local v=vector.new({0,0,0,1});
  v=tNeck0*v;
  v=v/v[4];
  return v;
end

---
--Project 3d point to level plane with some height
--@param targetheight The heigh of horizontal plane to project onto
--@param v 3 dimensional point to project
function projectGround(v, targetheight)
  local cameraOffset = tHead * vector.new({0, 0, 0, 1}); -- used to be: getCameraOffset();, should be same
  local targetheight = targetheight or 0;
  local vout = vector.new(v);

  vout = tHeadInv * vout;
  vout = vout * ((cameraOffset[3] - targetheight) / (cameraOffset[3] - v[3]));
  vout[4] = 1;
  vout = tHead * vout;
  return vout;
end