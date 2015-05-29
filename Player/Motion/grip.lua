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
bodyShift = 0;
bodyShift0 = 0;
bodyYaw=0;



qRArm= vector.zeros(3);
-- Starting Arm pose
qLArm0 = Config.walk.qLArm;
qRArm0 = Config.walk.qRArm;

--Pickup
bodyHeight1 = 0.20;
bodyRoll1 = 0*math.pi/180;
bodyTilt1 = 30*math.pi/180;
bodyYaw1 = 0*math.pi/180;
bodyShift1 = 0.05;



--take 2

bodyHeight1 = 0.20;
bodyRoll1 = 0*math.pi/180;
bodyTilt1 = 20*math.pi/180;
bodyShift1 = 0.04;
qLArm1 = math.pi/180*vector.new({40, 30, 0});	
qRArm1 = math.pi/180*vector.new({40, -30,0});	

bodyHeight2 = 0.20;
bodyShift2 = 0.04;
bodyTilt2 = 20*math.pi/180;

qLArm2 = math.pi/180*vector.new({40, 0, 0});	
qRArm2 = math.pi/180*vector.new({40, -0,0});	

--Raise arm 

bodyHeight3 = 0.20;
bodyShift3 = 0.04;
bodyTilt3 = 20*math.pi/180;

bodyShift3 = 0.02;
bodyTilt3 = 10*math.pi/180;



qLArm3 = math.pi/180*vector.new({-90, 0, -90});	
qRArm3 = math.pi/180*vector.new({-90, -0,-90});	

--Repose

bodyHeight4 = 0.23
bodyShift4 = -0.01;
bodyTilt4 = 10*math.pi/180;

qLArm4 = math.pi/180*vector.new({-90, 0, -90});	
qRArm4 = math.pi/180*vector.new({-90, -0,-90});	


bodyTilt0 = 20*math.pi/180;

--------------------





--windup 
bodyHeight6 = 0.25;
bodyShift_windup = -0.015;
bodyShift_throw = 0;
bodyShift6 = 0;
bodyTilt6 = -5*math.pi/180;


qLArm6 = math.pi/180*vector.new({-90, 0, -90});	
qRArm6 = math.pi/180*vector.new({-90, 0,-90});	

--Throw
qLArm7 = math.pi/180*vector.new({60, 15, 0});	
qRArm7 = math.pi/180*vector.new({60, -15,0});	

-- Time


t_grab  = {4.0,4.5,7.0,8.5,9.5};
t_throw = {2.0,3.0,5.0};



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

      ph1 = math.min(1,2*ph);

      ph2 = math.max(0,2*ph - 1);

      bodyHeight = ph1*bodyHeight1 + (1-ph1)*bodyHeight0;
      bodyShift=bodyShift0*(1-ph1)+ bodyShift1*ph1;
      bodyTilt = ph1* bodyTilt1 + (1-ph1)*bodyTilt0;
      qLArm = qLArm1*ph + qLArm0 * (1-ph2);
      qRArm = qRArm1*ph + qRArm0 * (1-ph2);

    elseif t<t_pickup[2] then
    --Grasp
      ph=(t-t_pickup[1])/(t_pickup[2]-t_pickup[1]);
      qLArm= ph * qLArm2 + (1-ph)*qLArm1;
      qRArm= ph * qRArm2 + (1-ph)*qRArm1;

      bodyHeight = ph*bodyHeight2 + (1-ph)*bodyHeight1;
      bodyShift=bodyShift2*ph+ bodyShift1*(1-ph);
      bodyTilt = ph* bodyTilt2 + (1-ph)*bodyTilt1;

    elseif t<t_pickup[3] then
      --repose

     ph=(t-t_pickup[2])/(t_pickup[3]-t_pickup[2]);
     bodyHeight = ph*bodyHeight3 + (1-ph)*bodyHeight2;
     bodyShift=bodyShift3*ph+ bodyShift2*(1-ph);
     bodyTilt = ph* bodyTilt3 + (1-ph)*bodyTilt2;

     qLArm= ph * qLArm3 + (1-ph)*qLArm2;
     qRArm= ph * qRArm3 + (1-ph)*qRArm2;

   elseif t<t_pickup[4] then 
     --Raise hand

     ph=(t-t_pickup[3])/(t_pickup[4]-t_pickup[3]);
     bodyHeight = ph*bodyHeight4 + (1-ph)*bodyHeight3;
     bodyShift=bodyShift4*ph+ bodyShift3*(1-ph);
     bodyTilt = ph* bodyTilt4 + (1-ph)*bodyTilt3;

     qLArm= ph * qLArm4 + (1-ph)*qLArm3;
     qRArm= ph * qRArm4 + (1-ph)*qRArm3;

   elseif t<t_pickup[5] then

     --Stand up
     ph=(t-t_pickup[4])/(t_pickup[5]-t_pickup[4]);

     bodyTilt = ph* bodyTilt0 + (1-ph)*bodyTilt4;
     bodyHeight = ph*bodyHeight0 + (1-ph)*bodyHeight4;
--     bodyShift=bodyShift0*ph+ bodyShift4*(1-ph);

   else
     walk.has_ball=1;
     return "done";
   end
 else	--Throw==1
   local t_pickup = t_throw;
   if t<t_pickup[1] then
     --Windup
     ph=(t)/(t_pickup[1]);
     qLArm= ph * qLArm6 + (1-ph)*qLArm4;
     qRArm= ph * qRArm6 + (1-ph)*qRArm4;
     bodyShift = bodyShift_windup*ph + bodyShift0*(1-ph);
     bodyHeight = ph*bodyHeight6 + (1-ph)*bodyHeight0;
     bodyTilt = ph* bodyTilt6 + (1-ph)*bodyTilt0;


   elseif t<t_pickup[2] then
     --Throw
     ph=(t-t_pickup[1])/(t_pickup[2]-t_pickup[1]);
     qLArm= ph * qLArm7 + (1-ph)*qLArm6;
     qRArm= ph * qRArm7 + (1-ph)*qRArm6;

   elseif t<t_pickup[3] then
	--Reposition
     ph = (t-t_pickup[2])/(t_pickup[3]-t_pickup[2]);
     qLArm = ph * qLArm0 + (1-ph)*qLArm7;
     qRArm = ph * qRArm0 + (1-ph)*qRArm7;

     bodyHeight = ph*bodyHeight0 + (1-ph)*bodyHeight6;
     bodyShift = bodyShift0*ph+ bodyShift_windup*(1-ph);
     bodyTilt = ph* bodyTilt0 + (1-ph)*bodyTilt6;

   else
     walk.has_ball=0;
     return "done";	
   end
  end

  pTorso[3],pTorso[5],pTorso[6] = bodyHeight,bodyTilt,bodyYaw;
  pTorso[4]=bodyRoll;

--print(pTorso[5]*180/math.pi)


  pLLeg[1],pLLeg[2],pLLeg[3],pLLeg[5],pLLeg[6]=uLeft[1],uLeft[2],zLeft,aLeft,uLeft[3];
  pRLeg[1],pRLeg[2],pRLeg[3],pRLeg[5],pRLeg[6]=uRight[1],uRight[2],zRight,aRight,uRight[3];
  uTorso=util.pose_global(vector.new({-footX,0,0}),uBody);  
  pTorso[1],pTorso[2],pTorso[6]=uTorso[1]+bodyShift,uTorso[2],uTorso[3]+bodyYaw;

  motion_legs();
  Body.set_larm_command(qLArm);
  Body.set_rarm_command(qRArm);
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
