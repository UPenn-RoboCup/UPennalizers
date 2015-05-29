local carray = require 'carray'
--local ffi = require 'ffi'

dd = carray.double(5)
dd[2] = 4
dd[5] = 342
for i = 1, 5 do

	print(dd[i])
end
carray.cast()

--cdata = ffi.cast('double* ', dd: pointer())
--print(cdata[1])
