local mot={};
mot.servos={
1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,};
mot.keyframes={  

--HANDSTAND getup
{
angles=vector.new({
0,-39,
85,5,-135,
0,0,-94,0,-70,0,
0,0,-94,0,-70,0,
85,5,-135
})*math.pi/180,
duration = 0.5;
},

--right leg up
{
angles=vector.new({
0,-39,
85,5,-135,
0,0,-94,0,-70,0,
0,0,30,79,-59,0,
85,5,-135
})*math.pi/180,
duration = 0.3;
},

--both leg up
{
angles=vector.new({
0,-39,
60,5,-135,
0,0,30,27,45,0,
0,0,30,27,45,0,
60,5,-135
})*math.pi/180,
duration = 0.3;
},

--final pose
{
angles=vector.new({
0,-39,
37,5,-115,
0,0,-4,2,44,0,
0,0,-4,2,44,0,
37,5,-115
})*math.pi/180,
duration = 0.5;
},

--[[
--spread legs
{
angles=vector.new({
0,-39,
37,5,-115,
0,60,-4,2,44,0,
0,-60,-4,2,44,0,
37,5,-115
})*math.pi/180,
duration = 0.5;
},
--narrow legs
{
angles=vector.new({
0,-39,
37,5,-115,
0,0,-4,2,44,0,
0,-0,-4,2,44,0,
37,5,-115
})*math.pi/180,
duration = 0.5;
},
--]]



--left leg down
{
angles=vector.new({
0,-39,
85,5,-135,
0,0,-94,0,-70,0,
0,0,30,79,-59,0,
85,5,-135
})*math.pi/180,
duration = 0.5;
},

--both leg down
{
angles=vector.new({
0,-39,
85,5,-135,
0,0,-94,0,-70,0,
0,0,-94,0,-70,0,
85,5,-135
})*math.pi/180,
duration = 0.5;
},

--start front getup
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
