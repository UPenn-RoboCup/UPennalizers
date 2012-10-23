module(..., package.seeall);

require('cutil')

function serialize_orig(o)
  local str = "";
  if type(o) == "number" then
    str = tostring(o);
  elseif type(o) == "string" then
    str = string.format("%q",o);
  elseif type(o) == "table" then
    str = "{";
    for k,v in pairs(o) do
      str = str..string.format("[%s]=%s,",serialize_orig(k),serialize_orig(v));
    end
    str = str.."}";
  else	
    str = "nil";
  end
  return str;
end

--New serialization code omiting integer indexes for tables
--Only do recursive call if v is a table
-- Pack size 2.3X smaller, Serilization time 3.4X faster on OP
function serialize(o)
  local str = "";
  if type(o) == "number" then
    if o%1==0 then --quickest check for integer
      str=tostring(o);
    else
      str = string.format("%.2f",o);--2-digit precision
    end
  elseif type(o) == "string" then
    str = string.format("%q",o);
  elseif type(o) == "table" then
    str = "{";
    local is_num=true;
    for k,v in pairs(o) do
      if type(k)=="string" then 
        if type(v) == "number" then
	  if v%1==0 then --quickest check for integer
            str = str..string.format("[%q]=%d,",k,v);
    	  else
	    str = str..string.format("[%q]=%.2f,",k,v);
	  end
	elseif type(v)=="string" then
          str = str..string.format("[%q]=%q,",k,v);
	elseif type(v)=="table" then
          str = str..string.format("[%q]=%s,",k,serialize(v));
	end
      else
        if type(v) == "number" then
	  if v%1==0 then --quickest check for integer
            str = str..string.format("%d,",v);
    	  else
	    str = str..string.format("%.2f,",v);
	  end
	elseif type(v)=="string" then
          str = str..string.format("%q,",v);
	elseif type(v)=="table" then
          str = str..string.format("%s,",serialize(v));
	end
      end

    end
    str = str.."}";
  else	
    str = "nil";
  end
  return str;
end

function serialize_array(ud, width, height, dtype, arrName, arrID)
  -- function to serialize an userdata array
  -- returns an array of lua arr tables
  -- Max size of a UDP packet
  local maxSize = 2^16 - 2^12;

  local dsize = cutil.sizeof(dtype);
  local arrSize = width*height*dsize;

  -- determine break size account for byte->ascii
  local rowSize = 2*width*dsize;
  local nrows = math.floor(maxSize/rowSize);
  local npackets = math.ceil(height/nrows);

  local ret = {};
  local cptr = ud;
  local rowsRemaining = height;
  for p = 1,npackets do
    local crows = math.min(nrows, rowsRemaining);
    rowsRemaining = rowsRemaining - crows;
    local name = string.format('%s.%d.%d.%d', arrName, arrID, p, npackets); 
    ret[p] = cutil.array2string(cptr, width, crows, dtype, name);
    cptr = cutil.ptr_add(cptr, width*crows, dtype);
  end

  return ret;
end

--For sending yuyv image
--We don't care even rows in yuyv
--So just skip every other line and save 1/2 bandwidth

function serialize_array2(ud, width, height, dtype, arrName, arrID)
  -- function to serialize an userdata array
  -- returns an array of lua arr tables
  -- Max size of a UDP packet
  local maxSize = 2^16 - 2^12;

  local dsize = cutil.sizeof(dtype);
  local arrSize = width*height*dsize/2; --skip every other line

  -- determine break size account for byte->ascii
  local rowSize = 2*width*dsize;
  local nrows = math.floor(maxSize/rowSize)*2; --skip every other line
  local npackets = math.ceil(height/nrows); 

  local ret = {};
  local cptr = ud;
  local rowsRemaining = height;
  for p = 1,npackets do
    local crows = math.min(nrows, rowsRemaining);
    rowsRemaining = rowsRemaining - crows;
    local name = string.format('%s.%d.%d.%d', arrName, arrID, p, npackets); 
    ret[p] = cutil.array2string2(cptr, width, crows, dtype, name);
	--skip every other line
    cptr = cutil.ptr_add(cptr, width*crows, dtype);
  end
  return ret;
end

--Label-only serialization code
--Exploiting label data range (0-31) to pack each label to a single byte
function serialize_label(ud, width, height, dtype, arrName, arrID)
  local dsize = cutil.sizeof(dtype);
  local arrSize = width*height*dsize;
  local ret = {};
  local cptr = ud;
  local name = string.format('%s.%d.1.1', arrName, arrID); 
  ret = cutil.label2string(cptr, width*height, dtype, name);
  return ret;
end

--Double-packing
function serialize_label_double(ud, width, height, dtype, arrName, arrID)
  local dsize = cutil.sizeof(dtype);
  local arrSize = width*height*dsize;
  local ret = {};
  local cptr = ud;
  local name = string.format('%s.%d.1.1', arrName, arrID); 
  ret = cutil.label2string_double(cptr, width*height, dtype, name);
  return ret;
end

--Run-length enclding
function serialize_label_rle(ud, width, height, dtype, arrName, arrID)
  local dsize = cutil.sizeof(dtype);
  local arrSize = width*height*dsize;
  local ret = {};
  local cptr = ud;
  local name = string.format('%s.%d.1.1', arrName, arrID); 
  ret = cutil.label2string_rle(cptr, width*height, dtype, name);
  return ret;
end

function deserialize(s)
  --local x = assert(loadstring("return "..s))();
  if not s then
    return '';
  end
  -- protected loadstring call
  ok, ret = pcall(loadstring('return '..s));
  --local x = loadstring("return "..s)();
  if not ok then 
    --print(string.format("Warning: Could not deserialize message:\n%s",s));
    return '';
  else
    return ret;
  end
end
