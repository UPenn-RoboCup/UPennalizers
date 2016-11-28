--File to reset orientation of robot when it is in penalty
--Simply run this file and it will set the the appropriate shared memory values
dofile('init.lua');
require('wcm')

print('Calling reset orienation function')
wcm.set_robot_resetOrientation(1);
