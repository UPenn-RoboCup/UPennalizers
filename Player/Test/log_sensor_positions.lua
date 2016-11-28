module(..., package.seeall);
dofile("/home/nao/UPennDev/Player/init.lua");
require('NaoBody');
require('getch');
require('unix');

recordState = nil;
manualRecordState = nil;

jointNames = { "HeadYaw", "HeadPitch", "LShoulderPitch",
               "LShoulderRoll", "LElbowYaw", "LElbowRoll",
               "LHipYawPitch", "LHipRoll", "LHipPitch",
               "LKneePitch", "LAnklePitch", "LAnkleRoll",
               "RHipYawPitch", "RHipRoll", "RHipPitch",
               "RKneePitch", "RAnklePitch", "RAnkleRoll",
               "RShoulderPitch", "RShoulderRoll", "RElbowYaw",
               "RElbowRoll" };
--[[
function determineState()
  while true do
    io.write("Press 1 to log sensor positions upon pressing r.\n");
    io.write("Press 2 to continuously log sensor positions.\n");

    recordState = string.byte(io.read(), 1);

    if recordState == string.byte("1") or recordState == string.byte("2") then
      file = io.open("/home/nao/UPennDev/Player/Test/sensor_position_log.txt", "w+");
      file:close();
      break;
    end
  end
end
--]]
function clearFile()
  file = io.open("/home/nao/UPennDev/Player/Test/sensor_position_log.txt", "w+");
  file:close();
end

function openFile()
  return io.open("/home/nao/UPennDev/Player/Test/sensor_position_log.txt", "a");
end
--[[
function record()
  if recordState == string.byte("1") and manualRecordState == string.byte("true") then    
    while io.read() do end
    storeData();
    manualRecordState = nil;
  elseif recordState == string.byte("2") then
    storeData();
  end
end
]]--
function record(file)
  local q = NaoBody.get_sensor_position();

  file:write(unix.time(), ",");

  for k, v in ipairs(q) do
    file:write(k, " : ", v, "\n");
  end
  
  file:write("========", "\n");
end
