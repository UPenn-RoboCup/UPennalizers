-- Get Computer for Lib suffix
package.cpath = './?.so;' .. package.cpath;
require('controller');

cwd = os.getenv('PWD')
cwd = cwd ..'/Player'
playerID = os.getenv('PLAYER_ID') +  0;
teamID = os.getenv('TEAM_ID') +  0;

print("\nStarting Webots Lua controller...");
print("CWD: ",cwd)
print("Team, Player: ",teamID,playerID)

--SJ:  Team-specific test code running 
if teamID == 98 then

	print("Starting test_walk");
	dofile("Player/Test/test_walk_webots.lua");
elseif teamID == 99 then

	print("Starting test_vision");
	dofile("Player/Test/test_vision_webots.lua");
elseif teamID==22 then

	print('football')
	dofile("Player/Test/test_football.lua");
else
	dofile("Player/Test/test_main_webots_parallel.lua");
end

