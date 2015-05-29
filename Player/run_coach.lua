require'init'
require'Config'
require'Body'
require'CoachComm'
CoachComm.init(Config.dev.ip_wireless)

-- Coach runs every 10 seconds
local tperiod = 1 / 10
local count = 0
local running = true
local get_time = Body.get_time
local usleep = unix.usleep
local t0
local coach_msg, coach_ret
local teamNumber = Config.game.teamNumber

local function entry()
  t0 = get_time()
  print("Let's get to rumble!")
end

local function update()
  coach_msg = string.format("Hi %d", count)
  coach_ret = coachcomm.send(teamNumber, coach_msg)
end

local function exit()
  print("Good game!")
end

entry()
while running do
  tstart = get_time()
  update()
  tloop = get_time() - tstart
  count = count + 1
  if tloop < tperiod then usleep(1e6*(tperiod - tloop)) end
end
exit()