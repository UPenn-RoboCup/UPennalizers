module(..., package.seeall);

require('vector')
require('parse_hostname')

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

loadconfig('Config_OP_Walk')
loadconfig('Config_OP_World')
loadconfig('Config_OP_Kick')
loadconfig('Config_OP_Vision')
loadconfig('Config_OP_Robot')

--Location Specific Camera Parameters--
loadconfig('Config_OP_Camera_Grasp')

-- Low battery level
-- Need to implement this api better...
bat_low = 100; -- 10V warning

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
km.kick_right = 'km_Nao_KickForwardRight.lua';
km.kick_left = 'km_Nao_KickForwardLeft.lua';
km.standup_front = 'km_Nao_StandupFromFrontFaster.lua';
km.standup_back = 'km_Nao_StandupFromBackFasterNew.lua';

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
