local mot = {};
mot.servos = {
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,
};
mot.keyframes = {
   {	--Straight out limbs.
     angles = vector.new({
         0, 0, 
         109.8, 11.0, -88.9, -21.4, 
         -13.7, -0.3, 17.1, -5.6, 5.2, 0, 
         0.0, -1.8, 14.6, -5.6, 4.9, 0, 
         109.9, -10.2, 88.7, 19.9, 
     })*math.pi/180,
     duration = 0.400;
   },
   {	--Bend in knees, rotate wrists
     angles = vector.new({
         0, 0, 
         121.0, 7.8, -2.3, -3.4, 
         0, 0, 24.0, 65.8, 28.2, 0, 
         0, 0, 24.0, 65.8, 28.2, 0, 
         121.0, -9.4, -5.4, 9.5, 
     })*math.pi/180,
     duration = 0.400;
   },
   {	--Pull in arms under tailbone
     angles = vector.new({
         0, 0, 
         120.1, 11.4, 1.1, -81.7, 
         0, 0, 18.9, 64.9, 31.5, 0, 
         0, 0, 18.9, 64.9, 31.5, 0, 
         120.1, -14.4, -2.6, 82.8,
     })*math.pi/180,
     duration = 0.400;
   },
	 {	--Re-extend legs, rotate body up
		angles = vector.new({
         0, 0, 
         120.1, 24.4, 0, -81.7, 
         0, 0, -50, 0, 31.5, 0, 
         0, 0, -50, 0, 31.5, 0, 
         120.1, -24.4, 0, 82.8,
     })*math.pi/180,
--     duration = 0.200;

     duration = 0.600;




	 },
	 {	--Spread stance, rotate forearms down, bend knees
		angles = vector.new({ 
				 0, 0, 
				 120.1, 0, 0, -20, 
         -60, 20, -60, 50, 40, 0, 
         -60, -20, -60, 50, 40, 0, 
         120.1, 0, 0, 20,
     })*math.pi/180,
--     duration = 0.200;
     duration = 0.600;
	 },
   {	--Plant feet 
		angles = vector.new({
         0, 0, 
         120.1, 0, 0, -20, 
         -60, 23, -80, 105, 25, 10, 
         -60, -23, -80, 105, 25, -10, 
         120.1, 0, 0, 20,
     })*math.pi/180,
     duration = 0.100;
	 },
   {	--Left leg pull in
		angles = vector.new({
         0, 0, 
         120.1, 0, 0, 0, 
         -60, 23, -80, 120, 15, 10, 
         -60, -23, -85, 105, 25, -10, 
         120.1, 0, 0, 0,
     })*math.pi/180,
     duration = 0.100;
	 },
   {	--Left-side lift
		angles = vector.new({
				0, 60,
				120.1, 0, 0, 0,
				-40, 20, -50, 125, -20, -10,
				-40, -30, -85, 125, 0, -5,
				120.1, 0, 0, 0
		})*math.pi/180,
		duration = 0.100;
	 },
   {	--Bring hips in
		angles = vector.new({
				0, 60,
				120.1, 0, 0, 0,
				-40, 0, -80, 125, -20, 0,
				-40, 0, -80, 125, -20, 0,
				120.1, 0, 0, 0
		})*math.pi/180,
		duration = 0.400;
	 },
   {	--Center hips and bring arms down
		angles = vector.new({
				0, 0,
				90, 0, 0, 0,
				-10, 0, -60, 125, -60, 0,
				-10, 0, -60, 125, -60, 0,
				90, 0, 0, 0
		})*math.pi/180,
		duration = 0.100;
	 },
   {	--Hold for 0.2s
		angles = vector.new({
				0, 0,
				90, 0, 0, 0,
				-10, 0, -60, 125, -60, 0,
				-10, 0, -60, 125, -60, 0,
				90, 0, 0, 0
		})*math.pi/180,
		duration = 0.200;
	 },

};

return mot;
