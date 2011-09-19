module(..., package.seeall);

require('shm');
require('carray');
require('vector');


function ptable(t)
  -- print a table key, value pairs
  for k,v in pairs(t) do print(k,v) end
end

function mod_angle(a)
  -- Reduce angle to [-pi, pi)
  a = a % (2*math.pi);
  if (a >= math.pi) then
    a = a - 2*math.pi;
  end
  return a;
end

function sign(x)
  -- return sign of the number (-1, 0, 1)
  if (x > 0) then return 1;
  elseif (x < 0) then return -1;
  else return 0;
  end
end

function min(t)
  -- find the minimum element in the array table
  -- returns the min value and its index
  local imin = 0;
  local tmin = math.huge;
  for i = 1,#t do
    if (t[i] < tmin) then
      tmin = t[i];
      imin = i;
    end
  end
  return tmin, imin;
end

function se2_interpolate(t, u1, u2)
  -- helps smooth out the motions using a weighted average
  return vector.new{u1[1]+t*(u2[1]-u1[1]),
                    u1[2]+t*(u2[2]-u1[2]),
                    u1[3]+t*mod_angle(u2[3]-u1[3])};
end

function pose_global(pRelative, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  return vector.new{pose[1] + ca*pRelative[1] - sa*pRelative[2],
                    pose[2] + sa*pRelative[1] + ca*pRelative[2],
                    pose[3] + pRelative[3]};
end

function pose_relative(pGlobal, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  local px = pGlobal[1]-pose[1];
  local py = pGlobal[2]-pose[2];
  local pa = pGlobal[3]-pose[3];
  return vector.new{ca*px + sa*py, -sa*px + ca*py, mod_angle(pa)};
end

function randu(n)
  --table of uniform distributed random numbers
  local t = {};
  for i = 1,n do
    t[i] = math.random();
  end
  return t;
end

function randn(n)
  -- table of normal distributed random numbers
  local t = {};
  for i = 1,n do
    --Inefficient implementation:
    t[i] = math.sqrt(-2.0*math.log(1.0-math.random())) *
                      math.cos(math.pi*math.random());
  end
  return t;
end


function init_shm_segment(fenv, name, shared, shsize)
  -- initialize shm segments from the *cm format
  for shtable, shval in pairs(shared) do
    -- create shared memory segment
    local shmHandleName = shtable..'Shm';
    local shmName = name..string.upper(string.sub(shtable, 1, 1))..string.sub(shtable, 2);
    
    fenv[shmHandleName] = shm.new(shmName, shsize[shtable]);
    local shmHandle = fenv[shmHandleName];

    -- intialize shared memory
    init_shm_keys(shmHandle, shared[shtable]);

    -- generate accessors and pointers
    local shmPointerName = shtable..'Ptr';
    fenv[shmPointerName] = {};
    local shmPointer = fenv[shmPointerName];
    
    for k,v in pairs(shared[shtable]) do
      shmPointer[k] = carray.cast(shmHandle:pointer(k));
      if (type(v) == 'string') then
        -- setup accessors for a string
        fenv['get_'..shtable..'_'..k] =
          function()
            local bytes = shmHandle:get(k);
            if (bytes == nil) then
              return '';
            else
              return string.char(unpack(bytes));
            end
          end
        fenv['set_'..shtable..'_'..k] =
          function(val)
            return shmHandle:set(k, {string.byte(val, 1, string.len(val))});
          end
      elseif (type(v) == 'number') then
        -- setup accessors for a userdata
        fenv['get_'..shtable..'_'..k] =
          function()
            return shmHandle:pointer(k);
          end
        fenv['set_'..shtable..'_'..k] =
          function(val)
            return shmHandle:set(k, val, v);
          end
      elseif (type(v) == 'table') then
        -- setup accessors for a number/vector 
        fenv['get_'..shtable..'_'..k] =
          function()
            val = shmHandle:get(k);
            if type(val) == 'table' then
              val = vector.new(val);
            end
            return val;
          end
        fenv['set_'..shtable..'_'..k] =
          function(val, ...)
            return shmHandle:set(k, val, ...);
          end
      else
        -- unsupported type
        error('Unsupported shm type '..type(v));
      end
    end
  end
end

function init_shm_keys(shmHandle, shmTable)
  -- initialize a shared memory block (creating the entries if needed)
  for k,v in pairs(shmTable) do 
    -- create the key if needed
    if (type(v) == 'string') then
      if (not shm_key_exists(shmHandle, k)) then
        shmHandle:set(k, {string.byte(v, 1, string.len(v))});
      end
    elseif (type(v) == 'number') then 
      if (not shm_key_exists(shmHandle, k) or shmHandle:size(k) ~= v) then
        shmHandle:empty(k, v);
      end
    elseif (type(v) == 'table') then
      if (not shm_key_exists(shmHandle, k, #v)) then
        shmHandle[k] = v;
      end
    end
  end
end

function shm_key_exists(shmHandle, k, nvals)
  -- checks the shm segment for the given key
  -- returns true if the key exists and is of the correct length nvals (if provided)

  for sk,sv in shmHandle.next, shmHandle do
    cpsv = carray.cast(shmHandle:pointer(sk));
    if (k == sk) then
      -- key exists, check length
      if (nvals and nvals ~= #cpsv) then
        return false;
      else
        return true;
      end
    end
  end

  -- key does not exist
  return false; 
end

