module(... or "", package.seeall)

local cameranum
if (arg[1] == nil) then
  print("WARNING: no camera specific, using default 1")
  cameranum = 1
else cameranum = tonumber(arg[1])
end

require('init')
require('wcm')

if cameranum==1 then --Top camera
  wcm.set_process_v1({0,0,0})
else
  --Bottom camera. Wait until the top camera completes initialization
  print("Waiting for top camera to initialized")
  local v1 = wcm.get_process_v1()
  while v1[3]==0 do
    unix.usleep(0.5*(1E6))
    v1 = wcm.get_process_v1()
  end
end

require('parallel_cognition')

maxFPS = Config.vision.maxFPS;
tperiod = 1.0/maxFPS;
local count = 0

parallel_cognition.entry(cameranum);

while (true) do
  tstart = unix.time();
  parallel_cognition.update(cameranum);
  tloop = unix.time() - tstart;
  if tonumber(arg[1])==1 then
    local v = wcm.get_process_v1()
    wcm.set_process_v1({v[1],v[2]+tloop,count})
  else
    local v = wcm.get_process_v2()
    wcm.set_process_v2({v[1],v[2]+tloop,count})
  end
  count = count + 1
  if (tloop < tperiod) then
    unix.usleep((tperiod - tloop)*(1E6));
  end
end

parallel_cognition.exit(arg[1]);

