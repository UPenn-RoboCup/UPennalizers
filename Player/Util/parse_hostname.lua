module(..., package.seeall);

require('io')
require('unix');
require('string');

--teamColor = 1;  --0 is blue team, 1 is red team

-- hostname = unix.gethostname();

-- if hostname ~= nil then
--   if (string.find(hostname, 'blue') ~= nil) then
--     teamColor = 0;
--   elseif (string.find(hostname, 'red') ~= nil) then
--     teamColor = 1;
--   end

--   for id in string.gmatch(hostname, '%d') do
--     playerID = tonumber(id);
--   end
-- end


-- function get_player_id()
--   return playerID;  
-- end

-- function get_team_color()
--   return teamColor;
-- end

