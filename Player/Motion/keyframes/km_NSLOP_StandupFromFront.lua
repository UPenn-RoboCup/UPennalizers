local mot={};

mot.servos={
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,};
mot.keyframes={  

--Arm back
{
angles=vector.new({
0,0,
179,5,-152,
1,-3,-15,24,-60,0,
-1,3,-15,24,-60,0,
179,-5,-152
})*math.pi/180,
duration = 0.3;
},
--Arm push
{
angles=vector.new({
0,0,
44,5,-155,
1,0,-94,59,-78,-2,
-1,0,-94,59,-78,2,
44,-5,-155
})*math.pi/180,
duration = 0.3;
},

{
angles=vector.new({
0,0,
58,10,-14,
-1,1,-97,130,-66,-1,
1,-1,-97,130,-66,1,
58,-10,-14
})*math.pi/180,
--duration = 0.4;
duration = 0.6; --slowed down 0.2sec
},

--This is the final pose of bodySit
{
angles=vector.new({
0,0,
78,10,-14,
0,3,-60,110,-60,-3,
0,-3,-60,110,-60,3,
78,-10,-14,
})*math.pi/180,
duration = 0.5;
},

};

return mot;
