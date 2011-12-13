module(..., package.seeall);
require('vector')

-- Name Platform
platform = {}; 
platform.name = 'WebotsOP'

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

loadconfig('Config_WebotsOP_Walk')
loadconfig('Config_WebotsOP_World')
--loadconfig('Config_WebotsOP_Kick')
loadconfig('Config_WebotsOP_KickPunch')
loadconfig('Config_WebotsOP_Vision')
loadconfig('Config_WebotsOP_Robot')

--Location Specific Camera Parameters--
loadconfig('Config_WebotsOP_Camera')

-- Device Interface Libraries
dev = {};
dev.body = 'WebotsOPBody'; 
dev.camera = 'WebotsOPCam';
dev.kinematics = 'OPKinematics';
dev.comm='WebotsOPComm';
dev.monitor_comm = 'NullComm';
dev.game_control='WebotsOPGameControl';
dev.walk='NewWalk';
--dev.kick='NewKick';
dev.kick='NSLKickPunch';

--dev.walk='NSLWalk';
--dev.kick='NSLKick';
--dev.kick='Jump';
--dev.kick='kickKeyframe';
--dev.walk='EKWalk';
--dev.kick='NSLPunch';

-- Game Parameters

game = {};
game.teamNumber = (os.getenv('TEAM_ID') or 0) + 0; 
game.robotID = game.playerID;
game.playerID = (os.getenv('PLAYER_ID') or 0) + 0;
game.teamColor = 1;
game.nPlayers = 3;


-- FSM Parameters

fsm = {};
--fsm.game = 'Dodgeball';
fsm.game = 'OpDemo'
fsm.game = 'RoboCup';

if( fsm.game == 'RoboCup' ) then
--[[
  if (game.playerID == 1) then
    fsm.body = {'OpGoalie'};
    fsm.head = {'OpGoalie'};
  else
    fsm.body = {'OpPlayer'};
    fsm.head = {'OpPlayer'};
  end
--]]

  fsm.body = {'OpPlayer'};
  fsm.head = {'OpPlayer'};

fsm.head = {'OpPlayerNSL'};
fsm.body = {'OpPlayerNSL'};

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
km.standup_front = 'km_WebotsOP_StandupFromFront.lua';
km.standup_back = 'km_WebotsOP_StandupFromBack.lua';
--km.standup_front = 'km_NSLOP_StandupFromFront.lua';
--km.standup_back = 'km_NSLOP_StandupFromBack.lua';
--km.standup_front = 'km_NSLOP_StandupFromFront2.lua';


km.kick_right = 'km_NSLOP_taunt1.lua';
km.kick_left = 'km_NSLOP_StandupFromFront2.lua';


--Webots tStep is 2x of real robot
--So slow down SM durations
speedFactor = 2.0; 
