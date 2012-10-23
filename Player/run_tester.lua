module(... or "", package.seeall)

require('unix');
require('tester');

while 1 do 
  tDelay = 0.005*1E6;
  tester.update();
  unix.usleep(tDelay);
end

