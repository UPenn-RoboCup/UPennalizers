module(... or '', package.seeall)

cwd = '.';
local platform = os.getenv('PLATFORM') or '';
if (string.find(platform,'webots')) then cwd = cwd .. '/Player';
end

local computer = os.getenv('COMPUTER') or '';
if (string.find(computer, 'Darwin')) then
  package.cpath = cwd .. '/Lib/?.so;' .. package.cpath;
else
  package.cpath = cwd .. '/Lib/?.so;' .. package.cpath;
end

package.path = cwd .. '/?.lua;' .. package.path;
package.path = cwd .. '/Util/?.lua;' .. package.path;
package.path = cwd .. '/Config/?.lua;' .. package.path;
package.path = cwd .. '/Lib/?.lua;' .. package.path;
package.path = cwd .. '/Dev/?.lua;' .. package.path;
package.path = cwd .. '/Motion/?.lua;' .. package.path;
package.path = cwd .. '/Motion/keyframes/?.lua;' .. package.path;
package.path = cwd .. '/Motion/Walk/?.lua;' .. package.path;
package.path = cwd .. '/Vision/?.lua;' .. package.path;
package.path = cwd .. '/World/?.lua;' .. package.path;
require 'Config'
local simple_ipc = require'simple_ipc'

local state_channels = {};
local action_channels = {};
for i=1,Config.game.nPlayers do
  state_channels[i] = simple_ipc.setup_subscriber('state'..i)
  action_channels[i] = simple_ipc.setup_publisher('action'..i)
  state_channels[i].callback = function()
    local state, has_more = state_channels[i]:receive()
    print('Player '..i..' state',state)
    local command = string.format('walk.set_velocity(%f,%f,%f)',
      i/4,0,0
    );
    command = "walk.doWalkKickLeft()"
    action_channels[i]:send(command)
  end
end
local state_poll = simple_ipc.wait_on_channels( state_channels );
local state_timeout = 1000; -- 1000 ms

while true do
  -- Wait on a particular robot state
  -- local state, has_more = state_channel:receive();
  -- print( state );
  state_poll:poll( state_timeout );
end
