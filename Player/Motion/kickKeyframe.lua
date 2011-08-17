module(..., package.seeall);

require('Body')
require('keyframe')
require('walk')
require('vector')
require('Config')

local cwd = unix.getcwd();
if string.find(cwd, "WebotsController") then
  cwd = cwd.."/Player";
end
cwd = cwd.."/Motion/keyframes"

keyframe.load_motion_file(cwd.."/"..Config.km.kick_right,
                          "kickForwardRight");
keyframe.load_motion_file(cwd.."/"..Config.km.kick_left,
                          "kickForwardLeft");

-- default kick type
kickType = "kickForwardLeft";
active = false;

function entry()
  print(_NAME.." entry");
  walk.stop();
  started = false;
  active = true;
end

function update()
  if (not started and not walk.active) then
      started = true;
      keyframe.entry();
      keyframe.do_motion(kickType);
  end
  if started then
      keyframe.update();
      if (keyframe.get_queue_len() == 0) then
	  return "done"
      end
  else
	walk.update();
  end
end

function exit()
  print("Kick exit");
  keyframe.exit();
  active = false;
  walk.active=true;
end

function set_kick(newKick)
  -- set the kick type (left/right)
	kickType = newKick;
end
