module(..., package.seeall);

require('Body')
require('keyframe')
require('walk')
require('vector')
require('Config')

local cwd = unix.getcwd();
if string.find(cwd, 'WebotsController') then
  cwd = cwd..'/Player';
end
cwd = cwd..'/Motion/keyframes'

keyframe.load_motion_file(cwd..'/'..Config.km.block_right,
                          'blockRight');
keyframe.load_motion_file(cwd..'/'..Config.km.block_left,
                          'blockLeft');

motion = '';

active = false;

function entry()
  print(_NAME..' entry');
  walk.stop();
  started = false;
  active = true;
end

function update()
  if (not started and not walk.active) then
    started = true;
    keyframe.entry();
    keyframe.do_motion(motion);
  end
  if started then
    keyframe.update();
    if (keyframe.get_queue_len() == 0) then
      return 'done'
    end
  else
    walk.update();
  end
end

function exit()
  print(_NAME..' exit');
  keyframe.exit();
  active = false;
end

function set_motion(m)
  motion = m;
end

