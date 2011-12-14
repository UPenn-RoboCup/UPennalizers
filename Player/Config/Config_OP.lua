module(..., package.seeall);

require('vector')
require('parse_hostname')

platform = {}; 
platform.name = 'OP'

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

--loadconfig('Config_OP_Walk_old')
loadconfig('Config_OP_Walk')
loadconfig('Config_OP_World')
loadconfig('Config_OP_Kick')
loadconfig('Config_OP_Vision')
loadconfig('Config_OP_Robot')

--Location Specific Camera Parameters--
loadconfig('Config_OP_Camera_Grasp')

-- Device Interface Libraries
dev = {};
dev.body = 'OPBody'; 
dev.camera = 'OPCam';
dev.kinematics = 'OPKinematics';
--dev.comm='OPComm';
dev.comm='NullComm';
dev.monitor_comm = 'OPMonitorCommWired';
dev.game_control='OPGameControl';
dev.walk='NewWalk';
dev.kick='NewKick';

--[[
dev.walk='NSLWalk';
dev.kick='NSLKick';
--]]

-- Game Parameters

game = {};
game.teamNumber = 18;
game.playerID = parse_hostname.get_player_id();
game.robotID = game.playerID;
game.teamColor = parse_hostname.get_team_color();
game.nPlayers = 3;

-- FSM Parameters

fsm = {};
--fsm.game = 'Dodgeball';
fsm.game = 'OpDemo'
--fsm.game = 'RoboCup';
if( fsm.game == 'RoboCup' ) then
  if (game.playerID == 1) then
    fsm.body = {'OpGoalie'};
    fsm.head = {'OpGoalie'};
  else
    fsm.body = {'OpPlayer'};
    fsm.head = {'OpPlayer'};
  end
elseif( fsm.game == 'Dodgeball' ) then
  fsm.body = {'Dodgeball'};
  fsm.head = {'Dodgeball'};
else
  fsm.body = {'OpDemo'};
  fsm.head = {'OpDemo'};
end

-- Game specific settings
if( fsm.game == 'Dodgeball' ) then
  Config.vision.enable_line_detection = 0;
  Config.vision.enable_midfield_landmark_detection = 0;
end

-- enable obstacle detection
BodyFSM = {}
BodyFSM.enable_obstacle_detection = 1;

-- Team Parameters

team = {};
team.msgTimeout = 5.0;
team.nonAttackerPenalty = 6.0; -- eta sec
team.nonDefenderPenalty = 0.5; -- dist from goal

-- keyframe files

km = {};
km.standup_front = 'km_OP_StandupFromFront.lua';
km.standup_back = 'km_OP_StandupFromBack.lua';

-- Low battery level
-- Need to implement this api better...
bat_low = 100; -- 10V warning


speedFactor = 1.0; --all SM work in real time
webots_vision = 0; --use full vision
