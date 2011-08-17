module(... or "", package.seeall)

require('unix');
require('main');

while 1 do 
  main.update();
  unix.usleep(100);
end

