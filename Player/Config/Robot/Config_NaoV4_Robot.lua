module(..., package.seeall);
require('vector')
require('unix')


--Sit/stand stance parameters
stance={};
stance.bodyHeightSit = 0.18;
stance.supportXSit = 0.020;
stance.bodyHeightDive= 0.25;
stance.dpLimitSit=vector.new({.1,.01,.06,.1,.3,.1});
stance.bodyTiltStance=0*math.pi/180; --bodyInitial bodyTilt, 0 for webots
stance.dpLimitStance=vector.new({.04, .03, .06, .05, .4, .1});
stance.delay = 80; --amount of time to stand still after standing to regain balance.


--stance.hardnessLeg = {0.5,0,5,0.5,0.7,0.7,0.5}
stance.hardnessLeg = 0.9




--Head Parameters

head = {};
head.camOffsetZ = 0.41;
head.pitchMin = -35*math.pi/180;
head.pitchMax = 30*math.pi/180;
head.yawMin = -120*math.pi/180;
head.yawMax = 120*math.pi/180;
head.yawMax_coach = 75*math.pi/180;
--Update with naoV4 camera values
head.cameraPos = {{0.05871, 0.0, 0.06364},
                  {0.05071, 0.0, 0.01774}}; 
head.cameraAngle = {{0.0, 1.2*math.pi/180, 0.0},
                    {0.0, 39.7*math.pi/180, 0.0}};

head.neckZ=0.14; --From CoM to neck joint
head.neckX=0;  
head.bodyTilt = 0;

--For compatibility with OP
--Should be more generally handled in Body..
servo={};
servo.pid=0;
bat_med = 0;
bat_low = 0;


