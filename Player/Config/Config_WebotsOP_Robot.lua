module(..., package.seeall);
require('vector')

-- Device Interface Libraries
dev = {};
dev.body = 'WebotsOPBody'; 
dev.camera = 'WebotsOPCam';
dev.kinematics = 'OPKinematics';
--dev.comm='WebotsOPComm';
dev.comm='NullComm';
--dev.monitor_comm = 'OPCommWired';
dev.monitor_comm = 'NullComm';
dev.game_control='OPGameControl';
dev.kick = 'SimpleKick'
dev.walk='NaoWalk';

--dev.walk='NSLWalk';
--dev.kick='NSLKick';

--Sitting parameters
sit={};
sit.bodyHeight=0.20; --Fixed for webots
sit.supportX=-0.010;

sit.bodyTilt=5*math.pi/180;

sit.dpLimit=vector.new({.1,.01,.03,.1,.3,.1});
sit.dpLimit=vector.new({.1,.01,.06,.1,.3,.1});--Faster sit

--Standing parameters
stance={};
stance.dpLimit=vector.new({.04, .03, .04, .4, .4, .4});
stance.dpLimit=vector.new({.04, .03, .07, .4, .4, .4});--Faster standup

-- Head Parameters

head = {};
head.camOffsetZ = 0.37;
head.pitchMin = -35*math.pi/180;
head.pitchMax = 68*math.pi/180;
head.yawMin = -90*math.pi/180;
head.yawMax = 90*math.pi/180;

head.cameraPos = {{0.05, 0.0, 0.05}} --OP, spec value, may need to be recalibrated
head.cameraAngle = {{0.0, 0.0, 0.0}}; --Default value for production OP
head.neckZ=0.0765; --From CoM to neck joint 
head.neckX=0.013; --From CoM to neck joint
head.bodyTilt = 0;


