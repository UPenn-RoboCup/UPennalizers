module(... or "", package.seeall)

require('unix')
webots = false;
darwin = false;

local cwd = unix.getcwd();
-- the webots sim is run from the WebotsController dir (not Player)
if string.find(cwd, "WebotsController") then
  webots = true;
  cwd = cwd.."/Player"
  package.path = cwd.."/?.lua;"..package.path;
end

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
package.path = cwd.."/Motion/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;

require('Config');
require('shm')
require('Body')
require('vector')
require('getch')
require('vcm'); 
require('Motion');
require('walk');
require('Broadcast')
require('Speak')

getch.enableblock(1);
unix.usleep(1E6*1.0);

tUpdate = unix.time();
count = 0;
vcmcount=0;
local t0=Body.get_time();
local last_update_time=t0;
local headangle=vector.new({0,10*math.pi/180});
local headsm_running=0;
local last_vision_update_time=t0;
targetvel=vector.zeros(3);
t_update=2;

broadcast_enable=0;
ballcount,visioncount,imagecount=0,0,0;

cameraparamcount=1;
broadcast_count=0;
buttontime=0;

function update()
  Body.set_syncread_enable(0); --read from only head servos
  count = count + 1;
  local t = Body.get_time();

  if (count % 300 == 0) then
    print('fps: '..(300 / (unix.time() - tUpdate))..', Level: '..broadcast_enable );
    tUpdate = unix.time();
  end

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
  Broadcast.update(broadcast_enable);
end

local tDelay=0.002*1E6;
while 1 do
--Wait until dcm has done reading/writing
  unix.usleep(tDelay);
  update()
end

