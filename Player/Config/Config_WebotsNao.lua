module(..., package.seeall);

require('parse_hostname')
require('vector')
require('os')

platform = {};
platform.name = 'WebotsNao'


function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

listen_monitor = 1

webots = 1
param = {}
param.world = 'World/Config_WebotsNao_World'
param.walk = 'Walk/Config_WebotsNao_Walk' 
param.kick = 'Kick/Config_WebotsNao_Kick'
param.vision = 'Vision/Config_WebotsNao_Vision'
param.camera = 'Vision/Config_WebotsNao_Camera'
param.fsm = 'FSM/Config_WebotsNao_FSM'

loadconfig(param.world)
loadconfig(param.walk)
loadconfig(param.kick)
loadconfig(param.vision)

--Location Specific Camera Parameters--
loadconfig(param.camera)

-- Device Interface Libraries
dev = {};
dev.body = 'NaoWebotsBody'; 
dev.camera = 'NaoWebotsCam';
dev.kinematics = 'NaoWebotsKinematics';
dev.game_control='WebotsGameControl';
dev.team= 'TeamSPL';
dev.kick = 'BasicKick';
dev.walk = 'Walk/NaoV4Walk';

-- Game Parameters

game = {};
game.teamNumber = (os.getenv('TEAM_ID') or 0) + 0;
-- webots player ids begin at 0 but we use 1 as the first id
game.playerID = (os.getenv('PLAYER_ID') or 0) + 1;
game.robotID = game.playerID;
game.role = game.playerID-1; -- default role, 0 for goalie 
game.nPlayers = 4;

--To handle non-gamecontroller-based team handling for webots
if game.teamNumber==0 then game.teamColor = 0; --Blue team
else game.teamColor = 1; --Red team
end

fsm={}
loadconfig(param.fsm)
fsm.game = 'RoboCup';
if (game.playerID == 1) then
  fsm.body = {'NaoGoalie'};
  fsm.head = {'NaoGoalie'};
else
  fsm.body = {'NaoKickLogic'};
  fsm.head = {'NaoPlayer'};
end

-- Team Parameters
team = {};
team.msgTimeout = 5.0;
team.nonAttackerPenalty = 6.0; -- eta sec
team.nonDefenderPenalty = 0.5; -- dist from goal

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


-- keyframe files

km = {};
km.kick_right = 'km_WebotsNao_KickForwardRight.lua';
km.kick_left = 'km_WebotsNao_KickForwardLeft.lua';
km.standup_front = 'km_WebotsNao_StandupFromFront.lua';
km.standup_back = 'km_WebotsNao_StandupFromBack.lua';


km.standup_front = 'km_WebotsNao_StandupFromFront.lua';
km.standup_back = 'km_WebotsNao_StandupFromBack.lua';
km.time_to_stand = 30; -- average time it takes to stand up in seconds



--Sit/stand stance parameters
stance={};
stance.bodyHeightSit = 0.225;
stance.supportXSit = 0;
stance.dpLimitSit=vector.new({.1,.01,.03,.1,.3,.1});
stance.bodyHeightDive= 0.25;
stance.bodyTiltStance=0*math.pi/180; --bodyInitial bodyTilt, 0 for webots
stance.dpLimitStance = vector.new({.04, .03, .04, .05, .4, .1});
stance.delay = 80; --amount of time to stand still after standing to regain balance.

world.enable_sound_localization = 0;
