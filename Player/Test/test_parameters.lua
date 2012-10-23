module(... or "", package.seeall)

require('unix')
webots = false;
darwin = false;

-- mv up to Player directory
unix.chdir('~/Player');

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
--require('World')
--require('Team')
--require('battery')
Vision = require 'vcm' -- Steve
Speak.talk("Starting test parameters.")

--World.entry();
--Team.entry();

-- initialize state machines
Motion.entry();
--Motion.sm:set_state('stance');

walk.stop();
getch.enableblock(1);
targetvel=vector.new({0,0,0});
headangle=vector.new({0,0});

walkKick=true;

--Adding head movement && vision...--
Body.set_head_hardness({0.4,0.4});

Motion.fall_check=0; --auto getup disabled

-- main loop
print(" Key commands \n 7:sit down 8:stand up 9:walk\n i/j/l/,/h/; :control walk velocity\n k : walk in place\n [, ', / :Reverse x, y, / directions\n 1/2/3/4 :kick\n w/a/s/d/x :control head\n t/T :alter walk speed\t f/F :alter step phase\t r/R :alter step height\t c/C :alter supportX\t v/V :alter supportY\n b/B :alter foot sensor threshold \t n/N :alter delay time.\n 3/4/5 :turn imu feedback/joint encoder feedback/foot sensor feedback on or off.");
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
      end
      
    elseif (ready) then
    --[[
      -- initialize state machines
      package.path = cwd..'/BodyFSM/'..Config.fsm.body[smindex+1]..'/?.lua;'..package.path;
      package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
      package.path = cwd..'/GameFSM/'..Config.fsm.game..'/?.lua;'..package.path;
      require('BodyFSM')
      require('HeadFSM')
      require('GameFSM')

      BodyFSM.entry();
      HeadFSM.entry();
      GameFSM.entry();
      
      if( webots ) then
        BodyFSM.sm:add_event('button');
      end
			--]]
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
  --battery.monitor();

  local str=getch.get();
  if #str>0 then
	local byte=string.byte(str,1);
		if byte==string.byte("i") then		
			targetvel[1]=targetvel[1]+0.01;
		elseif byte==string.byte("j") then	
			targetvel[3]=targetvel[3]+0.1;
		elseif byte==string.byte("k") then	
			targetvel[1],targetvel[2],targetvel[3]=0,0,0;
		elseif byte==string.byte("l") then	
			targetvel[3]=targetvel[3]-0.1;
		elseif byte==string.byte(",") then	
			targetvel[1]=targetvel[1]-0.01;
		elseif byte==string.byte("h") then	
			targetvel[2]=targetvel[2]+0.01;
		elseif byte==string.byte(";") then	
			targetvel[2]=targetvel[2]-0.01;
		elseif byte==string.byte("[") then
			targetvel[1]=-targetvel[1];
		elseif byte==string.byte("'") then
			targetvel[2]=-targetvel[2];
		elseif byte==string.byte("/") then
			targetvel[3]=-targetvel[3];

		--Move the head around--
		elseif byte==string.byte("w") then
			headangle[2]=headangle[2]-5*math.pi/180;
		elseif byte==string.byte("a") then	
			headangle[1]=headangle[1]+5*math.pi/180;
		elseif byte==string.byte("s") then	
			headangle[1],headangle[2]=0,0;
		elseif byte==string.byte("d") then	
			headangle[1]=headangle[1]-5*math.pi/180;
		elseif byte==string.byte("x") then	
			headangle[2]=headangle[2]+5*math.pi/180;

		--Change configuration params in real time--
		elseif byte==string.byte("t") then
			Config.walk.tStep = Config.walk.tStep - .01;
		elseif byte==string.byte("T") then
			Config.walk.tStep = Config.walk.tStep + .01;
		elseif byte==string.byte("f") then
			Config.walk.phSingle[1] = Config.walk.phSingle[1] - .01;
			Config.walk.phSingle[2] = Config.walk.phSingle[2] + .01;
		elseif byte==string.byte("F") then
			Config.walk.phSingle[1] = Config.walk.phSingle[1] + .01;
			Config.walk.phSingle[2] = Config.walk.phSingle[2] - .01;
		elseif byte==string.byte("r") then
			Config.walk.stepHeight = Config.walk.stepHeight - .001;
		elseif byte==string.byte("R") then
			Config.walk.stepHeight = Config.walk.stepHeight + .001;
		elseif byte==string.byte("c") then
			Config.walk.supportX = Config.walk.supportX - .001;
		elseif byte==string.byte("C") then
			Config.walk.supportX = Config.walk.supportX + .001;
		elseif byte==string.byte("v") then
			Config.walk.supportY = Config.walk.supportY - .001;
		elseif byte==string.byte("V") then
			Config.walk.supportY = Config.walk.supportY + .001;
		elseif byte==string.byte('y') then
			Config.walk.bodyHeight = Config.walk.bodyHeight - .001;
		elseif byte== string.byte('Y') then
			Config.walk.bodyHeight = Config.walk.bodyHeight + .001;
    elseif byte==string.byte('\\') then
      walkKick=not walkKick;
    elseif byte==string.byte("1") then
      if walkKick then	
        walk.doWalkKickLeft();
      else 
        kick.set_kick("KickForwardLeft");	
        Motion.event("kick");
      end
    elseif byte==string.byte("2") then
      if walkKick then
        walk.doWalkKickRight();
      else
        kick.set_kick("kickForwardRight");
        Motion.event("kick");
      end
		--turn assorted stability checks on/off--
		elseif byte==string.byte("3") then
		  Config.walk.imuOn = not Config.walk.imuOn;
		elseif byte==string.byte("4") then
			Config.walk.jointFeedbackOn = not Config.walk.jointFeedbackOn;
		elseif byte==string.byte("5") then
			Config.walk.fsrOn = not Config.walk.fsrOn;

		elseif byte==string.byte("7") then	Motion.event("sit");
		elseif byte==string.byte("8") then	
			walk.stop();
			Motion.event("standup");
		elseif byte==string.byte("9") then	
			Motion.event("walk");
			walk.start();
		end
		print(string.format("\n Walk Velocity: (%.2f, %.2f, %.2f)",unpack(targetvel)));
		walk.set_velocity(unpack(targetvel));
		print "huh?";
		Body.set_head_command(headangle);
		print(string.format("Head angle: %d, %d",
			headangle[1]*180/math.pi,
			headangle[2]*180/math.pi));
		print(string.format("Walk settings:\n tStep: %.2f\t phSingle: {%.2f, %.2f}\t stepHeight: %.3f\n supportX: %.3f\t supportY: %.3f\t", Config.walk.tStep, Config.walk.phSingle[1], Config.walk.phSingle[2], Config.walk.stepHeight, 
Config.walk.supportX, Config.walk.supportY));
 

end
end

