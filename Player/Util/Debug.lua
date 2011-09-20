module(..., package.seeall);

require('shm');
require('carray');
require('cutil');
require('vector');
require('Config');

-- intialize debug shm handle
debugShmHandle = shm.new('luarDebug'..Config.game.teamNumber..Config.game.playerID..(os.getenv('USER') or ''));
if (not util.shm_key_exists(debugShmHandle, 'debuglevel', 1)) then
  debugShmHandle.debuglevel = 1;
end
if (not util.shm_key_exists(debugShmHandle, 'visiondebuglevel', 1)) then
  debugShmHandle.visiondebuglevel = 1;
end
if (not util.shm_key_exists(debugShmHandle, 'visiondebugmode', 1)) then
  debugShmHandle.visiondebugmode = 0;
end
debuglevel = carray.cast(debugShmHandle:pointer('debuglevel'));
visiondebuglevel = carray.cast(debugShmHandle:pointer('visiondebuglevel'));
visiondebugmode = carray.cast(debugShmHandle:pointer('visiondebugmode'));

-- vision debug modes
visionmode = {};
visionmode.none = 0;
visionmode.ball = 1;
visionmode.goal = 2;
visionmode.line = 4;
visionmode.midfieldLandmark = 8;
visionmode.freespace = 16;
visionmode.all = cutil.bit_not(0);

-- store a reference to the standard lua print
-- this must be used everywhere you want to use
-- the regular lua print in this file
luaprint = print;

function print(level, ...)
  -- debug print
  if (level < debuglevel[1]) then
    luaprint(...);
  end
end

function printf(level, ...)
  -- debug formated print
  if (level < debuglevel[1]) then
    luaprint(string.format(...));
  end
end

-- vision print functions
function vprint(level, mode, ...)
  -- debug print
  if (cutil.bit_and(mode, visiondebugmode[1]) ~= 0) then
    if (level < visiondebuglevel[1]) then
      luaprint(...);
    end
  end
end

function vprintf(level, mode, ...)
  -- debug formated print
  if (cutil.bit_and(mode, visiondebugmode[1]) ~= 0) then
    if (level < visiondebuglevel[1]) then
      luaprint(string.format(...));
    end
  end
end


function set_debuglevel(val)
  debuglevel[1] = val;
end

function set_visiondebuglevel(val)
  visiondebuglevel[1] = val;
end

function set_visiondebugmode(mode)
  visiondebugmode[1] = mode;
end

function add_visiondebugmode(mode)
  visiondebugmode[1] = cutil.bit_or(mode, visiondebugmode[1]);
end

function remove_visiondebugmode(mode)
  visiondebugmode[1] = cutil.bit_and(cutil.bit_not(mode), visiondebugmode[1]);
end

