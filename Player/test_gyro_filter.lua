--File to test complimentary filter for Nao

--init file
cwd = cwd or os.getenv('PWD')
package.path = cwd.."/?.lua;"..package.path;
require('init')
require('Config');
require('shm')
require('Body')
require('vector')
require('getch')
require('Motion');
require('walk');
require('dive');
require('Speak')
require('util');
require('mcm');
local matrix = require('matrix');
darwin = false;
webots = false;
init = false;
calibrating=false;
ready=false;
getch.enableblock(1);

--initialization for imu filter
imu_init = false;
q_hat = matrix:new(4,1);
b_hat = matrix:new(3,1);
Vg0 = matrix:new(3,1);
matrix.setelement(Vg0,3,1,-1); --world gravity vector direction
t_old = Body.get_time();
haveIfallen = 0;
--gain parameters
KP = 1;
KI = 0.2;
K1 = 1;


-- initialize state machines
Motion.entry();
Body.set_head_hardness({0.4,0.4});

-- init main loop
lcount=0
count = 0;
vcmcount=0;
local t0=Body.get_time();
local last_update_time=t0;
local headangle=vector.new({0,10*math.pi/180});
local headsm_running=0;
local bodysm_running=0;
local last_vision_upfasfdsaasfgate_time=t0;
targetvel=vector.zeros(3);
t_update=2;

Motion.fall_check=0;
broadcast_enable=0;
ballcount,visioncount,imagecount=0,0,0;
hires_broadcast=0;
cameraparamcount=1;
broadcast_count=0;
buttontime=0;

paramsets={
--Name default div min
	{"bodyHeight",Config.walk.bodyHeight,0.005, 0.25},
	{"footY",Config.walk.footY,0.005, 			0.04},
	{"supportX",Config.walk.supportX,0.005, 	0},
	{"tStep",Config.walk.tStep,0.005,			0.24},
	{"supportY",Config.walk.supportY,0.005,		0},
	{"tZmp",Config.walk.tZmp,0.0025,			0.15},
	{"stepHeight",Config.walk.stepHeight,0.00125,	0.01},
	{"phSingleRatio",Config.walk.phSingleRatio,0.01,	0.01},
	{"hardnessSupport",Config.walk.hardnessSupport,0.05, 0.3},
	{"hardnessSwing",Config.walk.hardnessSwing,0.05, 	0.3},
	{"hipRollCompensation",Config.walk.hipRollCompensation,0.005, 0},
	{"zmp_type",Config.walk.zmp_type,1, 0},
}

currentparam = 1

--get keyboard inputs and do stuff with them
function process_keyinput()
  local str = getch.get()
  if #str>0 then 
  	byte = string.byte(str,1)

		if byte==string.byte("q") then	
		  currentparam = (currentparam+(#paramsets-2)) %(#paramsets)+1

		  print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))
		elseif byte==string.byte("w") then			
			print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))
		elseif byte==string.byte("e") then			
			currentparam = currentparam %(#paramsets)+1
		  print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))
		elseif byte==string.byte("[") then	
			Config.walk[paramsets[currentparam][1]]=
			math.max(paramsets[currentparam][4],
				Config.walk[paramsets[currentparam][1]]-paramsets[currentparam][3]
				)	
			print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))

		elseif byte==string.byte("]") then	
			Config.walk[paramsets[currentparam][1]]=
				math.max(paramsets[currentparam][4],
				Config.walk[paramsets[currentparam][1]]+paramsets[currentparam][3]
				)	
			print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))

		elseif byte==string.byte("1") then	kick.set_kick("kickForwardLeft"); Motion.event("kick");
		elseif byte==string.byte("2") then	 kick.set_kick("kickForwardRight"); Motion.event("kick");
		elseif byte==string.byte("3") then  walk.doStepKickLeft();
		elseif byte==string.byte("4") then  walk.doStepKickRight();
	  elseif byte==string.byte("5") then  walk.doWalkKickLeft();
	  elseif byte==string.byte("6") then  walk.doWalkKickRight();
	  elseif byte==string.byte("t") then  walk.doSideKickLeft();
	  elseif byte==string.byte("y") then  walk.doSideKickRight();
	  elseif byte==string.byte("7") then	Motion.event("sit");
		elseif byte==string.byte("8") then	
			if walk.active then walk.stop() end
			Motion.event("standup")
		elseif byte==string.byte("9") then	Motion.event("walk"); walk.start()
		else
			-- Walk velocity setting
			if byte==string.byte("i") then	targetvel[1]=targetvel[1]+0.02;
			elseif byte==string.byte("j") then	targetvel[3]=targetvel[3]+0.1;
			elseif byte==string.byte("k") then	targetvel[1],targetvel[2],targetvel[3]=0,0,0;
			elseif byte==string.byte("l") then	targetvel[3]=targetvel[3]-0.1;
			elseif byte==string.byte(",") then	targetvel[1]=targetvel[1]-0.02;
			elseif byte==string.byte("h") then	targetvel[2]=targetvel[2]+0.02;
			elseif byte==string.byte(";") then	targetvel[2]=targetvel[2]-0.02;
		  end
			walk.set_velocity(unpack(targetvel));
		end
	end

