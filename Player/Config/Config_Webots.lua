module(..., package.seeall);

require('parse_hostname')
require('vector')

platform = {};
platform.name = 'naoWebots'

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

loadconfig('Config_Nao')

--Location Specific Camera Parameters--
loadconfig('Config_Nao_Camera_Webots')

-- Device Interface Libraries
dev.body = 'NaoWebotsBody'; 
dev.camera = 'NaoWebotsCam';
dev.kinematics = 'NaoWebotsKinematics';

