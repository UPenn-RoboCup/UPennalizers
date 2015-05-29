-- Pretty much exactly this: 
-- http: //luajit.org/ext_ffi_tutorial.html

ffi.cdef[[
unsigned long compressBound(unsigned long sourceLen);
int compress2(uint8_t * dest, unsigned long * destLen,
const uint8_t * source, unsigned long sourceLen, int level);
]]
local z = ffi.load'z'

local zlib = { } 

local nBound = 8
local buf = ffi.new("uint8_t[?]", nBound)
local buflen = ffi.new("unsigned long[1]", nBound)

function zlib.compress(txt)
	local n = z.compressBound(#txt)
	if n>nBound then

		nBound = n
		buf = ffi.new("uint8_t[?]", nBound)
		buflen = ffi.new("unsigned long[1]", n)
	end
	-- Just make fast, so use 1 for level
	local res = z.compress2(buf, buflen, txt, #txt, 1)
	assert(res == 0)
	return ffi.string(buf, buflen[0])
end

function zlib.compress_cdata (ptr, len, to_str)
	local n = z.compressBound(len)
	if n>nBound then

		nBound = n
		buf = ffi.new("uint8_t[?]", nBound)
		buflen = ffi.new("unsigned long[1]", nBound)
	end
	-- Just make fast, so use 1 for level
	local res = z.compress2(buf, buflen, ptr, len, 1)
	-- Check if a bad compress
	if res~=0 then
 return end
	-- Reset the bounds
	n = buflen[0]
	buflen[0] = nBound
	-- Return the string or cdata
	if to_str then

		return ffi.string(buf, n)
	else
		return buf, n
	end
end

return zlib