end


--run update at each step
function update()
  count = count + 1;
  --Update battery info
  wcm.set_robot_battery_level(Body.get_battery_level());
  --Set game state to SET to prevent particle resetting
  gcm.set_game_state(1);

  if (not init)  then
    if (calibrating) then
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        calibrating = false;
        ready = true;
      end
    elseif (ready) then
      init = true;
    else
      if (count % 20 == 0) then
--start calibrating without waiting 
--        if (Body.get_change_state() == 1) then
          Speak.talk('Calibrating');
          calibrating = true;
--        end
      end
      -- toggle state indicator
      if (count % 100 == 0) then
        initToggle = not initToggle;
        if (initToggle) then
          Body.set_indicator_state({1,1,1}); 
        else
          Body.set_indicator_state({0,0,0});
        end
      end
    end
  else
    -- update state machines 
    process_keyinput();    
    Motion.update();
    Body.update();
  end
  local dcount = 50;
  if (count % 50 == 0) then
--    print('fps: '..(50 / (unix.time() - tUpdate)));
    tUpdate = unix.time();
    -- update battery indicator
    Body.set_indicator_batteryLevel(Body.get_battery_level());
  end
  
  -- check if the last update completed without errors
  lcount = lcount + 1;
  if (count ~= lcount) then
    print('count: '..count)
    print('lcount: '..lcount)
    Speak.talk('missed cycle');
    lcount = count;
  end
end


