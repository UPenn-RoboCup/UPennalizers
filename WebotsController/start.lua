require('controller');

print("\nStarting Webots Lua controller...");

playerID = os.getenv('PLAYER_ID') + 0;
teamID = os.getenv('TEAM_ID') + 0;

dofile("Player/player.lua");
-- Run test_vision
--dofile("Player/Test/test_vision_webots_op.lua");
--dofile("Player/Test/test_walk_webots_op.lua");

