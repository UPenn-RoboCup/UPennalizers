local cwd = os.getenv('PWD')
package.cpath = cwd..'/../Lib/Modules/Util/?.so;'..package.cpath
package.cpath = cwd..'/../Lib/Modules/Util/Shm/?.so;'..package.cpath
package.cpath = cwd..'/../Lib/Modules/Util/CArray/?.so;'..package.cpath
package.cpath = cwd..'/../Lib/Modules/Util/Unix/?.so;'..package.cpath
package.cpath = cwd..'/../Lib/Modules/Comm/?.so;'..package.cpath
package.path = cwd..'/../Player/Config/?.lua;'..package.path
package.path = cwd..'/../Player/Util/?.lua;'..package.path

require 'util'
require 'Config'
require 'unix'
require 'Comm'
require 'util'

Comm.init(Config.dev.ip_wireless, Config.dev.ip_wireless_port);

while (true) do
  msg = Comm.receive();
  if (msg)  then
--    print(msg)
    Comm.send(msg, #msg);
  end

  unix.usleep(1E6*0.005);
end
