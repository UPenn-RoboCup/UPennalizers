module(... or "", package.seeall)

cwd = '.';

uname = io.popen('uname -s')
system = uname:read();

computer = os.getenv('COMPUTER') or system;
if (string.find(computer, "Darwin")) then
   -- MacOS X uses .dylib:
   package.cpath = cwd.."/Lib/?.dylib;"..package.cpath;
else
   package.cpath = cwd.."/Lib/?.so;"..package.cpath;
end

package.path = cwd.."/Util/?.lua;"..package.path;
package.path = cwd.."/Config/?.lua;"..package.path;
package.path = cwd.."/Lib/?.lua;"..package.path;
package.path = cwd.."/Lib/Util/?.lua;"..package.path;
package.path = cwd.."/Dev/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path;
package.path = cwd.."/Motion/keyframes/?.lua;"..package.path;
package.path = cwd.."/Motion/Walk/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;

require('Config')
require('OccupancyMap')

maxFPS = 15;
tperiod = 1.0/maxFPS;
maxDisFPS = 5;
DisCount = 0;

OccupancyMap.entry();

while (true) do
  tstart = unix.time();

  OccupancyMap.update();

  tloop = unix.time() - tstart;

  DisCount = DisCount + 1
  if (DisCount % maxDisFPS == 0) then
    print('OccMap Update Time: '..tloop);
  end
  if (tloop < tperiod) then
    unix.usleep((tperiod - tloop)*(1E6));
  end
end

OccupancyMap.exit();

