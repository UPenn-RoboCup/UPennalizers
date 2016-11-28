--Prints dynamically changing joint positions in real time
module(... or "", package.seeall)

require('init')
require('Body')

function update()
  i = 1
  for i = 1,22,1 do
    local str = string.format("Motor %.2d:\t %.15s\t :\t %5.3f",
      i, Body.jointNames[i], Body.get_sensor_position()[i])
    print(str)
  end
end
