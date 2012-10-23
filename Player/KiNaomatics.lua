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
package.path = cwd.."/Motion/Walk/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/BodyFSM/?.lua;"..package.path;
package.path = cwd.."/HeadFSM/?.lua;"..package.path;

require('Config')
require('shm')
require('vector')
require('Motion')
require('walk')
require('Body')
require("getch")
require('kick')
require('Speak')
require('Comm')

-- initialize state machines
Motion.entry();

walk.stop();
targetvel=vector.new({0,0,0});
headangle=vector.new({0,0});

walkKick=true;

--Adding head movement && vision...--
Body.set_head_hardness({0.4,0.4});

-- main loop
local tUpdate = unix.time();
local count=0;
local countInterval=1000;
count_dcm=0;
t0=unix.time();
init = false;
calibrating = false;
ready = false;
calibrated=false;

function update()

  count = count + 1;
  
	if (not init)  then
    if (calibrating) then
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        calibrating = false;
        ready = true;
        Comm.init("192.168.1.255", 54321);
      end
      
    elseif (ready) then
      init = true;
    else
      if (count % 20 == 0) then
        if calibrated==false then
          Speak.talk('Calibrating');
          calibrating = true;
          calibrated=true;
        elseif (Body.get_change_role() == 1) then
          smindex = (smindex + 1) % #Config.fsm.body;
        end
      end

      -- toggle state indicator
      if (count % 100 == 0) then
        initToggle = not initToggle;
        if (initToggle) then
          Body.set_indicator_state({1,1,1}); 
        else
          Body.set_indicator_state({0,0,0});
        end
      end
    end
  end

  t=unix.time();
  Motion.update();
  Body.set_head_hardness(0.2);
end
