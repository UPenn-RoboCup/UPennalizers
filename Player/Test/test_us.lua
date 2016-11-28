cwd = os.getenv('PWD')
require('init')

require('Config')
require('unix')
require('getch')
require('shm')
require('vector')
require('mcm')
require('vcm')
require('wcm')
require('Speak')
require('Body')
require('Motion')
require('gcm')

us = require('UltraSound');

us.entry();
Left = false
Right = false

State_Old= 0
State = 0
-- 0: None, 1: left obstacle, 2: right obstacle, 3: front obstacle
function update()
  us.update();
  -- update shm
  mcm.set_us_left(us.left);
  mcm.set_us_right(us.right);
  Left, Right = us.check_obstacle()
  if Left and (not Right) then
    print('Left')
  elseif Right and (not Left) then
    print('Right')
  elseif Left and Right then
    print('Front')
  else
    print('Clear')
  end

 
 
 --[[
  Left, Right = check_obstacle()  
  --print ("Left: "..Left.."Right: "..Right) 
  if Left and (not Right) then
    State = 1
    if State_Old ~= 1 then
      print('Left')
    end
  elseif Right and (not Left) then
    State = 2
    if State_Old ~= 2 then
      print('Right')
    end
  elseif Left and Right then
    State = 3
    if State_Old ~= 3 then
      print('Front')
    end
  else
    State = 0
    if State_Old ~= 0 then
      print('Clear')
    end
  end
  State_Old = State
  --]]

end


while(1) do
  update()
  unix.usleep(10000);
end

--[[
-- test switch time
t0 = unix.time();
print(t0)
Body.set_actuator_us(0);
while(0 ~= Body.get_sensor_usCommand()[1]) do
  unix.usleep(1000);
end
t1 = unix.time();
print(t1-t0);

unix.usleep(1000000);


t0 = unix.time();
print(t0)
Body.set_actuator_us(3);
while(3 ~= Body.get_sensor_usCommand()[1]) do
  unix.usleep(1000);
end
t1 = unix.time();
print(t1-t0);
--]]

