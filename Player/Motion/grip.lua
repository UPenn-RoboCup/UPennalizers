-- Stabilized grip motion state
-- by SJ, edited by Steve

module(..., package.seeall);

require('Body')
require('keyframe')
require('walk')
require('vector')
require('Config')
require 'util'

-- These should be Config variables...
footX = Config.walk.footX;
footY = Config.walk.footY;
supportX = Config.walk.supportX;

bodyTilt = Config.walk.bodyTilt;
--bodyTilt1=40*math.pi/180;
--bodyTilt1=20*math.pi/180; --With long hand
bodyTilt0 = Config.walk.bodyTilt;
bodyTilt1 = 20*math.pi/180;






bodyHeight = Config.walk.bodyHeight;
bodyHeight0 = bodyHeight;

bodyHeight1 = 0.20;
bodyHeight2 = 0.22;

bodyShift = 0;
bodyShift0 = 0;
bodyShift1 = 0.0; --with long hand
bodyShift2 = -0.01;
bodyShift3 = 0;

bodyYaw=0;
bodyYaw1=-30*math.pi/180;



bodyHeight3 = 0.24;
bodyShift_windup = -0.015;
bodyShift_throw = 0;

-- Times
t_throw = {1.0,2.0,3.0};
t_throw = {2.0,3.0,4.0};


t_grab  = {1.2,2.5,3.0,4.0,5.0};

qRArm= vector.zeros(3);
-- Starting Arm pose
qLArm0 = Config.walk.qLArm;
qRArm0 = Config.walk.qRArm;

--Pickup
--30 degree: maximum open
qLArm1 = math.pi/180*vector.new({55, 5,30});
qRArm1 = math.pi/180*vector.new({90,-8,-40});

--Grasp
qLArm2 = math.pi/180*vector.new({55, 5,-40});	
qRArm2 = math.pi/180*vector.new({90, -8,40});	




bodyHeight1 = 0.20;
bodyShift1 = 0.0; --with long hand
bodyShift2 = -0.01;
bodyTilt1 = 20*math.pi/180;
--pickup
qLArm1 = math.pi/180*vector.new({55, 5,30});
--grasp
qLArm2 = math.pi/180*vector.new({55, 5,-40});	



--try 2
bodyHeight1 = 0.20;

bodyRoll1 = -20*math.pi/180;
bodyTilt1 = 10*math.pi/180;

bodyShift1 = 0.01;
bodyHeight1 = 0.19;

qLArm1 = math.pi/180*vector.new({45, 15, 40});
qLArm2 = math.pi/180*vector.new({45, 15,-40});	

qRArm1 = math.pi/180*vector.new({170, -15,0});
qRArm2 = math.pi/180*vector.new({170, -15,0});	


bodyHeight2 = 0.21;
bodyShift2 = -0.01;


--try 3

bodyHeight1 = 0.20;

bodyRoll1 = -20*math.pi/180;
bodyTilt1 = 0*math.pi/180;
bodyYaw1=0*math.pi/180;


bodyShift1 = 0.0;

qLArm1 = math.pi/180*vector.new({90, 30, 35});
qLArm2 = math.pi/180*vector.new({90, 30,-40});	
qRArm1 = math.pi/180*vector.new({170, -15,0});
qRArm2 = math.pi/180*vector.new({170, -15,0});	
bodyHeight1 = 0.20;
bodyHeight2 = 0.21;
bodyShift2 = -0.01;


t_grab  = {1.2,2.0,2.5,3.0,3.5};

t_throw = {1.0,2.0,3.0};








--Windup
qLArm3 = math.pi/180*vector.new({-80,5,-40});	
qRArm3 = qRArm0;

--Throw
qLArm4 = math.pi/180*vector.new({0,5,35});	
qRArm4 = qRArm0;




--[[
qLArm4 = math.pi/180*vector.new({20,20,-0});
qRArm4 = math.pi/180*vector.new({20,-20,-0});
--]]

--[[
qGrip0 = 0*math.pi/180;
qGrip1 = 45*math.pi/180;
qGrip2 = 60*math.pi/180;
--]]
qGrip0 = -2400*math.pi/180;
qGrip1 = 0*math.pi/180;
qGrip2 = 0*math.pi/180;
qGrip = 0;

-- Shifting and compensation parameters
ankleShift=vector.new({0, 0});
kneeShift=0;
hipShift=vector.new({0,0});

