-- libDetect
-- (c) 2014 Stephen McGill
-- General Detection methods

local ImageProcFuncs = require 'ImageProcFuncs'
local ImageProc = { } 
local torch = require'torch'
local bit = require'bit'
local lshift = bit.lshift
local rshift = bit.rshift
local band = bit.band
local bor = bit.bor

-- Widths and Heights of Image, LabelA, LabelB
local w, h, wa, ha, wb, hb
-- Form the labelA and labelB tensors
local labelA_t, labelB_t = torch.ByteTensor(), torch.ByteTensor()
-- Color Count always the same, as 8 bits for 8 colors means 256 color combos
local cc_t = torch.IntTensor(256)
-- The pointer will not change for this one
local cc_d = cc_t: data()
-- The Current Lookup table (Can be swapped dynamically)
local luts = { } 
-- Downscaling
local scaleA, scaleB, log_sA, log_sB
local log2 = { 
[1] = 0,
[2] = 1,
[4] = 2,
[8] = 3,
} 

-- Load LookUp Table for Color -> Label
function ImageProc.load_lut (filename)
	local f_lut = torch.DiskFile( filename , 'r')
	f_lut.binary(f_lut)
	-- We know the size of the LUT, so load the storage
	local lut_s = f_lut: readByte(262144)
	f_lut: close()
	-- Form a tensor for us
	lut_t = torch.ByteTensor(lut_s)
	table.insert(luts,lut_t)
	-- Return the id of this LUT
	return #luts
end
-- Return the pointer to the LUT
function ImageProc.get_lut (lut_id)
	local lut_t = luts[lut_id]
	if not lut_t then
 return end
	return lut_t
end

-- Take in a pointer (or string) to the image
-- Take in the lookup table, too
-- Return labelA and the color count
-- Assumes a subscale of 2 (i.e. drop every other column and row)
-- Should be dropin for previous method
function ImageProc.yuyv_to_label (yuyv_ptr, lut_ptr)
	-- The yuyv pointer changes each time
	-- Cast the lightuserdata to cdata
	local yuyv_d = ffi.cast("uint32_t* ", yuyv_ptr)
	-- Set the LUT Raw data
	local lut_d = ffi.cast("uint8_t* ", lut_ptr)
	-- Temporary variables for the loop
	-- NOTE:  4 bytes yields 2 pixels, so stride of (4/2)* w
	local a_ptr, stride, yuyv = labelA_t: data(), w / 2
	for j=0,ha-1 do

		for i=0,wa-1 do

			yuyv = yuyv_d[0]
			-- Set the label 
			a_ptr[0] = lut_d[bor(
			rshift(band(yuyv, 0xFC000000), 26),
			rshift(band(yuyv, 0x0000FC00), 4),
			lshift(band(yuyv, 0xFC), 10)
			)]
			-- Move the labelA pointer
			a_ptr = a_ptr +  1
			-- Move the image pointer
			yuyv_d = yuyv_d +  1
		end
		-- stride to next line
		yuyv_d = yuyv_d +  stride
	end
	--
	return labelA_t
end

function ImageProc.color_count (label_t)
	-- Reset the color count
	cc_t: zero()
	-- Loop variables
	local l_ptr, color = label_t: data()
	for i=0,np_a-1 do

		color = l_ptr[0]
		cc_d[color] = cc_d[color] +  1
		l_ptr = l_ptr +  1
	end
	return cc_t
end

-- Bit OR on blocks of NxN to get to labelB from labelA
local function block_bitorN (label_t)
	-- Zero the downsampled image
	labelB_t: zero()
	local a_ptr, b_ptr = label_t: data(), labelB_t: data()

	local jy, iy, ind_b, off_j
	for jx=0,ha-1 do

		jy = rshift(jx, log_sB)
		off_j = jy *  wb
		for ix=0,wa-1 do

			iy = rshift(ix, log_sB)
			ind_b = iy +  off_j
			b_ptr[ind_b] = bor(b_ptr[ind_b], a_ptr[0])
			a_ptr = a_ptr +  1
		end
	end

	return labelB_t
end

-- Bit OR on blocks of 2x2 to get to labelB from labelA
local function block_bitor2 (label_t)
	-- Zero the downsampled image
	labelB_t: zero()
	local a_ptr, b_ptr = label_t: data(), labelB_t: data()

	-- Offset a row
	local a_ptr1 = a_ptr +  wa
	-- Start the loop
	for jb=0,hb-1 do

		for ib=0,wb-1 do

			b_ptr[0] = bor(a_ptr[0],a_ptr[1],a_ptr1[0],a_ptr1[1])
			-- Move to the next pixel
			a_ptr = a_ptr +  2
			a_ptr1 = a_ptr1 +  2
			-- Move b
			b_ptr = b_ptr +  1
		end
		-- Move another row, too
		a_ptr = a_ptr +  wa
		a_ptr1 = a_ptr1 +  wa
	end

	return labelB_t
end

-- Get the color stats for a bounding box
-- TODO:  Add tilted color stats if needed
function ImageProc.color_stats ()

	-- Initialize statistics
	local area = 0
	local minI, maxI = width-1, 0
	local minJ, maxJ = height-1, 0
	local sumI, sumJ = 0, 0
	local sumII, sumJJ, sumIJ = 0, 0, 0

	for j=0,ha-1 do

		for i=0,wa-1 do

		end
	end
end

-- Setup should be able to quickly switch between cameras
-- i.e. not much overhead here.
-- Resize should be expensive at most n_cameras times (if all increase the sz)
function ImageProc.setup (w0, h0, sA, sB)
	-- Save the scale paramter
	scaleA = sA or 2
	scaleB = sB or 2
	log_sA, log_sB = log2[scaleA], log2[scaleB]
	-- Recompute the width and height of the images
	w, h = w0, h0
	wa, ha = w / scaleA, h / scaleA
	wb, hb = wa / scaleB, ha / scaleB
	-- Save the number of pixels
	np_a, np_b = wa *  ha, wb *  hb
	-- Resize as needed
	labelA_t: resize(ha, wa)
	labelB_t: resize(hb, wb)
	-- Select faster bit_or
	if scaleB==2 then
		ImageProc.block_bitor = block_bitor2
	else
		ImageProc.block_bitor = block_bitorN
	end
  ImageProc.old_block_bitor = ImageProcFuncs.block_bitor
  ImageProc.old_yuyv_to_label = ImageProcFuncs.yuyv_to_label
  ImageProc.label_to_mask = ImageProcFuncs.label_to_mask
  ImageProc.yuyv_mask_to_lut = ImageProcFuncs.yuyv_mask_to_lut
  ImageProc.color_stats = ImageProcFuncs.color_stats
  ImageProc.tilted_color_stats = ImageProcFuncs.tilted_color_stats
  ImageProc.connected_regions = ImageProcFuncs.connected_regions
  ImageProc.goal_posts = ImageProcFuncs.goal_posts
  ImageProc.goal_posts_white = ImageProcFuncs.goal_posts_white
  ImageProc.tilted_goal_posts = ImageProcFuncs.tilted_goal_posts
  ImageProc.field_occupancy = ImageProcFuncs.field_occupancy
  ImageProc.field_lines = ImageProcFuncs.field_lines
  ImageProc.line_connect = ImageProcFuncs.line_connect
  ImageProc.field_spots = ImageProcFuncs.field_spots
  ImageProc.robots = ImageProcFuncs.robots
end

return ImageProc
