--module(..., package.seeall);
dofile('init.lua')
require('getch');
require('unix');
require('gcm');
require('Speak');
require('Body');
require('vector');
local sound = require('Sound');
sound.enable_receiver();
file = io.open("paramsLog.txt", "w")

function autocorrelate(data, shift)
  local autocoeff = 0
  local local_max = 0
  for i = 0,100-shift-1 do
    --print (data[i], data[i+shift]) 
    if data ~= nil and data[i] ~= nil and data[i+shift] ~= nil then 
      autocoeff = autocoeff + data[i] * data[i + shift]
      if data[i] > local_max then local_max = data[i] end
    end 
  end
  return autocoeff / 100000000, local_max
end

function detect_pitch_autocorrelation(data, max_width)
  local current_shift = 10
  local pitch_detected = false
  local previous_coeff, autocoeff, local_max
  previous_coeff, local_max = autocorrelate(data, current_shift)
  local n = 0
  if data ~= nil then n = #data end 
  local previous_derivative = -1
  local current_shift = current_shift + 1
  while (not pitch_detected and current_shift < max_width) do
    autocoeff, local_max = autocorrelate(data, current_shift)
    max = local_max;
    current_derivative = autocoeff - previous_coeff
    if (current_derivative < 0 and previous_derivative >= 0) then 
      pitch_detected = true
      return {autocoeff, local_max, current_shift}
    else
      previous_derivative = current_derivative
      previous_coeff = autocoeff
      current_shift = current_shift + 1
    end
  end
  if not pitch_detected then 
    print ('pitch not found')
    return {0,0,0}
  end 
end

function check(array, threshold)
  if #array >= 10 then
    local len = #array
    local count = 1
    for i = 1, len do
      if array[i] >= threshold then count = count + 1 else end
    end
    if count > 0.63 * len then return true end
  end
  return false
end

function check_period(array, value)
  if #array >= 10 then
    local len = #array
    local count = 1
    for i = 1, len do
      if array[i] == value then count = count + 1 else end
    end
    if count > 0.8 * len then return true end 
  end
  return false
end
--------------------------------------------------
autocoeff_thres = 50 --Config.game.whistle_autocoeff or 100 --50
amplitude_thres = 15000 --Config.game.whistle_amplitude or 20000 --10000
period_thres = 13 --Config.game.whistle_period or 13
local initialized = false
local autocoeff = {}
local amplitude = {}
local period = {}
local pitch = 0
local print_count = 1
local flag = -1
local game_state = -1

gcm.set_game_kickoff_from_whistle(0);

while true do
	game_state = gcm.get_game_state() or -1
  flag = gcm.get_game_whistle() or -1
  print (game_state, flag);
  if (gcm.get_game_state() == 2 and gcm.get_game_whistle() == 0) then 
    if not initialized then
      autocoeff = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
      amplitude = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
      period = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
      print_count = 1
      initialized = true
    end
    local str = getch.get();
    local currnet_pitch = false;
    local data = sound.get_pcm_buffer();
    pitch = detect_pitch_autocorrelation(data, 500)
    if pitch[1] ~= 0 and pitch[2] ~= 0 and pitch[3] ~= 0 then
      print_count = (print_count + 1) % 21
      autocoeff[print_count] = math.abs(pitch[1])
      amplitude[print_count] = pitch[2]
      period[print_count] = pitch[3]
      file:write(pitch[1]..', '..pitch[2]..', '..pitch[3]..'/\n')
      print (pitch[1], pitch[2], pitch[3]);
    end
    if check(autocoeff, autocoeff_thres) and check(amplitude, amplitude_thres) and check_period(period, period_thres) then
      file:write(Body.get_time()..' PASS\n')
      gcm.set_game_state(3);
      gcm.set_game_whistle(1);
      initialized = false;
    end
    else end
  end

