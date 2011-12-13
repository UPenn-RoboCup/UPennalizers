module(..., package.seeall);

require('parse_hostname')
require('vector')
require('os')

platform = {};
platform.name = 'WebotsHubo'

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end


loadconfig('Config_WebotsHubo_Walk')
loadconfig('Config_WebotsHubo_Kick')
loadconfig('Config_WebotsOP_World')
loadconfig('Config_WebotsOP_Vision')

--Location Specific Camera Parameters--
loadconfig('Config_WebotsOP_Camera')

-- Device Interface Libraries
dev = {};
dev.body = 'WebotsHuboBody'; 
dev.camera = 'WebotsOPCam';
dev.kinematics = 'HuboKinematics';
dev.comm = 'WebotsNaoComm';
dev.monitor_comm = 'NullComm';
dev.game_control='WebotsOPGameControl';
--dev.walk = 'NaoWalk';
--dev.kick = 'NaoKick';

dev.walk = 'NewWalk';
dev.kick = 'NewKick';

-- Game Parameters
game = {};
game.teamNumber = (os.getenv('TEAM_ID') or 0) + 0;
-- webots player ids begin at 0 but we use 1 as the first id
game.playerID = (os.getenv('PLAYER_ID') or 0) + 1;
game.robotID = game.playerID;
game.teamColor = 1;
game.nPlayers = 4;


-- FSM Parameters
fsm = {};
fsm.game = 'OpDemo'
fsm.body = {'HuboPlayer'};
fsm.head = {'OpPlayer'};


fsm.head = {'OpPlayerNSL'}; 

-- Team Parameters

team = {};
team.msgTimeout = 5.0;
team.nonAttackerPenalty = 6.0; -- eta sec
team.nonDefenderPenalty = 0.5; -- dist from goal


--Head Parameters

head = {};
head.camOffsetZ = 0.41;
head.pitchMin = -35*math.pi/180;
head.pitchMax = 68*math.pi/180;
head.yawMin = -120*math.pi/180;
head.yawMax = 120*math.pi/180;
head.cameraPos = {{0.05, 0.0, 0.05}} --OP, spec value, may need to be recalibrated
head.cameraAngle = {{0.0, 0.0, 0.0}}; --Default value for production OP
head.neckZ=0.15; --From CoM to neck joint , Hubo prototype
head.neckX=0.03; --From CoM to neck joint , Hubo prototype

-- keyframe files

km = {};
km.standup_front = 'km_Hubo_StandupFromFront.lua';
km.standup_back = 'km_Hubo_StandupFromBack.lua';


-- sitting parameters

sit = {};
sit.bodyHeight=0.40; --For Hubo
sit.supportX = 0;
sit.dpLimit = vector.new({.1,.01,.03,.1,.3,.1});

-- standing parameters

stance = {};
--stance.dpLimit = vector.new({.04, .03, .04, .05, .4, .1});
stance.dpLimit = vector.new({.4, .3, .4, .05, .4, .1});
stance.delay = 80; --amount of time to stand still after standing to regain balance.

-- enable obstacle detection
BodyFSM = {}
BodyFSM.enable_obstacle_detection = 1;

--How slow is the walking compared to real OP?
speedFactor = 4.0;

--Skip all checks in vision for 160*120 image 
webots_vision = 1; 
