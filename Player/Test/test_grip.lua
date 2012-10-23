module(... or '', package.seeall)

-- Get Platform for package path
cwd = '.';
local platform = os.getenv('PLATFORM') or '';
if (string.find(platform,'webots')) then cwd = cwd .. '/Player';
end

-- Get Computer for Lib suffix
local computer = os.getenv('COMPUTER') or '';
if (string.find(computer, 'Darwin')) then
	-- MacOS X uses .dylib:
	package.cpath = cwd .. '/Lib/?.dylib;' .. package.cpath;
else
	package.cpath = cwd .. '/Lib/?.so;' .. package.cpath;
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

require('unix')
require('Config')
require('shm')
require('vector')
require('mcm')
require('Speak')
require('getch')
require('Body')
require('Motion')

Motion.entry();

darwin = false;
webots = false;


-- Enable OP specific 
if(Config.platform.name == 'OP') then
	darwin = true;
	--SJ: OP specific initialization posing (to prevent twisting)
	Body.set_body_hardness(0.3);
	Body.set_actuator_command(Config.sit.initangle);
	unix.usleep(1E6*1.0);
	Body.set_body_hardness(0);
end

getch.enableblock(1);
unix.usleep(1E6*1.0);

--This is robot specific 
webots = false;

init = false;
calibrating = false;
ready = false;
if( webots or darwin) then
	ready = true;
end


smindex = 0;
initToggle = true;

targetvel=vector.zeros(3);

function process_keyinput()

	local str=getch.get();
	if #str>0 then
		local byte=string.byte(str,1);

		-- Walk velocity setting
		if byte==string.byte("i") then	targetvel[1]=targetvel[1]+0.02;
		elseif byte==string.byte("j") then	targetvel[3]=targetvel[3]+0.1;
		elseif byte==string.byte("k") then	targetvel[1],targetvel[2],targetvel[3]=0,0,0;
		elseif byte==string.byte("l") then	targetvel[3]=targetvel[3]-0.1;
		elseif byte==string.byte(",") then	targetvel[1]=targetvel[1]-0.02;
		elseif byte==string.byte("h") then	targetvel[2]=targetvel[2]+0.02;
		elseif byte==string.byte(";") then	targetvel[2]=targetvel[2]-0.02;

		elseif byte==string.byte("1") then	
			kick.set_kick("kickForwardLeft");
			Motion.event("kick");
		elseif byte==string.byte("2") then	
			kick.set_kick("kickForwardRight");
			Motion.event("kick");
		elseif byte==string.byte("3") then	
			kick.set_kick("kickSideLeft");
			Motion.event("kick");
		elseif byte==string.byte("4") then	
			kick.set_kick("kickSideRight");
			Motion.event("kick");

		elseif byte==string.byte("5") then
			walk.doWalkKickLeft();
		elseif byte==string.byte("6") then
			--                walk.doWalkKickRight();
			walk.doSideKickRight();


		elseif byte==string.byte("a") then
			grip.throw = 0;			
			Motion.event('pickup')
		elseif byte==string.byte("f") then
			grip.throw = 1;
			Motion.event('pickup')


		elseif byte==string.byte("7") then	
			Motion.event("sit");
		elseif byte==string.byte("8") then	
			if walk.active then 
				walk.stopAlign();
			end
			Motion.event("standup");
		elseif byte==string.byte("9") then	
			Motion.event("walk");
			walk.start();
		end
		walk.set_velocity(unpack(targetvel));

		print("Command velocity:",unpack(walk.velCommand))
	end
end

-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();

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
			init = true;
		else
			if (count % 20 == 0) then
				if (Body.get_change_state() == 1) then
					Speak.talk('Calibrating');
					calibrating = true;
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

	else
		-- update state machines 
		Motion.update();
		Body.update();
	end

	local dcount = 50;
	if (count % 50 == 0) then
		--    print('fps: '..(50 / (unix.time() - tUpdate)));
		tUpdate = unix.time();
		-- update battery indicator
		Body.set_indicator_batteryLevel(Body.get_battery_level());
	end

	-- check if the last update completed without errors
	lcount = lcount + 1;
	if (count ~= lcount) then
		print('count: '..count)
		print('lcount: '..lcount)
		Speak.talk('missed cycle');
		lcount = count;
	end
end

-- if using Webots simulator just run update
if (webots) then
	while (true) do
		-- update motion process
		update();
		io.stdout:flush();
	end
end

if( darwin ) then
	local tDelay = 0.005 * 1E6; -- Loop every 5ms
	while 1 do
		update();
		process_keyinput();
		unix.usleep(tDelay);
	end
end