-- this is the main thing this script is testing
-- based on "Nonlinear Complimentary Filters on the Special Orthogonal Group" by Mahony, Hamel, and Pflimlin
function imu_filter()

	--initialize imu
	if (not imu_init) then
		
		--get current gravity vector and normalize to 1
		Vg = matrix:new(Body.get_sensor_imuAcc());
	        Vg = matrix.mulnum(Vg,1/matrix.normf(Vg));
		
		--initial rotation matrix based on gravity vector measurement with zero yaw
		R_hat = vecs2rot(Vg,Vg0);
		q_hat = rot2quat(R_hat);
		phi,theta,psi = quat2eul(q_hat);
		psi = 0;
		q_hat = eul2quat(phi,theta,psi);		

		--debug	
		print('Init:')	
		--matrix.print(R_hat);
		phi = math.floor(phi);
		theta = math.floor(theta);
		psi = math.floor(psi);
		print('Euler Angles:',phi,theta,psi);
		--matrix.print(q_hat);

		t_old = Body.get_time();
		imu_init = true;
	
	else --run update step to filter

		--get measurements
		--normalized gravity vector
		Vg = matrix:new(Body.get_sensor_imuAcc());
	        Vg = matrix.mulnum(Vg,1/matrix.normf(Vg));
		
		--angular velocities, get function gives deg/s and wrong direction for x and z 
		
		gyroScale = 1/3;
		Omg = matrix:new(Body.get_sensor_imuGyr());
		Omg = matrix.mulnum(Omg,gyroScale*math.pi/180);		
		matrix.setelement(Omg,1,1,-matrix.getelement(Omg,1,1))
		matrix.setelement(Omg,3,1,-matrix.getelement(Omg,3,1))

		--time
		t_cur = Body.get_time();
		t_delta = t_cur - t_old;
		t_old = t_cur;


		--run filter computations
		--get gravity vector estimate
		R_hat = quat2rot(q_hat)
		Vg_est = matrix.mul(matrix.transpose(R_hat),Vg0);		

		--compute w_meas
		tmp1 = matrix.mul(Vg,matrix.transpose(Vg_est));
		tmp2 = matrix.mul(Vg_est,matrix.transpose(Vg));
		tmp3 = matrix.mulnum(matrix.sub(tmp1,tmp2),K1/2);
		w_meas = matrix.mulnum(unskew(tmp3),-1);
		
		b_hat_dot = matrix.mulnum(w_meas,-KI);
		
		--compute q_hat_dot
		tmp4 = matrix.sub(Omg,b_hat);
		tmp5 = matrix.mulnum(w_meas,KP);
		tmp6 = matrix.add(tmp4,tmp5);
		p = matrix:new(1,1)
		p = matrix.concatv(p,tmp6);
		q_hat_dot = quatmult(matrix.mulnum(q_hat,0.5),p);
		
		--euler integration
		b_hat = matrix.add(b_hat,matrix.mulnum(b_hat_dot,t_delta));	
		q_hat = matrix.add(q_hat,matrix.mulnum(q_hat_dot,t_delta));	
		q_hat = quatNorm(q_hat);

		
		--fall check to reset yaw bias
		if (mcm.get_walk_isFallDown()==1) then
			haveIfallen = 1;
		else
			if ((haveIfallen==1) and (mcm.get_walk_isGetupDone() == 1)) then --we fell but are back up according to mcm
				matrix.setelement(b_hat,3,1,0); --reset yaw bias
				haveIfallen = 0;
			end
		end
			

	end

	--debug printouts
	if (count % 100 == 0) then

		--print('Delta t:', t_delta);

		print('w_meas');
		matrix.print(w_meas);

		print('b_hat:')
		matrix.print(b_hat);

		--print('b_hat_dot:');
		--matrix.print(b_hat_dot);

		print('Omg:');
		matrix.print(Omg);

		print('q_hat:')
		matrix.print(q_hat);
		
		--print('q_hat_dot:');
		--matrix.print(q_hat_dot);

		phi,theta,psi = quat2eul(q_hat);
		phi = round(phi,2);
		theta = round(theta,2);
		psi = round(psi,2);
		print('Euler Angles:',phi,theta,psi);

		phi,theta,psi = unpack(Body.get_sensor_imuAngle());
		phi = round(phi*180/math.pi,2);
		theta = round(theta*180/math.pi,2);
		psi = round(psi*180/math.pi,2);
		print('Nao Angles:',phi,theta,psi);

		print('Getup Done:',mcm.get_walk_isGetupDone());
		print('Fallen:',haveIfallen);
	end

end


--simple round function from lua wiki
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


--create skew sym matrix from 3x1 vector
function skew(vec)
	
	mtx = matrix:new(3,3);
	v1 = matrix.getelement(vec,1,1);
	v2 = matrix.getelement(vec,2,1);
	v3 = matrix.getelement(vec,3,1);
	matrix.setelement(mtx,1,2,-v3);
	matrix.setelement(mtx,1,3, v2);
	matrix.setelement(mtx,2,1, v3);
	matrix.setelement(mtx,2,3,-v1);
	matrix.setelement(mtx,3,1,-v2);
	matrix.setelement(mtx,3,2, v1);
	return mtx
end

