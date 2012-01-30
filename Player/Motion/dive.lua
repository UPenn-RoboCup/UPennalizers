module(..., package.seeall);

require('Body')
require('keyframe')
require('walk')
require('step')
require('vector')
require('Config')

local cwd = unix.getcwd();
if string.find(cwd, "WebotsController") then
  cwd = cwd.."/Player";
end
cwd = cwd.."/Motion"

-- default kick type
diveType = "diveLeft";
active = false;


qLArm=math.pi/180*vector.new({-150,0,-40});
qRArm=math.pi/180*vector.new({-150,0,-40});

--spread arm to roll back
qLArm2=math.pi/180*vector.new({-150,60,-40});
qRArm2=math.pi/180*vector.new({-150,-60,-40});

qLArm2=math.pi/180*vector.new({120,60,-90});
qRArm2=math.pi/180*vector.new({120,-60,-90});


--default arm
qLArm0=math.pi/180*vector.new({90,16,-40});
qRArm0=math.pi/180*vector.new({90,-16,-40});



bodyHeight = Config.walk.bodyHeight;
footX = Config.walk.footX+Config.walk.footXComp;
footY = Config.walk.footY+Config.walk.footYComp;
bodyTilt = Config.walk.bodyTilt;
supportX = Config.walk.supportX;
pTorso = vector.new({0, 0, bodyHeight, 0,bodyTilt,0});
pLLeg=vector.zeros(6);
pRLeg=vector.zeros(6);

torsoShiftX=0;
t0=0;
t1=0;

function entry()
  print("Motion SM:".._NAME.." entry");
  walk.active=false; --Instaneous walk stop
  --The robot should stand still before dive anyway

  -- disable joint encoder reading
  Body.set_syncread_enable(0);
  t0 = Body.get_time();
  t00 = Body.get_time();

  phase=1;

  if diveType == "diveLeft" then
     Speak2.talk('Left dive')
  elseif diveType == "diveRight" then
     Speak2.talk('Right dive')
  else
     Speak2.talk('Center dive')
  end

end


zBody=Config.walk.bodyHeight;
pTorso[3]=zBody;
aLeft=0; aRight=0;


function update() 
     if Config.BodyFSM.level.goalie==2 then
--     if true then 
	divedone=dodive();
	if divedone then 
	    if diveType == "diveCenter" then
	  	    walk.start();
	  	    return "done"
	    else
		    return "divedone"
	    end
 	end
     else
	divedone=dodive2();
	if divedone then 
  	    walk.start();
  	    return "done"
	end
     end
end

function dosquat()

  tDelay1=0.5;
  tDelay2=1.5;
  tDelay3=1.0;

  t = Body.get_time();
  local divedone=false;
  if phase==1 then

	qLArm4=math.pi/180*vector.new({80,20,0});
	qRArm4=math.pi/180*vector.new({80,-20,0});
        Body.set_larm_command(qLArm4);
        Body.set_rarm_command(qRArm4);


      ph=(t-t0)/tDelay1;
	  uTorsoX=0;
	  uTorso=vector.new({-footX+uTorsoX,0,0});
	  uLeft={-supportX ,0.04 ,0.2};
	  uRight={-supportX ,-0.04 ,-0.2};
	  zLeft=0.09*ph; zRight=0.09*ph;

	if t-t0>tDelay1 then
  	   print("PH1")
	   phase=2;t0=t;
	end
  elseif phase==2 then
	if t-t0>tDelay2 then
  	   print("PH1")
	   phase=3;t0=t;
	end

  elseif phase==3 then
      ph=(t-t0)/tDelay3;
      zLeft=0.09*(1-ph); zRight=0.09*(1-ph);
	  uLeft={-supportX ,0.05 ,0.2*(1-ph)};
	  uRight={-supportX ,-0.05 ,-0.2*(1-ph)};

	if t-t0>tDelay3 then
  	   print("PH1")
	   phase=4;t0=t;
	end
  elseif phase==4 then
        Body.set_larm_command(qLArm0);
        Body.set_rarm_command(qRArm0);

     divedone=true;
  end     

  pTorso[1],pTorso[2],pTorso[6]=uTorso[1],uTorso[2],uTorso[3];
  pLLeg[1],pLLeg[2],pLLeg[3],pLLeg[5],pLLeg[6]=uLeft[1],uLeft[2],zLeft,aLeft,uLeft[3];
  pRLeg[1],pRLeg[2],pRLeg[3],pRLeg[5],pRLeg[6]=uRight[1],uRight[2],zRight,aRight,uRight[3];
  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso,0);
  Body.set_lleg_command(qLegs);
  return divedone;
