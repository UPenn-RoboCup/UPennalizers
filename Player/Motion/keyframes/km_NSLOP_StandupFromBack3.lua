local mot={};
mot.servos={
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,};
mot.keyframes={  

{
angles=vector.new({
0,-39,
90,5,-0,
0,0,-90,106,-35,0,
0,0,-90,106,-35,1,
90,-5,-0
})*math.pi/180,
duration = 0.3;
},

{
angles=vector.new({
0,-39,
180,5,-88,
0,0,-90,0,-35,0,
0,0,-90,0,-35,0,
180,-5,-88
})*math.pi/180,
duration = 0.4;
--duration = 1;
},

{
angles=vector.new({
0,-39,
226,25,-37,
0,0,-90,90,-35,0,
0,0,-90,90,-35,0,
226,-25,-37
})*math.pi/180,
--duration = 0.6;
duration = 0.6;
},

{
angles=vector.new({
0,0,
44,9,-155,
1,0,-94,59,-78,-2,
-1,0,-94,59,-78,2,
44,-9,-155
})*math.pi/180,
duration = 0.4;
},
{
angles=vector.new({
0,0,
58,-2,-14,
-1,1,-97,130,-66,-1,
1,-1,-97,130,-66,1,
58,2,-14
})*math.pi/180,
duration = 0.5;
},

--This is the final pose of bodySit
{
angles=vector.new({
0,0,
105,29,-45,
0,3,-44,119,-75,-3,
0,-3,-44,119,-75,3,
105,-29,-45
})*math.pi/180,
duration = 0.5;
},


};

return mot;
