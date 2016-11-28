module(... or "",package.seeall)
--TODO: what about coroutine instead running to files?
cwd = os.getenv('PWD')
require('init')
require('Config')
Config.dev.body = 'SimBody';
Config.dev.camera = 'SimCam';
Config.game.teamNumber = 1;
Config.game.playerID = 1;
Config.game.robotID = 1;
Config.game.role = 0; -- 0 for goalie
require('vcm')
require('unix')
require('shm')
require('Broadcast')

local cameranum
if (arg[1] == nil) then
  print("WARNING: no camera specific, using default 1")
  cameranum = 1
else 
  cameranum = tonumber(arg[1])
end
if cameranum == 2 then
  require('Parallel_Arbitrator')
end
local Vision = require 'Vision_thread'
Vision_thread = Vision.entry(cameranum)
count = 0;
tUpdate = unix.time();

while (true) do
  count = count + 1;
  tstart = unix.time();
  -- update vision 
  Vision_thread:update(cameranum);
  if (cameranum == 2) then
    Parallel_Arbitrator.ball_arbitration();
  end
  unix.sleep(1.0);
end

