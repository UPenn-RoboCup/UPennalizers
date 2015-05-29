local unix = require 'unix'

print(unix.time())

tbl = unix.readdir('./')
for k, v in pairs(tbl) do

	print(k, v)
end
