cwd = os.getenv('PWD')
require('init')

require('unix');
require('coach');
require('Body')

local t_last = Body.get_time()
while 1 do 
  local t=Body.get_time() 
  tPassed = t-t_last
  t_last = t
  if tPassed>0.005 then
    update()
  end 
  tDelay = 0.005*1E6;	
  unix.usleep(tDelay);
end

