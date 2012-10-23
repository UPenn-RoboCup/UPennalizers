module(... or "", package.seeall)

require('unix');
require('test_new_walk');

while 1 do 
  test_new_walk.update();
  unix.usleep(100);
end

