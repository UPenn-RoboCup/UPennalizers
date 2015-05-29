-- Torch/Lua Ball tracking using a Kalman Filter
-- (c) 2013 Stephen McGill
local libKalman = require'libKalman'
local torch = require 'torch'
torch.Tensor = torch.DoubleTensor
local cov_debug = false
local prior_debug = false

local libBallTrack = {}
local tmp_rotatation = torch.Tensor(2,2)
local DEFAULT_VAR = 100*100
local EPS = .1/(DEFAULT_VAR*DEFAULT_VAR);



-- TODO: Tune these values...
local MIN_ERROR_DISTANCE = 5 -- 5cm
local ERROR_DEPTH_FACTOR = 0.1;
local ERROR_ANGLE_FACTOR = 1*math.pi/180
local DECAY = 1


-- Previous values
--local MIN_ERROR_DISTANCE = 5 -- 5cm
--local ERROR_DEPTH_FACTOR = .2
--local ERROR_ANGLE_FACTOR = 3*math.pi/180
--local DECAY = 1

local function check_uncertainty(cxx,cyy,cxy)
	if ((cxx <= 0) or
	(cxx > DEFAULT_VAR) or
	(cyy <= 0) or
	(cyy > DEFAULT_VAR)) then
		cxx = DEFAULT_VAR;
		cyy = DEFAULT_VAR;
		cxy = 0;
	end
	
	local cDet = cxx*cyy-cxy*cxy;
	if (cDet < EPS) then
		local t = (1-cDet)/(cxx+cyy)
		cxx = cxx + t
		cyy = cyy + t
		cDet = cxx*cyy-cxy*cxy
	end
--	print('Det',cDet)
	return cxx,cyy,cxy
end

local function set_uncertainty( unc, s1, s2, alpha )
	s1 = s1*s1;
	s2 = s2*s2;

	local cosa = math.cos(alpha);
	local sina = math.sin(alpha);
	local cxx = s1*cosa*cosa+s2*sina*sina;
	local cyy = s1*sina*sina+s2*cosa*cosa;
	local cxy = (s1-s2)*cosa*sina;
	
	cxx,cyy,cxy = check_uncertainty(cxx,cyy,cxy)
	
	unc[1][1] = cxx;
	unc[2][2] = cyy;
	unc[1][2] = cxy;
	unc[2][1] = cxy;
	return unc
  
end

-- Position filter
-- Yields velocity as well
-- http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=5298809
local function customize_filter( filter, nDim )

	-----------------
	-- Modify the Dynamics update
	-----------------
	filter.A:zero()
	-- Position stays the same
	filter.A:sub(1,nDim,  1,nDim):eye(nDim)
	-- TODO: blocks of the matrix may be mixed up...
	-- Predict next position by velocity
	filter.A:sub(1,nDim, nDim+1,2*nDim):eye(nDim)
	--filter.A:sub(nDim+1,2*nDim, 1,nDim):eye(nDim):mul(filter.dt)
	-- Velocity Decay
	filter.A:sub(nDim+1,2*nDim, nDim+1,2*nDim):eye(nDim):mul(DECAY)

	-----------------
	-- Modify the Measurement update
	-----------------
	-- We only measure the state positions, not velocities
	filter.R = torch.eye( nDim )
	filter.H = torch.Tensor( nDim, 2*nDim ):zero()
	filter.H:sub(1,nDim,1,nDim):eye(nDim)

	return filter

end

local function reset( filter )
	filter.needs_reset = true
end

-- Update the Ball Tracker based on an observation
-- If no positions are given, it is assumed that 
-- we missed an observation during that camera frame
-- Arguments
-- positions: torch.Tensor(2) or {x,y}
local function update( filter, positions )
	
	-- Reset if needed
	if filter.needs_reset and positions then
		local x = positions[1] * 100
		local y = positions[2] * 100
		filter.x_k_minus[1] = x
		filter.x_k_minus[2] = y
		filter.x_k_minus[3] = 0
		filter.x_k_minus[4] = 0
		filter.x_k:copy( filter.x_k_minus )
		filter.P_k_minus:eye(4)
		-- Gotta really trust the position upon a reset!
		filter.P_k_minus:sub(1,2,1,2):eye(4):mul(10)
		-- Very uncertain in vel upon reset
		filter.P_k_minus:sub(3,4,3,4):eye(4):mul(1e6)
		filter.P_k:copy(filter.P_k_minus)
		state, uncertainty = filter:get_state()
		filter.needs_reset = false
		return {state[1]/100,state[2]/100}, {state[3]/100,state[4]/100}, uncertainty
	end
	
	-- Update process confidence based on ball velocity
	--filter.Q
	-- Perform prediction with this process covariance
	filter:predict()
	
	local state, uncertainty = filter:get_prior()
	if prior_debug then
		print('Prior',state[1]/100,state[2]/100,state[3]/100,state[4]/100)
	end
	-- Next, correct prediction, if positions available
	if positions then
		-- Update measurement confidence
		-- Convert to centimeters
		local x = positions[1] * 100
		local y = positions[2] * 100
		
		local r = math.sqrt( x^2 + y^2 )
		local theta = math.atan2(-y,x)
		local rho_unc = ERROR_DEPTH_FACTOR*(r+MIN_ERROR_DISTANCE)
		local azi_unc = ERROR_ANGLE_FACTOR*(r+MIN_ERROR_DISTANCE)
		filter.R = set_uncertainty( filter.R, rho_unc, azi_unc, theta )
		-- This Tensor instantiation is to support tables or tensors
		-- Tables will be used in regular lua files
		-- We wish to support non-torch programs
		filter:correct( torch.Tensor({x,y}) )
		state, uncertainty = filter:get_state()
		
		if cov_debug then
			print('x,y',x,y)
			print('theta',theta*180/math.pi)
			print('unc', rho_unc, azi_unc)
			print()
		end
		
	end
	
	-- Return position, velocity, uncertainty
	if cov_debug then
		print('Rj',filter.R[1][1],filter.R[2][2])
		print('Rn',filter.R[1][2],filter.R[2][1])
		print()
		print('uj',uncertainty[1][1],uncertainty[2][2])
		print('un',uncertainty[1][2],uncertainty[2][1])
		print()
	end
	return {state[1]/100,state[2]/100}, {state[3]/100,state[4]/100}, uncertainty
	--return {state[1],state[2]}, {state[3],state[4]}, uncertainty
end

-- FOR NOW - ONLY USE 2 DIMENSIONS
-- 4 states: x y vx vy
libBallTrack.new_tracker = function()
	local f = {}
	-- Generic filter to start with 2 states per dimension
	f = libKalman.initialize_filter( f, 4 )
	f = customize_filter( f, 2 )
	f.update = update
	f.reset = reset
	f:reset()
	f = libKalman.initialize_temporary_variables( f )
	return f
end

-- Arbitrary # of dimensions for generic position tracker
libBallTrack.new_position_filter = function(nDim)
	local f = {}
	-- Generic filter to start with 2 states per dimension
	f = libKalman.initialize_filter( f, 2*nDim )
	f = customize_filter( f, nDim )
	f = libKalman.initialize_temporary_variables( f )
	return f
end

return libBallTrack
