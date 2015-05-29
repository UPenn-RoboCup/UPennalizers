cwd = cwd or os.getenv('PWD')
-- this module is used to facilitate interactive debuging

package.cpath = cwd.."/Lib/?.so;"..package.cpath;

package.path = cwd.."/Util/?.lua;"..package.path;
package.path = cwd.."/Config/?.lua;"..package.path;
package.path = cwd.."/Lib/?.lua;"..package.path;
package.path = cwd.."/Lib/?/?.lua;"..package.path;
package.path = cwd.."/Dev/?.lua;"..package.path;
package.path = cwd.."/Run/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path;
package.path = cwd.."/Motion/keyframes/?.lua;"..package.path;
package.path = cwd.."/Motion/Walk/?.lua;"..package.path;
package.path = cwd.."/Motion/Arms/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/Test/?.lua;"..package.path;
package.path = cwd.."/?.lua;"..package.path;

 -- Check for LuaJit and add to the global namespace
local ok, myffi = pcall(require,'ffi')
if ok then
  ffi = myffi
end

require('serialization')
require('string')
require('vector')
require('getch')
require('util')
require('unix')
require('cutil')
require('shm')
