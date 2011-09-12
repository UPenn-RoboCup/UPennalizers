module(..., package.seeall);
require 'vector'

platform = {};
platform.name = 'webots_op'

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

-- Load configuration
loadconfig('Config_OP')
loadconfig('Config_OP_Webots_Camera')

-- Device Interface Libraries
dev.body = 'DarwinOPWebotsBody';
dev.camera = 'DarwinOPWebotsCam';

-- Webots Custom Head Parameters
head.cameraPos = {{0.05, 0.0, 0.05}}; 
head.cameraAngle = {{0.0, 0.0, 0.0}};

-- Walk Parameters
walk.tSensorDelay = 0.10;

-- Webots-specific keyframe files
km = {};
km.kick_right = 'km_Webots_OP_KickForwardRight.lua';
km.kick_left = 'km_Webots_OP_KickForwardLeft.lua';
km.standup_front = 'km_OP_StandupFromFront.lua';
km.standup_back = 'km_OP_StandupFromBack.lua';
