module(... or "", package.seeall)

require('odometry')

maxFPS = Config.vision.maxFPS;
tperiod = 1.0/maxFPS;

odometry.entry();

while (true) do
  tstart = unix.time();

  odometry.update();

  tloop = unix.time() - tstart;

  if (tloop < tperiod) then
    unix.usleep((tperiod - tloop)*(1E6));
  end
end

odometry.exit();

