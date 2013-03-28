package.path = "./../Util/?.lua;"..package.path;
package.cpath = "./../Lib/?.so;"..package.cpath;
local simple_ipc = require 'simple_ipc'
local mp = require 'MessagePack'
local util = require 'util'
local test_channel = simple_ipc.setup_publisher('test'); --ipc
--local test_channel = simple_ipc.setup_publisher(5555); --tcp
local imu = {Ax=0,Ay=0,Az=1,Wx=0,Wy=0,Wz=1}
while true do
  imu.Wz = math.random(20)/2
  print(util.ptable(imu))
	test_channel:send( mp.pack(imu) )
  unix.usleep(1e6)
end