--create vector from skew symetric matrix
function unskew(M)

	vec = matrix:new(3,1);
	v1 = matrix.getelement(M,3,2);
	v2 = matrix.getelement(M,1,3);
	v3 = matrix.getelement(M,2,1);
	matrix.setelement(vec,1,1,v1);
	matrix.setelement(vec,2,1,v2);
	matrix.setelement(vec,3,1,v3);

	return vec
end

--Use rodrigues formula to build rotation matrix from two vectors
--using formula from http://math.stackexchange.com/questions/180418/calculate-rotation-matrix-to-align-vector-a-to-vector-b-in-3d
function vecs2rot(vec1, vec2)
	
	I = matrix:new(3,"I");
	v = matrix.cross(vec1,vec2);
	s = matrix.normf(v);
	c = matrix.scalar(vec1,vec2);
	Vx = skew(v);
	tmp1 = matrix.add(I,Vx);
	tmp2 = matrix.mul(Vx,Vx);
	tmp3 = matrix.mulnum(tmp2,(1-c)/(s*s));
	R = matrix.add(tmp1,tmp3); 
	return R 
end

--convert roation matrix to quaterion
function rot2quat(R)
	
	--get all matrix elements
	r11 = matrix.getelement(R,1,1);
	r12 = matrix.getelement(R,1,2);
	r13 = matrix.getelement(R,1,3);
	r21 = matrix.getelement(R,2,1);
	r22 = matrix.getelement(R,2,2);
	r23 = matrix.getelement(R,2,3);
	r31 = matrix.getelement(R,3,1);
	r32 = matrix.getelement(R,3,2);
	r33 = matrix.getelement(R,3,3);

	--compute and check trace to make sure we use the best equations
	tr = r11+r22+r33;
	if (tr>0) then
		S = math.sqrt(1+tr)*2;
		qw = 0.25*S;
		qx = (r32-r23)/S;
		qy = (r13-r31)/S;
		qz = (r21-r12)/S;
	elseif ((r11>r22) and (r11>r33)) then
		S = math.sqrt(1+r11-r22-r33)*2;
		qw = (r32-r23)/S;
		qx = 0.25*S;
		qy = (r12+r21)/S;
		qz = (r13+r31)/S;
	elseif (r22>r33)  then
		S = math.sqrt(1+r22-r11-r33)*2;
		qw = (r13-r31)/S;
		qx = (r12+r21)/S;
		qy = 0.25*S;
		qz = (r23+r32)/S;
	else  
		S = math.sqrt(1+r33-r22-r11)*2;
		qw = (r21-r12)/S;
		qx = (r13+r31)/S;
		qy = (r23+r32)/S;
		qz = 0.25*S;
	end
	
	q = matrix:new(4,1);
	matrix.setelement(q,1,1,qw);
	matrix.setelement(q,2,1,qx);
	matrix.setelement(q,3,1,qy);
	matrix.setelement(q,4,1,qz);
	q = quatNorm(q);
	return q
end


--normalize quaterion
function quatNorm(q)

	qNorm = matrix.mulnum(q,1/matrix.normf(q));
	return qNorm
end


--quaternion to euler angles
function quat2eul(q)
	
	--get values from q
	qw = matrix.getelement(q,1,1);
	qx = matrix.getelement(q,2,1);
	qy = matrix.getelement(q,3,1);
	qz = matrix.getelement(q,4,1);

	--do math, this assumes ZYX convention
	psi = math.atan2(2*(qx*qy+qw*qz),(qw^2+qx^2-qy^2-qz^2))*180/math.pi;
	theta = math.asin(-2*(qx*qz-qw*qy))*180/math.pi;
	phi = math.atan2(2*(qy*qz+qw*qx),(qw^2-qx^2-qy^2+qz^2))*180/math.pi;

	return phi,theta,psi

end


