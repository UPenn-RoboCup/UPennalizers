local mot={};



mot.servos={
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,};
mot.keyframes={  {
    angles=math.pi/180*vector.new({
	0,0,
	-20,90,90,-90,
	0,0,-60,110,-90,0,
	0,0,-60,110,-90,0,
	-20,-90,90,90,
	0,
    }),
    duration = 1; 
  },
  {
    angles=math.pi/180*vector.new({
	0,0,
	-20,0,90,-0,
	0,0,-90,110,-90,0,
	0,0,-90,110,-90,0,
	-20,-0,90,0,
	0,
    }),
    duration = 1; 
  },

--SJ: This is final pose of bodySit
  {
    angles={
        0,0,
	105*math.pi/180, 30*math.pi/180, 0, -0*math.pi/180,
	0,  0.055, -0.77, 2.08, -1.31, -0.055, 
	0, -0.055, -0.77, 2.08, -1.31, 0.055,
	105*math.pi/180, -30*math.pi/180,-0,0*math.pi/180,
	0,
	},
    duration=0.7;
  },

};

return mot;
