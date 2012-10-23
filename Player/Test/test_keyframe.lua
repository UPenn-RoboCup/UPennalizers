-- General Includes
module(... or "", package.seeall)

cwd = '.';
local computer = os.getenv('COMPUTER') or "";
--local computer = 'Darwin'
if (string.find(computer, 'Darwin')) then
	-- MacOS X uses .dylib:
	package.cpath = cwd .. './Lib/?.dylib;' .. package.cpath;
else
	package.cpath = cwd .. './Lib/?.so;' .. package.cpath;
end

require('unix')
require('os')

----------------------------
-- mv up to Player directory
unix.chdir('..');

if (#arg == 0) then
	print('no keyframe specified');
	print('example usage:');
	print('lua test_keyframe.lua <filename>');
	os.exit();
end

filename = arg[1];

webots = false;
local cwd = unix.getcwd();
-- the webots sim is run from the WebotsController dir (not Player)
if string.find(cwd, "WebotsController") then
	webots = true;
	cwd = cwd.."/Player"
	package.path = cwd.."/?.lua;"..package.path;
end

--computer = os.getenv('COMPUTER') or "";
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
package.path = cwd.."/Motion/keyframes/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/BodyFSM/?.lua;"..package.path;
package.path = cwd.."/HeadFSM/?.lua;"..package.path;

require('unix')
require('vector')
require('Body')
require('keyframe')
require('getch')


keyframe.load_motion_file(filename, 'test_keyframe');
Body.set_actuator_command(Body.get_sensor_position());
Body.set_body_hardness(0.8);
getch.enableblock(1);

keyframe.entry();

t0 = unix.time();
keyframe.do_motion('test_keyframe');

print "Press \'f\' to step forward by one frame.\n Press \'r\' to progress through the keyframe; press any key to stop progression.\n Press \'p\' to print out current joint angles.\n Press \'q\' to quit testing. Press \'h\' to see these directions again."

print('queue: ', keyframe.get_queue_len() );

while (true) do
	local str=getch.get();
	if #str>0 then
		local byte=string.byte(str,1);
		if byte==string.byte("r") then
			while (true) do
				local cont = getch.get();
				if #cont>0 then break;
				else
					keyframe.update();
					if (keyframe.get_queue_len()==0) then break end;
				end
				-- sleep 0.01s
				unix.usleep(10000);
			end
			print('Done running through!')
		elseif byte == string.byte("f") then
			unix.usleep(10000);
			keyframe.update();
			print("\tStepping forward...");
		elseif byte == string.byte("p") then
			print("Joint angles are: ");
			print(keyframe.getJoints());
		elseif byte==string.byte("h") then
			print "Press \'f\' to step forward by one frame.\n Press \'r\' to progress through the keyframe; press any key to stop progression.\n Press \'p\' to print out current joint angles.\n Press \'q\' to quit testing. Press \'h\' to see these directions again.";
		elseif byte == string.byte("q") then
			print("\tQuitting...");
			break;
		end
		print("\n");
	end

end

print('turn off hardness? (y/n)');
while true do
	local zeroHardness = getch.get();
	if #zeroHardness > 0 then
		local byte = string.byte(zeroHardness, 1);
		if byte == string.byte("y") then 
			Body.set_body_hardness(0);
			break;
		elseif byte == string.byte("n") then break;
		end
	end
end

