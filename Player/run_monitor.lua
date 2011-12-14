module(... or "", package.seeall)

require('unix')

local cwd = unix.getcwd();
computer = os.getenv('COMPUTER') or "";
if (string.find(computer, "Darwin")) then
   -- MacOS X uses .dylib:
   package.cpath = cwd.."/Lib/?.dylib;"..package.cpath;
else
   package.cpath = cwd.."/Lib/?.so;"..package.cpath;
end

package.path = cwd .. '/?.lua;' .. package.path;
package.path = cwd .. '/Util/?.lua;' .. package.path;
package.path = cwd .. '/Config/?.lua;' .. package.path;
package.path = cwd .. '/Lib/?.lua;' .. package.path;
package.path = cwd .. '/Dev/?.lua;' .. package.path;
package.path = cwd .. '/Motion/?.lua;' .. package.path;
package.path = cwd .. '/Motion/keyframes/?.lua;' .. package.path;
package.path = cwd .. '/Vision/?.lua;' .. package.path;
package.path = cwd .. '/World/?.lua;' .. package.path;

--require 'Config'
require('getch')
require('Broadcast')

-- Do not wait for a carriage return
getch.enableblock(1);
unix.usleep(1E6*1.0);

local count = 0;
local ncount = 100;
local t0 = unix.time();
local tUpdate = t0;

-- Broadcast the images at a lower rate than other data
local maxFPS = 10;
local imgFPS = 5;
local maxPeriod = 1.0 / maxFPS;
local imgRate = math.max( math.floor( maxFPS / imgFPS ), 1);

local broadcast_enable=0;

function update()
  -- Get a keypress
  local str=getch.get();
  if #str>0 then
    local byte=string.byte(str,1);
    if byte==string.byte("g") then	--Broadcast selection
      local mymod = 4;
      broadcast_enable = (broadcast_enable+1)%mymod;
      print("Broadcast:", broadcast_enable);
    end
  end
  -- Always send non-image data
  Broadcast.update(broadcast_enable);
  -- Send image data every so often
  if( count % imgRate == 0 ) then
    Broadcast.update_img(broadcast_enable);    
  end
end

while true do

  count = count + 1;

  -- Get the time before sending packets
  local tstart = unix.time();
  update();
  -- Get time after sending packets
  tloop = unix.time() - tstart;
  -- Sleep in order to get the right FPS
  if (tloop < 0.025) then
    unix.usleep((.025 - tloop)*(1E6));
  end

  -- Display our FPS and broadcast level
  if (count % ncount == 0) then
    print('fps: '..(ncount / (tstart - tUpdate))..', Level: '..broadcast_enable );
    tUpdate = unix.time();
  end

end
