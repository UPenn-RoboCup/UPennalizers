module(... or "", package.seeall)

require('unix')

-- mv up to Player directory
unix.chdir('..');

local cwd = unix.getcwd();

package.cpath = cwd.."/Lib/?.so;"..package.cpath;
package.path = cwd.."/Util/?.lua;"..package.path;
package.path = cwd.."/Config/?.lua;"..package.path;
package.path = cwd.."/Lib/?.lua;"..package.path;
package.path = cwd.."/Dev/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path;
package.path = cwd.."/Motion/keyframes/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/BodyFSM/?.lua;"..package.path;
package.path = cwd.."/HeadFSM/?.lua;"..package.path;
package.path = cwd.."/GameFSM/?.lua;"..package.path;

require('mcm');
us = require('UltraSound');

--Body.set_actuator_us(68);
--unix.usleep(1000000);


--[[
while(1) do
  left = vector.new(Body.get_sensor_usLeft());
  right = vector.new(Body.get_sensor_usRight());
  mcm.set_us_left(left);
  mcm.set_us_right(right);
  unix.usleep(10000);
end
--]]

us.entry();

function update()
  us.update();
  -- update shm
  mcm.set_us_left(us.left);
  mcm.set_us_right(us.right);
end


while(1) do
  update()
  unix.usleep(10000);
end

--[[
-- test switch time
t0 = unix.time();
print(t0)
Body.set_actuator_us(0);
while(0 ~= Body.get_sensor_usCommand()[1]) do
  unix.usleep(1000);
end
t1 = unix.time();
print(t1-t0);

unix.usleep(1000000);


t0 = unix.time();
print(t0)
Body.set_actuator_us(3);
while(3 ~= Body.get_sensor_usCommand()[1]) do
  unix.usleep(1000);
end
t1 = unix.time();
print(t1-t0);
--]]

