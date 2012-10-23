local mot={};


--walk.qLArm = math.pi/180*vector.new({110, 12, -0, -40});
--walk.qRArm = math.pi/180*vector.new({110, -12, 0, 40});	

mot.servos={
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,};
mot.keyframes={  
  {
    angles=math.pi/180*vector.new({
	0,0,
	170,12,0,-130,
	0,0,-90,110,-0,0,
	0,0,-90,110,-0,0,
	170,-12,0,130,
    }),
    duration = 0.5; 
  },
  {
    angles=math.pi/180*vector.new({
	0,0,
	170,0,0,-0,
	0,0,-0,110,0,0,
	0,0,-0,110,0,0,
	170,0,0,0,
    }),
    duration = 0.5; 
  },
  {
    angles=math.pi/180*vector.new({
	0,0,
	160,0,0,-0,
	0,0,0,150,-90,0,
	0,0,0,150,-90,0,
	160,0,0,0,
    }),
    duration = 1; 
  },
  {
    angles=math.pi/180*vector.new({
	0,0,
	90,12,0,-0,
	0,0,-50,140,-90,0,
	0,0,-50,140,-90,0,
	90,-12,0,0,
    }),
    duration = 1; 
  },
};

return mot;
