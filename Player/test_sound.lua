dofile('init.lua')
require('Config'); 
require('getch');
local sound = require('Sound')
sound.enable_receiver();
--file = io.open("soundLog.txt", "w")
file = io.open("soundLog.txt", "w")

function autocorrelate(data, shift)
  local autocoeff = 0
  local local_max = 0
  for i = 0,100-shift-1 do
    --print (data[i], data[i+shift]) 
    if data[i] ~= nil and data[i+shift] ~= nil then 
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
  local n = #data
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
  local len = #array
  local count = 0
  for i = 1, len do
    if array[i] >= threshold then count = count + 1 else end
  end
  if count >= 0.8 * len then return true else return false end
end

function check_period(array, value)
  local len = #array
  local count = 0
  for i = 1, len do
    if array[i] == value then count = count + 1 else end
  end
  if count >= 0.8 * len then return true else return false end 
end

local running = true;
print_count = 0
count = 0
autocoeff = {}
amplitude = {}
period = {}
autocoeff_thres = 50 --Config.game.whistle_autocoeff or 100 --50
amplitude_thres = 15000 --Config.game.whistle_amplitude or 20000 --10000
period_thres = Config.game.whistle_period or 13

while running do
  local str = getch.get();
  local local_max = 1;
  data = sound.get_pcm_buffer()
  --print (#data)
  --print (autocorrelate(data, 500))
  local len = #data/32
  for i = 0,31 do
    toprint = ""
    for j=1,len do
      toprint = toprint..tostring(data[i*len+j])
      toprint = toprint..' '
    end
    file:write(toprint..'\n')
    --print (toprint)
  end   
  currnet_pitch = false
  pitch = detect_pitch_autocorrelation(data, 500) or {0,0,0}
  print_count = (print_count + 1) % 50
  autocoeff[print_count] = math.abs(pitch[1])
  amplitude[print_count] = pitch[2]
  period[print_count] = pitch[3]
  --file:write(pitch[1]..', '..pitch[2]..', '..pitch[3]..'/ \n')
  if print_count % 30 == 0 then
    pitch = detect_pitch_autocorrelation(data, 500) or {0,0,0}
    if #pitch == 3 then print (pitch[1], pitch[2], pitch[3]) end
  end
  if #pitch == 3 then 
    if check(autocoeff, autocoeff_thres) and check(amplitude, amplitude_thres) and check_period(period, period_thres) then currnet_pitch = true; print('SUCCESS!') end
  end
--[[
  local len = #data/32
  
  for i = 0,31 do
    toprint = ""
    for j=1,len do
      toprint = toprint..tostring(data[i*len+j])
      toprint = toprint..' '
    end
    file:write(toprint..'\n')
    --print (toprint)
  end   
  --print("")
  if #str>0 then
  local byte = string.byte(str, 1);
  if byte==string.byte("i") then running = (not running)  end
  end
  --io.close(file)
  ]]
end
