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
loadconfig('Config_WebotsOP_Kick')
loadconfig('Config_WebotsOP_Vision')
loadconfig('Config_WebotsOP_Robot')

--Location Specific Camera Parameters--
loadconfig('Config_WebotsOP_Camera')

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
km.kick_right = 'km_WebotsOP_KickForwardRight.lua';
km.kick_left = 'km_WebotsOP_KickForwardLeft.lua';
km.standup_front = 'km_WebotsOP_StandupFromFront.lua';
km.standup_back = 'km_WebotsOP_StandupFromBack.lua';

-- Load the Sitting and standing paramters from the RObot config file
-- See up top
--[[
-- sitting parameters

sit = {};
sit.bodyHeight = 0.22;
sit.supportX = 0;
sit.dpLimit = vector.new({.1,.01,.03,.1,.3,.1});


-- standing parameters

stance = {};
stance.dpLimit = vector.new({.04, .03, .04, .05, .4, .1});
stance.delay = 80; --amount of time to stand still after standing to regain balance.

--]]