--convert ZYX euler angles to quaternion
function eul2quat(phi,theta,psi)

	--convert to radians
	phi = phi*math.pi/180;
	theta = theta*math.pi/180;
	psi = psi*math.pi/180;
	
	--do trig on half angles
	c1 = math.cos(psi/2);
	c2 = math.cos(theta/2);
	c3 = math.cos(phi/2);
	s1 = math.sin(psi/2);
	s2 = math.sin(theta/2);
	s3 = math.sin(phi/2)

	--do quaterion computations	
	qw = c1*c2*c3+s1*s2*s3;
	qx = c1*c2*s3-s1*s2*c3;
	qy = c1*s2*c3+s1*c2*s3;
	qz = s1*c2*c3-c1*s2*s3;

	--build quaterion to return
	q = matrix:new(4,1);
	matrix.setelement(q,1,1,qw);
	matrix.setelement(q,2,1,qx);
	matrix.setelement(q,3,1,qy);
	matrix.setelement(q,4,1,qz);
	q = quatNorm(q);
	return q
	
end


--convert quaterion into rotation matrix
function quat2rot(q)

	--get values from q
	q0 = matrix.getelement(q,1,1);
	q1 = matrix.getelement(q,2,1);
	q2 = matrix.getelement(q,3,1);
	q3 = matrix.getelement(q,4,1);

	--build r values
	r11 = q0^2+q1^2-q2^2-q3^2;
	r12 = 2*(q1*q2 - q0*q3);
	r13 = 2*(q0*q2 + q1*q3);
	r21 = 2*(q1*q2 + q0*q3);
	r22 = q0^2-q1^2+q2^2-q3^2;
	r23 = 2*(q2*q3 - q0*q1);
	r31 = 2*(q1*q3 - q0*q2);
	r32 = 2*(q0*q1 + q2*q3);
	r33 = q0^2-q1^2-q2^2+q3^2;
	
	--put it all in the matrix
	R = matrix:new(3,3)
	matrix.setelement(R,1,1,r11);
	matrix.setelement(R,1,2,r12);
	matrix.setelement(R,1,3,r13);
	matrix.setelement(R,2,1,r21);
	matrix.setelement(R,2,2,r22);
	matrix.setelement(R,2,3,r23);
	matrix.setelement(R,3,1,r31);
	matrix.setelement(R,3,2,r32);
	matrix.setelement(R,3,3,r33);
	return R
end


--quaterion multiplication
function quatmult(q,r)
	
	--get values from q
	q0 = matrix.getelement(q,1,1);
	q1 = matrix.getelement(q,2,1);
	q2 = matrix.getelement(q,3,1);
	q3 = matrix.getelement(q,4,1);
	
	--get values from r
	r0 = matrix.getelement(r,1,1);
	r1 = matrix.getelement(r,2,1);
	r2 = matrix.getelement(r,3,1);
	r3 = matrix.getelement(r,4,1);

	--make new values
	t0 = r0*q0-r1*q1-r2*q2-r3*q3;
	t1 = r0*q1+r1*q0-r2*q3+r3*q2;
	t2 = r0*q2+r1*q3+r2*q0-r3*q1;
	t3 = r0*q3-r1*q2+r2*q1+r3*q0;

	--output
	t = matrix:new(4,1);
	matrix.setelement(t,1,1,t0);
	matrix.setelement(t,2,1,t1);
	matrix.setelement(t,3,1,t2);
	matrix.setelement(t,4,1,t3);
	return t

end




t_last = Body.get_time()
t_last_update = Body.get_time()
t_frame = 0
fpscount = 0
local tDelay = 0.0025 * 1E6; -- Loop every 2.5ms


--main loop
  while 1 do
    t=Body.get_time()
    tPassed = t-t_last
    t_last = t
    if tPassed>0.005 then
--      print("t:",t-t_start)

      t_frame = t_frame+ t-t_last_update
      t_last_update=t
      fpscount=fpscount+1
      if fpscount%200==0 then
--        print("Motion FPS:",200/t_frame)
        t_frame=0
        fpscount=0
        end
      update();
      imu_filter();
    end
    unix.usleep(tDelay);
  end




