local cwd = os.getenv('PWD')
package.cpath = cwd..'/../Lib/Modules/Util/Unix/?.so;'..package.cpath
package.cpath = cwd..'/../Lib/Modules/Util/Shm/?.so;'..package.cpath
package.cpath = cwd..'/../Lib/Modules/Util/CArray/?.so;'..package.cpath
package.cpath = cwd..'/../Lib/Modules/Util/Msgpack/?.so;'..package.cpath
package.cpath = cwd..'/../Lib/Modules/Comm/?.so;'..package.cpath
package.path = cwd..'/../Player/Config/?.lua;'..package.path
package.path = cwd..'/../Player/Util/?.lua;'..package.path

require 'util'
require 'Config'
require 'unix'
require 'Comm'
require 'util'
require 'msgpack'

Comm.init(Config.dev.ip_wireless, Config.dev.ip_wireless_port);

local test_file_name = '../Player/Data/lut_grasp_daytime.raw'
local test_file = io.open(test_file_name)
local test_str = test_file:read('*a')

local max_packet_size = 64000 --math.floor(65535 / 2)
local max_packet_size = math.floor(65535 / 2)
local pktDelay = 1E6 * 0.001; --For image and colortable

function udp_packet_split(str)
  local array = {}
  local ptr = 1
  while (ptr < #str) do
    array[#array + 1] = str:sub(ptr, math.min(ptr + max_packet_size, #str))
    ptr = ptr + max_packet_size + 1
  end
  return array
end

function send_packet(header, data_str)
  -- split png string to fit udp packet
  local array = udp_packet_split(data_str) 
  header.total = #array

  local tSerialize=0;
  local tSend=0;  
  local totalSize=0;
--  for i = 1, #array do
--  for i = 1, 1 do
  i = 1
    header.arr = array[i]
    header.num = i
    header.timestamp = unix.time()
    t0 = unix.time();
    local send_msg = msgpack.pack(header)
    t1 = unix.time();
    tSerialize= tSerialize + t1 - t0;
    Comm.send(send_msg, #send_msg);
    t2 = unix.time();
    tSend=tSend+t2-t1;

    totalSize=totalSize+#send_msg;
--  end

--  if debug>0 then
--    print("Image info array num:",#array,"Total size",totalSize);
--    print("Total Serialize time:",#array,"Total",tSerialize);
--    print("Total Send time:",tSend);
--  end
end

while (true) do
  t0 = unix.time();
  -- print('send timestamp', t0)
  t0_str = tostring(t0);
--  Comm.send(t0_str, #t0_str)
  send_packet({}, test_str)

  msg = Comm.receive()
  while (msg == nil)  do
    msg = Comm.receive()
  end
  local header = msgpack.unpack(msg)
  print('Latency', 'send:'..t0, 'recv:'..header.timestamp,  
              unix.time() - tonumber(header.timestamp))
--  print('Latency', 'send:'..t0, 'recv:'..msg,  unix.time() - tonumber(msg))


  unix.usleep(1E6 * 0.005)
end
