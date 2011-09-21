module(... or "", package.seeall)

require('cognition')

maxFPS = Config.vision.maxFPS;
tperiod = 1.0/maxFPS;

cognition.entry();

while (true) do
  tstart = unix.time();

  congition.update();

  tloop = unix.time() - tstart;
  if (tloop < 0.025) then
    unix.usleep((.025 - tloop)*(1E6));
  end
end

cognition.exit();

