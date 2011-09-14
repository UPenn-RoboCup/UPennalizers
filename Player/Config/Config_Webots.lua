module(..., package.seeall);

require('parse_hostname')
require('vector')
require('os')

platform = {};
platform.name = 'naoWebots'

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

loadconfig('Config_Nao')
loadconfig('Config_Webots_Walk')
loadconfig('Config_Webots_Nao_Vision')
loadconfig('Config_Webots_Kick')

--Location Specific Camera Parameters--
loadconfig('Config_Nao_Camera_Webots')

-- Device Interface Libraries
dev.body = 'NaoWebotsBody'; 
dev.camera = 'NaoWebotsCam';
dev.kinematics = 'NaoWebotsKinematics';


-- Game Parameters

game = {};
game.teamNumber = os.getenv('TEAM_ID') + 0;
game.playerID = os.getenv('PLAYER_ID') + 0;
game.robotID = game.playerID;
game.teamColor = 1;
game.nPlayers = 4;


-- FSM Parameters

fsm = {};
fsm.game = 'RoboCup';
if (game.playerID == 1) then
  fsm.body = {'NaoGoalie'};
  fsm.head = {'NaoGoalie'};
else
  fsm.body = {'NaoPlayer'};
  fsm.head = {'NaoPlayer'};
end


-- keyframe files

km.kick_right = 'km_Webots_KickForwardRight.lua';
km.kick_left = 'km_Webots_KickForwardLeft.lua';
km.standup_front = 'km_Webots_StandupFromFront.lua';
km.standup_back = 'km_Webots_StandupFromBack.lua';


