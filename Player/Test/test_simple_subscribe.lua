package.path = "./../Util/?.lua;"..package.path;
package.cpath = "./../Lib/?.so;"..package.cpath;
local util = require'util'
local mp = require'MessagePack'
local simple_ipc = require 'simple_ipc'
local test_channel = simple_ipc.setup_subscriber('test');
--local test_channel = simple_ipc.setup_subscriber(5555);
while true do
	local data = test_channel:receive()
  util.ptable( mp.unpack(data) )
end
