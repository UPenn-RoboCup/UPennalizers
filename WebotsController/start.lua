require('controller');

print("\nStarting Webots Lua controller...");

playerID = os.getenv('PLAYER_ID') + 0;
teamID = os.getenv('TEAM_ID') + 0;

dofile("Player/player.lua");

