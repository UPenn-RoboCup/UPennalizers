-- Get Computer for Lib suffix
package.cpath = './?.so;' .. package.cpath;

require('controller');

playerID = os.getenv('PLAYER_ID') + 0;
teamID = os.getenv('TEAM_ID') + 0;

--Default
print("\nStarting Webots Lua controller...");
dofile("Player/Test/test_main_webots.lua");
--dofile("Player/main.lua");
