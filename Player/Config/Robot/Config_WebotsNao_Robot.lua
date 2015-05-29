module(..., package.seeall);
require('vector')
require('unix')

--Sit/stand stance parameters
stance={};
stance.bodyHeightSit = 0.225;
stance.supportXSit = 0;
stance.dpLimitSit=vector.new({.1,.01,.03,.1,.3,.1});
stance.bodyHeightDive= 0.25;
stance.bodyTiltStance=0*math.pi/180; --bodyInitial bodyTilt, 0 for webots
stance.dpLimitStance = vector.new({.04, .03, .04, .05, .4, .1});
stance.delay = 80; --amount of time to stand still after standing to regain ba$


--Head Parameters

head = {};
head.camOffsetZ = 0.41;
head.pitchMin = -35*math.pi/180;
head.pitchMax = 30*math.pi/180;
head.yawMin = -120*math.pi/180;
head.yawMax = 120*math.pi/180;
head.cameraPos = {{0.05390, 0.0, 0.06790},
                  {0.04880, 0.0, 0.02381}}; 
head.cameraAngle = {{0.0, 0.0, 0.0},
                    {0.0, 40*math.pi/180, 0.0}};
head.neckZ=0.14; --From CoM to neck joint
head.neckX=0;  

--Dummy variables
bat_low = 999;
bat_med = 999;

-- keyframe files
km = {};
km.standup_front = 'km_WebotsNao_StandupFromFront.lua';
km.standup_back = 'km_WebotsNao_StandupFromBackBackup.lua';
km.time_to_stand = 30; -- average time it takes to stand up in seconds

