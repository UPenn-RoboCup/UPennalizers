module(..., package.seeall);

require('shm');
require('carray');
require('vector');
require('unix')

---------------------------------
function split(str, pat)
   local t = {}  
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end
---------------------------------

function ptable(t)
  -- print a table key, value pairs
  for k,v in pairs(t) do print(k,v) end
end

function mod_angle(a)
  if a==nil then return nil end
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

function max(t)
  -- find the maximum element in the array table
  -- returns the min value and its index
  local imax = 0;
  local tmax = -math.huge;
  for i = 1,#t do
    if (t[i] > tmax) then
      tmax = t[i];
      imax = i;
    end
  end
  return tmax, imax;
end

function se2_interpolate(t, u1, u2)
  -- helps smooth out the motions using a weighted average
  return vector.new{u1[1]+t*(u2[1]-u1[1]),
                    u1[2]+t*(u2[2]-u1[2]),
                    u1[3]+t*mod_angle(u2[3]-u1[3])};
end

function se3_interpolate(t, u1, u2, u3)
  --Interpolation between 3 xya values
  if t<0.5 then
    tt=t*2;
    return vector.new{u1[1]+tt*(u2[1]-u1[1]),
                    u1[2]+tt*(u2[2]-u1[2]),
                    u1[3]+tt*mod_angle(u2[3]-u1[3])};
  else
    tt=t*2-1;
    return vector.new{u2[1]+tt*(u3[1]-u2[1]),
                    u2[2]+tt*(u3[2]-u2[2]),
                    u2[3]+tt*mod_angle(u3[3]-u2[3])};
  end
end

function shallow_copy(a)
  --copy the table by value
  local ret={}
  for k,v in pairs(a) do ret[k]=v end
  return ret
end


function procFunc(a,deadband,maxvalue)
  --Piecewise linear function for IMU feedback
  if a>0 then
        b=math.min( math.max(0,math.abs(a)-deadband), maxvalue);
  else
        b=-math.min( math.max(0,math.abs(a)-deadband), maxvalue);
  end
  return b;
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

---table of uniform distributed random numbers
--@param n length of table to return
--@return table of n uniformly distributed random numbers
function randu(n)
  local t = {};
  for i = 1,n do
    t[i] = math.random();
  end
  return t;
end

---Table of normal distributed random numbers.
--@param n length of table to return
--@return table of n normally distributed random numbers
function randn(n)
  local t = {}
  local toggle = true
  for i = 1,n do
    --Inefficient implementation:
    -- Box-muller
    if toggle then
      t[i] = math.sqrt(-2.0*math.log(math.random())) *
                      math.cos(2*math.pi*math.random())
      toggle = not toggle
    else
    	t[i] = math.sqrt(-2.0*math.log(math.random())) *
                      math.sin(2*math.pi*math.random())
      toggle = not toggle
    end
  end
  return t
end

---Two INDEPENDENT normal distributed random numbers.
--@return table of n normally distributed random numbers
function randn2()
  local t = {}
  -- Box-muller
    t[1] = math.sqrt(-2.0*math.log(math.random())) *
                    math.cos(2*math.pi*math.random())
  	t[2] = math.sqrt(-2.0*math.log(math.random())) *
                    math.sin(2*math.pi*math.random())
  return t
end


function init_shm_segment(fenv, name, shared, shsize, tid, pid)
  tid = tid or Config.game.teamNumber;
  pid = pid or Config.game.playerID;
  -- initialize shm segments from the *cm format
  for shtable, shval in pairs(shared) do
    -- create shared memory segment
    local shmHandleName = shtable..'Shm';
    -- segment names are constructed as follows:
    -- [file_name][shared_table_name][team_number][player_id][username]
    -- ex. vcmBall01brindza is the segment for shared.ball table in vcm.lua
    -- NOTE: the first letter of the shared_table_name is capitalized
    local shmName = name..string.upper(string.sub(shtable, 1, 1))..string.sub(shtable, 2)..tid..pid..(os.getenv('USER') or '');
    
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
            if (bytes == nil or type(bytes) ~= 'table') then
              return '';
            else
              for i=1,#bytes do
                if not (bytes[i]>0) then --Testing NaN
		              print("NaN Detected at string!");
	               return;
		            end
              end
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


