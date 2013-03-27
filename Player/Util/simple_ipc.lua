local zmq = require 'zmq' -- Based on ZMQ
local poller = require 'zmq/poller'
local simple_ipc = {} -- Our module

--[[
-- On the require, find the interfaces
local f_ifconfig = io.popen( 'ifconfig -l' )
local interface_list = f_ifconfig:read()
f_ifconfig:close()
for interface in string.gmatch(interface_list, "[%a|%d]+") do 
	local f_ifconfig = io.popen( "ifconfig "..interface.." | grep 'inet ' | cut -d ' ' -f 2" )
	local interface_ip = f_ifconfig:read()
	if interface_ip then
		local subnet_search = string.gmatch(interface_ip, "192.168.123.%d+")
		local addr = subnet_search()
		if addr then
			simple_ipc.intercom_interface = interface
			simple_ipc.intercom_interface_ip = interface_ip
		end
	end
	f_ifconfig:close()
end
--]]

-- Simple number of threads
simple_ipc.n_zmq_threads = 2
simple_ipc.local_prefix = 'ipc:///tmp/'
-- Set the intercomputer interface
if simple_ipc.intercom_interface then
	print( string.format('Selecting (%s) as the inter-pc interface\nUsing address (%s)',
	simple_ipc.intercom_interface, simple_ipc.intercom_interface_ip) );
	simple_ipc.intercom_prefix = 'epgm://'..simple_ipc.intercom_interface_ip..';239.192.1.1:'
else
	print( 'There is no inter-pc interface, using TCP' )
	simple_ipc.intercom_prefix = 'tcp://'
end

-- If channel is a number, then use tcp
local function setup_publisher( channel )
	local channel_obj = {}
	local channel_type = type(channel)
	if channel_type=="string" then
		channel_obj.name = simple_ipc.local_prefix..channel
	elseif channel_type=="number" then
    if simple_ipc.intercom_interface then
    else -- port
      channel_obj.name = simple_ipc.intercom_prefix..'*:'..channel
    end
	end
	assert(channel_obj.name)
	print('Publishing on',channel_obj.name)
	
  channel_obj.context_handle = zmq.init( simple_ipc.n_zmq_threads )
  assert( channel_obj.context_handle )

  -- Set the socket type
  channel_obj.socket_handle = channel_obj.context_handle:socket( zmq.PUB );
  assert( channel_obj.socket_handle );

  -- Bind to a message pipeline
	-- TODO: connect?
  channel_obj.socket_handle:bind( channel_obj.name )

  -- Set up the sending object
  function channel_obj.send( self, messages )
    if type(messages) == "string" then
      return self.socket_handle:send( messages );
    end
    local nmessages = #messages;
    for i=1,nmessages do
      local msg = messages[i];
--      assert( type(msg)=="string", 
--        print( string.format("SimpleIPC (%s): Type (%s) not implemented",
--        self.name, type(msg) )
--        ));
      if i==nmessages then
        return self.socket_handle:send( msg );
      else
        ret = self.socket_handle:send( msg, zmq.SNDMORE );
      end
    end
  end
  return channel_obj;
end
simple_ipc.setup_publisher = setup_publisher

local function setup_subscriber( channel )
	local channel_obj = {}
	local channel_type = type(channel)
	if channel_type=="string" then
		channel_obj.name = simple_ipc.local_prefix..channel
	elseif channel_type=="number" then
		channel_obj.name = simple_ipc.intercom_prefix..channel
  else
		channel_obj.name = simple_ipc.intercom_prefix..channel[1]..":"..channel[2]
	end
	assert(channel_obj.name)
	print('Subscribing on',channel_obj.name)

  channel_obj.context_handle = zmq.init( simple_ipc.n_zmq_threads )
  assert( channel_obj.context_handle )

  -- Set the socket type
  channel_obj.socket_handle = channel_obj.context_handle:socket( zmq.SUB );
  assert( channel_obj.socket_handle );

  -- Bind to a message pipeline
	-- Bind?
  local rc = channel_obj.socket_handle:connect( channel_obj.name )
  channel_obj.socket_handle:setopt( zmq.SUBSCRIBE, '', 0 )

	-- Set up receiving object
	function channel_obj.receive( self )
	  local ret = self.socket_handle:recv();
		local has_more = self.socket_handle:getopt(zmq.RCVMORE)
    return ret, has_more==1;
  end

  return channel_obj;
end
simple_ipc.setup_subscriber = setup_subscriber

local function wait_on_channels( channels )
  local poll_obj = poller.new( #channels )
	for i=1,#channels do
    poll_obj:add( channels[i].socket_handle, zmq.POLLIN, channels[i].callback );--no callback yet
	end
	return poll_obj;
end
simple_ipc.wait_on_channels = wait_on_channels

return simple_ipc
