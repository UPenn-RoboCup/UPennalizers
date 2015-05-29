local torch=require'libtorch'
torch.Tensor = torch.DoubleTensor

--[[
Copyright (c) 2011-2014 Idiap Research Institute (Ronan Collobert)
Copyright (c) 2011-2012 NEC Laboratories America (Koray Kavukcuoglu)
Copyright (c) 2011-2013 NYU (Clement Farabet)
Copyright (c) 2006-2010 NEC Laboratories America (Ronan Collobert, Leon Bottou, Iain Melvin, Jason Weston)
Copyright (c) 2006      Idiap Research Institute (Samy Bengio)
Copyright (c) 2001-2004 Idiap Research Institute (Ronan Collobert, Samy Bengio, Johnny Mariethoz)

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

3. Neither the names of NEC Laboratories American and IDIAP Research
Institute nor the names of its contributors may be used to endorse or
promote products derived from this software without specific prior
written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
--]]

-- Add FFI interface
if jit then

	local ffi = require 'ffi'

	local Real2real = {
		Byte='unsigned char',
		Char='char',
		Short='short',
		Int='int',
		Long='long',
		Float='float',
		Double='double'
	}

	-- Allocator
	ffi.cdef[[
	typedef struct THAllocator {
		void* (*malloc)(void*, long);
		void* (*realloc)(void*, void*, long);
		void (*free)(void*, void*);
	} THAllocator;
	]]

	-- Storage
	for Real, real in pairs(Real2real) do

		local cdefs = [[
		typedef struct THRealStorage
		{
			real *data;
			long size;
			int refcount;
			char flag;
			THAllocator *allocator;
			void *allocatorContext;
		} THRealStorage;
		]]
		cdefs = cdefs:gsub('Real', Real):gsub('real', real)
		ffi.cdef(cdefs)

		local Storage = torch.getmetatable(string.format('torch.%sStorage', Real))
		local Storage_tt = ffi.typeof('TH' .. Real .. 'Storage**')

		rawset(Storage,
		"cdata",
		function(self)
			return Storage_tt(self)[0]
		end)

		rawset(Storage,
		"data",
		function(self)
			return Storage_tt(self)[0].data
		end)
	end

	-- Tensor
	for Real, real in pairs(Real2real) do

		local cdefs = [[
		typedef struct THRealTensor
		{
			long *size;
			long *stride;
			int nDimension;

			THRealStorage *storage;
			long storageOffset;
			int refcount;

			char flag;

		} THRealTensor;
		]]
		cdefs = cdefs:gsub('Real', Real):gsub('real', real)
		ffi.cdef(cdefs)

		local Tensor = torch.getmetatable(string.format('torch.%sTensor', Real))
		local Tensor_tt = ffi.typeof('TH' .. Real .. 'Tensor**')

		rawset(Tensor,
		"cdata",
		function(self)
			return Tensor_tt(self)[0]
		end)

		rawset(Tensor,
		"data",
		function(self)
			self = Tensor_tt(self)[0]
			return self.storage.data + self.storageOffset
		end)

		-- faster apply (contiguous case)
		local apply = Tensor.apply
		rawset(Tensor,
		"apply",
		function(self, func)
			if self:isContiguous() and self.data then
				local self_d = self:data()
				for i=0,self:nElement()-1 do
					local res = func(tonumber(self_d[i])) -- tonumber() required for long...
					if res then
						self_d[i] = res
					end
				end
				return self
			else
				return apply(self, func)
			end
		end)

		-- faster map (contiguous case)
		local map = Tensor.map
		rawset(Tensor,
		"map",
		function(self, src, func)
			if self:isContiguous() and src:isContiguous() and self.data and src.data then
				local self_d = self:data()
				local src_d = src:data()
				assert(src:nElement() == self:nElement(), 'size mismatch')
				for i=0,self:nElement()-1 do
					local res = func(tonumber(self_d[i]), tonumber(src_d[i])) -- tonumber() required for long...
					if res then
						self_d[i] = res
					end
				end
				return self
			else
				return map(self, src, func)
			end
		end)

		-- faster map2 (contiguous case)
		local map2 = Tensor.map2
		rawset(Tensor,
		"map2",
		function(self, src1, src2, func)
			if self:isContiguous() and src1:isContiguous() and src2:isContiguous() and self.data and src1.data and src2.data then
				local self_d = self:data()
				local src1_d = src1:data()
				local src2_d = src2:data()
				assert(src1:nElement() == self:nElement(), 'size mismatch')
				assert(src2:nElement() == self:nElement(), 'size mismatch')
				for i=0,self:nElement()-1 do
					local res = func(tonumber(self_d[i]), tonumber(src1_d[i]), tonumber(src2_d[i])) -- tonumber() required for long...
					if res then
						self_d[i] = res
					end
				end
				return self
			else
				return map2(self, src1, src2, func)
			end
		end)
	end

	-- torch.data
	-- will fail is :data() is not defined
	function torch.data(self, asnumber)
		local data = self:data()
		if asnumber then
			return ffi.cast('intptr_t', data)
		else
			return data
		end
	end

	-- torch.cdata
	-- will fail is :cdata() is not defined
	function torch.cdata(self, asnumber)
		local cdata = self:cdata()
		if asnumber then
			return ffi.cast('intptr_t', cdata)
		else
			return cdata
		end
	end

end

return torch