-- For HZD
--[[
% Plot a left knee angle from the above coefficients
s = linspace(0, 1, 50) ;
figure ; plot(s*100, polyval_bz(alpha_L(ind_LKneePitch, :), s)*180/pi) ;
grid on ; xlabel('% gait') ; ylabel('deg') ; title('Left stance Knee') ;
--]]

  -- wikipedia
function factorial(n)
  if n == 0 then
  return 1
  else
return n * factorial(n - 1)
  end
  end

  --[[
  % Function to evaluate bezier polynomials
% Inputs: Alpha - Bezeir coefficients (alpha_0 ... alpha_M)
  %         s - s parameter. Range [0 1]
  % Outputs: b = sum(k=0 to m)[ alpha_k * M!/(k!(M-k)!) s^k (1-s)^(M-k)]
  --]]
function polyval_bz(alpha, s)
  b = 0;
  M = #alpha-1 ;  -- length(alpha) = M+1
  for k =0,M do
  b = b + alpha[k+1] * factorial(M)/(factorial(k)*factorial(M-k)) * s^k * (1-s)^(M-k) ;
  end
  return b;
  end

function bezier( alpha, s )
--  [n, m] = size(alpha);
  n = #alpha;
  m = #alpha[1];
  value=vector.zeros(n);
  M = m-1;
  if M==3 then
  k={1,3,3,1};
  elseif M==4 then
  k={1,4,6,4,1};
  elseif M==5 then
  k={1,5,10,10,5,1};
  elseif M==6 then
  k={1,6,15,20,15,6,1};
  else
  return;
  end

  x = vector.ones(M+1);
  y = vector.ones(M+1);
  for i=1,M do
  x[i+1]=s*x[i];
  y[i+1]=(1-s)*y[i];
  end
  for i=1,n do
  value[i] = 0;
  for j=1,M+1 do
  value[i] = value[i] + alpha[i][j]*k[j]*x[j]*y[M+2-j];
  end
  end

  return value;
  end

function get_wireless_ip()
  ifconfig = io.popen('/sbin/ifconfig wlan0 | grep "inet " | cut -d" " -f10-11');
  ip = ifconfig:read();
  return ip;
end

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

function LoadConfig(params, platform)
  file_header = "Config_"..platform.name;
  for k, v in pairs(params.name) do
    file_name = params[v] or "";
    overload_platform = params[v..'_Platform'] or "";
    if string.len(overload_platform) ~= 0 then 
      file_header = "Config_"..overload_platform;
    else
      file_header = "Config_"..platform.name;
    end
    if string.len(file_name) ~= 0 then file_name = '_'..file_name; end
    file_name = v..'/'..file_header..'_'..v..file_name
    loadconfig(file_name)
  end
end

function printtable(t)
  for k,v in pairs(t) do
    if type(v) == 'table' then
      -- Assume only two layers
      if type(k)=='string' then
        --print(k, printtable(v))
        print(k, unpack(v))
      else
        print(unpack(v))
      end
    else
      if type(k)=='string' then
        print(k, v)
      else
        print(v)
      end
    end
  end
end

--Sorts a simple lua table that has 1 set of entries, i.e. tbl={4, 8, 27, 13, 75, 7}
--It will return a table with two sets of entries, one with the sorted values
--and another with the sorted indeces.
--For example, the table listed above will return as
--            ID, VAL
--newtbl = { {1 ,  4}
--           {6 ,  7}
--           {2 ,  8}
--           {4 ,  13}
--           {3 ,  27}
--           {5 ,  75}}
--
function SortTable(tbl)

    local newtbl = {};   
    for k,v in pairs(tbl) do
        newtbl[#newtbl+1] = {k,v};
        --print(newtbl[#newtbl][1],newtbl[#newtbl][2])
    end

    table.sort(newtbl, function(b,c) return b[2] < c[2] end)
    
    --for testing
    --print("Order, id, value")
    --for k = 1,#newtbl do
    --    print (k,newtbl[k][1],newtbl[k][2])
    --end
    
    return newtbl
end

