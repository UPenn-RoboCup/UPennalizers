module(... or "", package.seeall)

-- Add the required paths
--local cwd = unix.getcwd();
local cwd = os.getenv('PWD');
computer = os.getenv('COMPUTER') or "";
if (string.find(computer, "Darwin")) then
   -- MacOS X uses .dylib:                                                      
   package.cpath = cwd.."/Lib/?.dylib;"..package.cpath;
else
   package.cpath = cwd.."/Lib/?.so;"..package.cpath;
end
package.path = cwd.."/Util/?.lua;"..package.path;
package.path = cwd.."/Config/?.lua;"..package.path;
package.path = cwd.."/Lib/?.lua;"..package.path;
package.path = cwd.."/Dev/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path; 

require('unix')
require('vcm')
require('getch')

require('Vision')

Vision.entry();

getch.enableblock(1);

count = 0;
tUpdate = unix.time();

while (true) do
  count = count + 1;
  tstart = unix.time();

  -- update vision 
  imageProcessed = Vision.update();
  --print(imageProcessed)

  --[[
  print('press n');
  while (getch.get() ~= 'n') do
    unix.sleep(.1);
  end
  --]]
  unix.sleep(0.1);
end

-- exit 
Vision.exit();