ankleImuParamX=Config.kick.ankleImuParamX;
ankleImuParamY=Config.kick.ankleImuParamY;
kneeImuParamX=Config.kick.kneeImuParamX;
hipImuParamY=Config.kick.hipImuParamY;
armImuParamX=Config.kick.armImuParamX;
armImuParamY=Config.kick.armImuParamX;

qLHipRollCompensation=0;
qRHipRollCompensation=0;
qLHipPitchCompensation=0;
qRHipPitchCompensation=0;

pTorso = vector.new({0, 0, bodyHeight, 0,bodyTilt,0});
pLLeg=vector.zeros(6);
pRLeg=vector.zeros(6);

-- Pickup or throw
throw=0;
active=false;

--[[
walk.starting_foot=1; --after left kick, start walking with left foot
walk.starting_foot=0; 
--]]

function entry()
  print("Motion SM:".._NAME.." entry");
  walk.stop();
  started = false;
  active = true;
  -- disable joint encoder reading
  Body.set_syncread_enable(0);

  uLeft   = vector.new({-supportX, footY, 0});
  uRight  = vector.new({-supportX, -footY, 0});
  uLeft1  = vector.new({-supportX, footY, 0});
  uRight1 = vector.new({-supportX, -footY, 0});

  uBody  = vector.new({0,0,0});
  uBody0 = vector.new({0,0,0});
  uBody1 = vector.new({0,0,0});

  zLeft,  zRight  = 0,0;
  zLeft1, zRight1 = 0,0;
  aLeft,  aRight  = 0,0;
  aLeft1, aRight1 = 0,0;
end

function update()
  if (not started and walk.active) then
    walk.update();
    return;
  elseif not started then
    started=true;
    Body.set_head_hardness(.5);
    if throw==0 then
      Body.set_larm_hardness({0.5,.5,1});
      Body.set_rarm_hardness({0.5,.5,1});
    else
      Body.set_larm_hardness({1,1,1});
      Body.set_rarm_hardness({1,1,1});
    end
    Body.set_lleg_hardness(1);
    Body.set_rleg_hardness(1);
    t0 = Body.get_time();
  end


  local t=Body.get_time();
  t=t-t0;
  if throw==0 then
    local t_pickup = t_grab;
    if t<t_pickup[1] then 
      --Open grip and extend hand, lower body
      ph = t/t_pickup[1];
      qLArm = qLArm1*1.0;
      qRArm = qRArm1*1.0;
      bodyHeight = ph*bodyHeight1 + (1-ph)*bodyHeight0;
      bodyShift=bodyShift0*(1-ph)+ bodyShift1*ph;
      bodyYaw=ph*bodyYaw1;
      bodyTilt = ph* bodyTilt1 + (1-ph)*bodyTilt0;
      bodyRoll = ph* bodyRoll1;


    elseif t<t_pickup[2] then
   --bend front
      ph=(t-t_pickup[1])/(t_pickup[2]-t_pickup[1]);

    elseif t<t_pickup[3] then
    --Grasp
      ph=(t-t_pickup[2])/(t_pickup[3]-t_pickup[2]);
      qLArm= ph * qLArm2 + (1-ph)*qLArm1;
      qRArm= ph * qRArm2 + (1-ph)*qRArm1;

    elseif t<t_pickup[4] then
      --repose
     ph=(t-t_pickup[3])/(t_pickup[4]-t_pickup[3]);

     bodyTilt = ph* bodyTilt0 + (1-ph)*bodyTilt1;
     bodyHeight = ph*bodyHeight2 + (1-ph)*bodyHeight1;
     bodyShift=bodyShift2*ph+ bodyShift1*(1-ph);
     bodyYaw=(1-ph)*bodyYaw1;

     qLArm= ph * qLArm0 + (1-ph)*qLArm2;
     qRArm= ph * qRArm0 + (1-ph)*qRArm2;

      bodyRoll = (1-ph)* bodyRoll1;

   elseif t<t_pickup[5] then
     --Stand up
     ph=(t-t_pickup[4])/(t_pickup[5]-t_pickup[4]);
     bodyHeight = ph*bodyHeight0 + (1-ph)*bodyHeight2;
   --	qRArm= ph * qRArm0 + (1-ph)*qRArm1;
     bodyShift=bodyShift3*ph+ bodyShift2*(1-ph);
   else
     walk.has_ball=1;
     return "done";
   end
 else	--Throw==1
   local t_pickup = t_throw;
   if t<t_pickup[1] then
     --Windup
     ph=(t)/(t_pickup[1]);
     qLArm= ph * qLArm3 + (1-ph)*qLArm2;
     qRArm= ph * qRArm3 + (1-ph)*qRArm2;
     bodyShift = bodyShift_windup*ph + bodyShift3*(1-ph);

     bodyHeight = ph*bodyHeight3 + (1-ph)*bodyHeight0;


   elseif t<t_pickup[2] then
     --Throw
     ph=(t-t_pickup[1])/(t_pickup[2]-t_pickup[1]);
