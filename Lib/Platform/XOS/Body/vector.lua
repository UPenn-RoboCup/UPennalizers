module(..., package.seeall);

local mt = {};

function new(t)
  t = t or {};
  return setmetatable(t, mt);
end

function ones(n)
  n = n or 1;
  local t = {};
  for i = 1, n do
    t[i] = 1;
  end
  return setmetatable(t, mt);
end

function zeros(n)
  n = n or 1;
  local t = {};
  for i = 1, n do
    t[i] = 0;
  end
  return setmetatable(t, mt);
end

function slice(v1, istart, iend)
  local v = {};
  iend = iend or #v1;
  for i = 1,iend-istart+1 do
    v[i] = v1[istart+i-1];
  end
  return setmetatable(v, mt);
end

function add(v1, v2)
  local v = {};
  for i = 1, #v1 do
    v[i] = v1[i]+v2[i];
  end
  return setmetatable(v, mt);
end

function sub(v1, v2)
  local v = {};
  for i = 1, #v1 do
    v[i] = v1[i]-v2[i];
  end
  return setmetatable(v, mt);
end

function mulnum(v1, a)
  local v = {};
  for i = 1, #v1 do
    v[i] = a*v1[i];
  end
  return setmetatable(v, mt);
end

function divnum(v1, a)
  local v = {};
  for i = 1, #v1 do
    v[i] = v1[i]/a;
  end
  return setmetatable(v, mt);
end

function mul(v1, v2)
  if type(v2) == "number" then
    return mulnum(v1, v2);
  elseif type(v1) == "number" then
    return mulnum(v2, v1);
  else
    local s = 0;
    for i = 1, #v1 do
      s = s+v1[i]*v2[i];
    end
    return s;
  end
end

function unm(v1)
  return mulnum(v1, -1);
end

function div(v1, v2)
  if type(v2) == "number" then
    return divnum(v1, v2);
  else
    return nil;
  end
end

function norm(v1)
  local s = 0;
  for i = 1, #v1 do
    s = s + v1[i]*v1[i];
  end
  return math.sqrt(s);
end

function tostring(v1, formatstr)
  formatstr = formatstr or "%g";
  local str = "{"..string.format(formatstr, v1[1]);
  for i = 2, #v1 do
    str = str..", "..string.format(formatstr,v1[i]);
  end
  str = str.."}";
  return str;
end

mt.__add = add;
mt.__sub = sub;
mt.__mul = mul;
mt.__div = div;
mt.__unm = unm;
mt.__tostring = tostring;

