local xbox360 = require 'xbox360'
xbox360.open()
for i=1,100 do

	local buttons = xbox360.button()
	local axes = xbox360.axis()
	print('Buttons: ', unpack(buttons) )
	print('Axes: ', unpack(axes) )
end
