module(... or "", package.seeall)

require('cognition')

maxFPS = Config.vision.maxFPS;
tperiod = 1.0/maxFPS;

cognition.entry();

while (true) do
  tstart = unix.time();

  cognition.update();

  tloop = unix.time() - tstart;

  if (tloop < tperiod) then
    unix.usleep((tperiod - tloop)*(1E6));
  end
end

cognition.exit();