end



function dodive()
    if diveType == "diveCenter" then
        return dosquat();
    else
       tDelay1=0.1;
       tDelay2=5; 
       tDelay3=0.5;
       tDelay4=0.5;
   end

  t = Body.get_time();
  local divedone=false;
--  print(t-t00,phase)

  if phase==1 then

--raise hand. squat down


  	  if diveType == "diveLeft" then
   	     Body.set_larm_hardness(0.9);
	     Body.set_larm_command(qLArm);
	  else
  	     Body.set_rarm_hardness(0.9);
  	     Body.set_rarm_command(qRArm);
	  end

	  uTorsoX=-0.02;
	  uTorso=vector.new({-footX+uTorsoX,0,0});
	  uLeft={-supportX ,0.05 ,0};
	  uRight={-supportX ,-0.05 ,0};
	  zLeft=0.05; zRight=0.05;

	if t-t0>tDelay1 then
  	   print("PH1")
	   phase=2;t0=t;
	end
  elseif phase==2 then

--Do diving

	uTorsoX=-0.04;
	uTorso=vector.new({-footX+uTorsoX,0,0});

	if diveType == "diveLeft" then
	   uLeft={-supportX ,0.05 ,0};
	   uRight={-supportX+0.04 ,-0.05 ,0};


	   uLeft={-supportX ,0.05 ,0};
	   uRight={-supportX-0.04 ,-0.05 ,0};

	   zLeft=0.03;  zRight=-0.03;
	elseif diveType == "diveRight" then
	   uLeft={-supportX+0.04 ,0.05 ,0};
	   uRight={-supportX ,-0.05 ,0};
	   zLeft=-0.03;  zRight=0.03;
	end

	if t-t0>tDelay2 then
	print("PH2")

	   phase=3;t0=t;
	end

  elseif phase==3 then

--Role to back

 	if diveType == "diveLeft" then
  	      Body.set_larm_command(qLArm2);
	else
		Body.set_rarm_command(qRArm2);
        end

	uTorsoX=0.0;
	uTorso=vector.new({-footX+uTorsoX,0,0});
	if diveType == "diveLeft" then
	    uLeft= vector.new({-supportX+0.04, footY, 0});
	    uRight=vector.new({-supportX-0.04, -footY, 0});
	else
	    uLeft= vector.new({-supportX-0.04, footY, 0});
	    uRight=vector.new({-supportX+0.04, -footY, 0});
	end
   	zLeft=0.0;   zRight=0.0;

	if t-t0>tDelay3 then
        print("PH3")

	   phase=4;t0=t;
	end

  elseif phase==4 then
 	if diveType == "diveLeft" then
  	      Body.set_larm_command(qLArm0);
	else
		Body.set_rarm_command(qRArm0);
        end
        uLeft= vector.new({-supportX, footY, 0});
        uRight=vector.new({-supportX, -footY, 0});

	if t-t0>tDelay4 then
        print("PH3")
	   phase=5;t0=t;
	end
  elseif phase==5 then
        local divedone=true;
  end     

  pTorso[1],pTorso[2],pTorso[6]=uTorso[1],uTorso[2],uTorso[3];
  pLLeg[1],pLLeg[2],pLLeg[3],pLLeg[5],pLLeg[6]=uLeft[1],uLeft[2],zLeft,aLeft,uLeft[3];
  pRLeg[1],pRLeg[2],pRLeg[3],pRLeg[5],pRLeg[6]=uRight[1],uRight[2],zRight,aRight,uRight[3];
  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso,0);
  Body.set_lleg_command(qLegs);
  return divedone;
end


function dodive2()

 tDelay1=0.0;
 tDelay2=1.0;

  t = Body.get_time();
  divedone=false;
  if t-t0>tDelay1 and phase==1 then 
	print("PH1")
        Body.set_larm_hardness(0.9);
        Body.set_rarm_hardness(0.9);
	if diveType == "diveLeft" then
	   Body.set_larm_command(qLArm2);
	elseif diveType == "diveRight" then
           Body.set_rarm_command(qRArm2);
	else
	   Body.set_larm_command(qLArm2);
           Body.set_rarm_command(qRArm2);
	end
        phase=2;
  end
  if phase==2 and t-t0>tDelay2 then
     divedone=true;
  end     
  return divedone;
end

function exit()
  
end

function set_dive(newdive)
  -- set dive type (left/right)
    diveType = newdive;
end

