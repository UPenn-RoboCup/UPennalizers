local mot={};
mot.servos={
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,};
mot.keyframes={  

--Arm back
{
angles=vector.new({
0,-39,
237,5,-147,
0,0,-90,102,-35,0,
0,0,-90,102,-35,0,
237,-5,-147
})*math.pi/180,
duration = 0.3;
},

--Arm push, Move knee forward
{
angles=vector.new({
0,-39,
220,15,-37,
0,0,30,58,0,0,
0,0,30,58,0,0,
220,-15,-37
})*math.pi/180,
duration = 0.6;
},


{
angles=vector.new({
0,-39,
178,14,-17,
1,0,33,109,-80,0,
0,0,33,109,-80,0,
178,-14,-17
})*math.pi/180,
duration = 0.5;
},

{
angles=vector.new({
0,-39,
178,14,-17,
0,0,33,91,-80,0,
0,0,33,91,-80,0,
178,-14,-17
})*math.pi/180,
duration = 0.2;
},

--SJ: This is final pose of bodySit
 
{
angles=vector.new({
0,0,
178,14,-45,
0,3,-35,110,-75,-3,
0,-3,-35,110,-75,3,
178,-14,-45
})*math.pi/180,
duration = 0.5;
},

{
angles=vector.new({
0,0,
105,14,-45,
0,3,-35,110,-75,-3,
0,-3,-35,110,-75,3,
105,-14,-45
})*math.pi/180,
duration = 0.1;
},



};

return mot;