-- For speed, just command the final position
--[[
     if ph < 0.1 then
       qLArm[3] = qLArm2[3];
     end
    --]] 

--bodyShift = bodyShift3;
   elseif t<t_pickup[3] then
	--Reposition
     ph = (t-t_pickup[2])/(t_pickup[3]-t_pickup[2]);
     qLArm = ph * qLArm0 + (1-ph)*qLArm4;
     qRArm = ph * qRArm0 + (1-ph)*qRArm4;
     qGrip = ph*qGrip1 + (1-ph)*qGrip2;

     bodyHeight = ph*bodyHeight0 + (1-ph)*bodyHeight3;

	--bodyShift = bodyShift0*ph+ bodyShift2*(1-ph);
   else
     walk.has_ball=0;
     return "done";	
   end
  end

  pTorso[3],pTorso[5],pTorso[6] = bodyHeight,bodyTilt,bodyYaw;
  pTorso[4]=bodyRoll;

  pLLeg[1],pLLeg[2],pLLeg[3],pLLeg[5],pLLeg[6]=uLeft[1],uLeft[2],zLeft,aLeft,uLeft[3];
  pRLeg[1],pRLeg[2],pRLeg[3],pRLeg[5],pRLeg[6]=uRight[1],uRight[2],zRight,aRight,uRight[3];
  uTorso=util.pose_global(vector.new({-footX,0,0}),uBody);
  
pTorso[1],pTorso[2],pTorso[6]=uTorso[1]+bodyShift,uTorso[2],uTorso[3]+bodyYaw;
  motion_legs();
  Body.set_larm_command(qLArm);
  Body.set_rarm_command(qRArm);
  Body.set_aux_command(qGrip);
end


function motion_legs()

--Ankle stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyrRPY();

  gyro_roll=imuGyr[1];
  gyro_pitch=imuGyr[2];

  ankleShiftX=util.procFunc(gyro_pitch*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4]);
  ankleShiftY=util.procFunc(gyro_roll*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4]);
  kneeShiftX=util.procFunc(gyro_pitch*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4]);
  hipShiftY=util.procFunc(gyro_roll*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4]);

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);
  kneeShift=kneeShift+kneeImuParamX[1]*(kneeShiftX-kneeShift);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);

  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso,0);

  qLegs[4] = qLegs[4] + kneeShift;
  qLegs[5] = qLegs[5]  + ankleShift[1];
  qLegs[10] = qLegs[10] + kneeShift;
  qLegs[11] = qLegs[11]  + ankleShift[1];

  qLegs[2] = qLegs[2] + qLHipRollCompensation+hipShift[2];
  qLegs[8] = qLegs[8] + qRHipRollCompensation+hipShift[2];

  qLegs[6] = qLegs[6] + ankleShift[2];
  qLegs[12] = qLegs[12] + ankleShift[2];
  Body.set_lleg_command(qLegs);
end


function exit()
  print("Pickup exit");
  active = false;
  walk.active = true;
  Body.set_lleg_slope(0);
  Body.set_rleg_slope(0);
end

function set_distance(xdist)
  local dist = math.min(0.15,math.max(0,xdist));

  --[[
  print("===Ball X distance:",dist)

  if dist<0.04 then
  --For 0cm
	bodyTiltTarget=0*math.pi/180;
	qRArm1 = math.pi/180*vector.new({90,-15,0});	--Pickup
	elseif dist<0.08 then
	--For 6cm
	bodyTiltTarget=10*math.pi/180;
	qRArm1 = math.pi/180*vector.new({70,-10,0});	--Pickup
	elseif dist<0.12 then
	--For 10cm
	bodyTiltTarget=20*math.pi/180;
	qRArm1 = math.pi/180*vector.new({50,-10,0});	--Pickup
	elseif dist<0.14 then
	--For 12cm
	bodyTiltTarget=30*math.pi/180;
	qRArm1 = math.pi/180*vector.new({30,0,0});	--Pickup
	else
	--For 16cm
	bodyTiltTarget=45*math.pi/180;
	qRArm1 = math.pi/180*vector.new({20,0,0});	--Pickup
	end

	--]]

end
