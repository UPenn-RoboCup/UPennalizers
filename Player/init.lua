module(... or "", package.seeall)

-- this module is used to facilitate interactive debuging

cwd = '.';

uname = io.popen('uname -s')
system = uname:read();

computer = os.getenv('COMPUTER') or system;
package.cpath = cwd.."/Lib/?.so;"..package.cpath;

package.path = cwd.."/Util/?.lua;"..package.path;
package.path = cwd.."/Config/?.lua;"..package.path;
package.path = cwd.."/Lib/?.lua;"..package.path;
package.path = cwd.."/Lib/Util/?.lua;"..package.path;
package.path = cwd.."/Dev/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path;
package.path = cwd.."/Motion/keyframes/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;


require('serialization')
require('string')
require('vector')
require('getch')
require('util')
require('unix')
require('cutil')
require('shm')


