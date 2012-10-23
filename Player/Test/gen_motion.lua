module(... or "", package.seeall)

require('os')

webots = false;

local cwd = '../.' 
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
package.path = cwd.."/Motion/keyframes/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/BodyFSM/?.lua;"..package.path;
package.path = cwd.."/HeadFSM/?.lua;"..package.path;

require('unix')
require('Config');
require('Body')
require('vector')
require('getch')
require('util')

getch.enableblock(1);

local str = getch.get();
-- initialize 
jp = Body.get_sensor_position();
Body.set_actuator_command(jp);
rlhardness = 1;
llhardness = 1;
rahardness = 1;
lahardness = 1;
hardness = 1;
Body.set_body_hardness(hardness);


jointNames = {'HeadYaw',
              'HeadPitch',
              'LShoulderPitch',
              'LShoulderRoll',
              'LElbowYaw',
              'LElbowRoll',
              'LHipYawPitch',
              'LHipRoll',
              'LHipPitch',
              'LKneePitch',
              'LAnklePitch',
              'LAnkleRoll',
              'RHipYawPitch',
              'RHipRoll',
              'RHipPitch',
              'RKneePitch',
              'RAnklePitch',
              'RAnkleRoll',
              'RShoulderPitch',
              'RShoulderRoll',
              'RElbowYaw',
              'RElbowRoll'};
jointCommands = { 'z',
                  'x',
                  'q',
                  'w',
                  'e',
                  'r',
                  't',
                  'a',
                  's',
                  'd',
                  'f',
                  'g',
                  'y',
                  'u',
                  'i',
                  'o',
                  'p',
                  'j',
                  'k',
                  'l',
                  'n',
                  'm'};

resolution = 0.02;
dresolution = 0.002;
mode = 0;

frames = {};

function inc_res()
  print(string.format('increasing resolution from %0.4f to %0.4f rad', resolution, resolution+dresolution));
  resolution = resolution + dresolution;
end

function dec_res()
  print(string.format('decreasing resolution from %0.4f to %0.4f rad', resolution, resolution-dresolution));
  resolution = resolution - dresolution;
end

function toggle_hardness()
  hardness = 1 - hardness;
  local s = '';
  if hardness == 0 then
    s = 'off';
  else
    s = 'on';
  end
  
  local j = Body.get_sensor_position();
  Body.set_actuator_command(j);
  
  print('Toggling hardness '..s);
  Body.set_body_hardness(hardness);
end

function toggle_rleg()
  rlhardness = 1-rlhardness;
  local s = '';
  if rlhardness == 0 then
    s = 'off';
  else
    s = 'on';
  end

  local j = Body.get_sensor_position();
  Body.set_actuator_command(j);
  
  print('Toggling right leg hardness '..s);
  Body.set_rleg_hardness(rlhardness);
end

function toggle_lleg()
  llhardness = 1-llhardness;
  local s = '';
  if llhardness == 0 then
    s = 'off';
  else
    s = 'on';
  end

  local j = Body.get_sensor_position();
  Body.set_actuator_command(j);
  
  print('Toggling left leg hardness '..s);
  Body.set_lleg_hardness(llhardness);
end

function toggle_rarm()
  rahardness = 1-rahardness;
  local s = '';
  if rahardness == 0 then
    s = 'off';
  else
    s = 'on';
  end

  local j = Body.get_sensor_position();
  Body.set_actuator_command(j);
  
  print('Toggling right arm hardness '..s);
  Body.set_rarm_hardness(rahardness);
end


function toggle_larm()
  lahardness = 1-lahardness;
  local s = '';
  if lahardness == 0 then
    s = 'off';
  else
    s = 'on';
  end

  local j = Body.get_sensor_position();
  Body.set_actuator_command(j);
  
  print('Toggling left arm hardness '..s);
  Body.set_larm_hardness(lahardness);
end

  

function print_help()
  print('command\tjoint');
  for i = 1,#jointNames do
    print(jointCommands[i]..'\t'..jointNames[i]);
  end
  print('<SHIFT>+command to move the other way');

  print('\ncommand\tfunction');
  print('+\tincrease move resolution');
  print('-\tdecrease move resolution');
  print('SPACE\ttoggle hardness');
  print('1\ttoggle right leg  hardness');
  print('2\ttoggle left leg  hardness');
  print('3\ttoggle right arm  hardness');
  print('4\ttoggle left arm  hardness');
  print('h\thelp');
  print('Enter\tsave current joint angles');
  print('\\\tremove last frame');
  print('ESC\tgenerate keyframe and exit');
end

function save_frame()
  print('Appending frame...');

  local str = ""
  local input = ""
  print("Enter duration: ")
  while(true) do
    input = getch.get()
    if(input == '\n') then
      break;
    end
    str = str..input
  end
  frames[#frames+1] = {};
  frames[#frames]["Duration"] = str
  local j = Body.get_sensor_position();
  for k,v in pairs(j) do
    frames[#frames][k] = v;
  end
end

function remove_last_frame()
  -- pop last frame  
  if #frames > 0 then
    frames[#frames] = nil;
    print('Last frame removed.');
  else
    print('No frames to remove.');
  end
end

function format_keyframe()
  filename = 'generated_keyframe.lua'

  local f = assert(io.open(filename,'w'))

  f:write('local mot={};\n');

  f:write('mot.servos={');
  for i=1,#jointNames do
    f:write(i,',');
  end
  f:write('};\n');

  f:write('mot.keyframes={');
  for i=1,#frames do
    f:write("  {\n    angles={\n");
    for j=1,#jointNames do
      f:write(frames[i][j],",");
    end
    f:write("\n    },\n");
    f:write("duration = "..frames[i]["Duration"].."; \n  },\n");
  end
  f:write("};\n\nreturn mot;")
  f:close();
  print("Saved as "..filename)
end


function exit()
  format_keyframe();
  os.exit();
end

utilFunctions = {inc_res,
                 dec_res,
                 toggle_hardness,
		toggle_rleg,
		toggle_lleg,
		toggle_rarm,
		toggle_larm, 
                print_help,
                 save_frame,
                 remove_last_frame,
                 exit};

utilCommands = {'+',
                '-',
                ' ',
		'1',
		'2',
		'3',
		'4',
                'h',
                string.char(0x0A),  -- Return
                --string.char(0x08),  -- Backspace
                '\\',
                string.char(0x1B)}; -- ESC



print('Press h for Help menu');
function update()
  local str = getch.get();

  if #str > 0 then
    local byte = string.byte(str,1);
    local index = 0;
    local dir = 1;
    print('');

    for i = 1,#jointCommands do
      if byte == string.byte(jointCommands[i]) then
        index = i;
        break;
      elseif byte == string.byte(string.upper(jointCommands[i])) then
        index = i;
        dir = -1;
        break;
      end
    end

		if index > 0 then
      -- joint command received
      local j = Body.get_sensor_position();
			j[index] = j[index] + dir*resolution;
			print(string.format('%s : %0.4f rad', jointNames[index], j[index]))

      Body.set_actuator_command(j);
    else
      -- check util commands
      for i = 1,#utilCommands do
        if byte == string.byte(utilCommands[i]) then
          -- util command received
          utilFunctions[i](); 
        end
      end
    end
  end
end


-- loop
while(true) do
  update()
  unix.usleep(100);
end

