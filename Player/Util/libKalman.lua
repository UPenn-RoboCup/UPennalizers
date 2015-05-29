-- Torch/Lua Kalman Filter
-- (c) 2013 Stephen McGill

local torch = require 'torch'
torch.Tensor = torch.DoubleTensor

-- Begin the library code
local libKalman = {}

-- Accessor Methods
local function get_prior(self)
	return self.x_k_minus, self.P_k_minus
end
local function get_state(self)
	return self.x_k, self.P_k
end

-- Form a state estimate prior based on the process and input
local function predict(self, u_k)
	-- Complicated (i.e. fast in-memory) way
	
	self.tmp_state:mv( self.A, self.x_k_minus ) -- Evolve the state
	self.x_k_minus:copy( self.tmp_state )
	if u_k then
		self.tmp_input:mv( self.B, u_k )
		self.x_k_minus:add( self.tmp_input )		
	end
	self.tmp_covar:mm( self.A, self.P_k_minus )
	self.P_k_minus:mm( self.tmp_covar, self.A:t() ):add( self.Q )
	--]]
	
	--[[
	-- Simple (i.e. mallocing memory each time) way
	self.x_k_minus = self.A * self.x_k_minus + self.B * (u_k or 0)
	self.P_k_minus = self.A * self.P_k_minus * self.A:t() + self.Q
	--]]
end

-- Correct the state estimate based on a measurement
local function correct( self, z_k )
	-- Complicated (i.e. fast in-memory) way

	self.tmp_pcor1:mm( self.H, self.P_k_minus )
	self.tmp_pcor2:mm( self.tmp_pcor1, self.H:t() ):add(self.R)
	torch.inverse( self.tmp_pcor3, self.tmp_pcor2 )
	self.tmp_pcor4:mm(self.P_k_minus, self.H:t() )	
	self.K_k:mm( self.tmp_pcor4, self.tmp_pcor3 )
	self.K_update:mm( self.K_k, self.H ):mul(-1):add(self.I)
	self.P_k:mm( self.K_update, self.P_k_minus )
	self.tmp_scor:mv( self.H, self.x_k_minus ):mul(-1):add(z_k)
	self.x_k:mv( self.K_k, self.tmp_scor ):add(self.x_k_minus)
	--]]
	
	--[[
	-- Simple (i.e. malloc'ing memory each time) way
	local tmp1 = self.H * self.P_k_minus * self.H:t()
	local tmp = tmp1 + self.R
	self.K_k = self.P_k_minus * self.H:t() * torch.inverse(tmp)
	self.P_k = (self.I - self.K_k * self.H) * self.P_k_minus
	self.x_k = self.x_k_minus + self.K_k * (z_k - self.H * self.x_k_minus)
	--]]

	-- Duplicate Values
	self.x_k_minus:copy(self.x_k)
	self.P_k_minus:copy(self.P_k)
end

-- Filter initialization code
libKalman.initialize_filter = function( filter, nDim )
	-- Utility
	filter.I = torch.eye(nDim)
	-- Process
	filter.A = torch.eye(nDim) -- State process w/o input
	filter.B = torch.eye(nDim) -- Control input to state effect
	filter.Q = torch.eye(nDim) -- Additive uncertainty
	-- Measurement
	filter.R = torch.eye(nDim) -- Measurement uncertainty
	filter.H = torch.eye(nDim) 
	-- Prior
	filter.P_k_minus = torch.eye(nDim)
	filter.x_k_minus = torch.Tensor(nDim):zero()
	-- State
	filter.P_k = torch.Tensor( nDim, nDim ):copy( filter.P_k_minus )
	filter.x_k = torch.Tensor(nDim):copy( filter.x_k_minus )
	
	----------
	-- Methods
	----------
	filter.predict = predict
	filter.correct = correct
	filter.get_prior = get_prior
	filter.get_state = get_state
	
	return filter
end

-- Temporary Variables for complicated fast memory approach
libKalman.initialize_temporary_variables = function( filter )
	filter.tmp_input = torch.Tensor( filter.B:size(1) )
	filter.tmp_state = torch.Tensor( filter.A:size(1) )
	filter.tmp_covar = torch.Tensor( filter.A:size(1), filter.P_k_minus:size(2) )
	filter.tmp_pcor1 = torch.Tensor( filter.H:size(1), filter.P_k_minus:size(2) )
	filter.tmp_pcor2 = torch.Tensor( filter.tmp_pcor1:size(1), filter.H:size(1) )
	filter.tmp_pcor3 = torch.Tensor( filter.tmp_pcor1:size(1), filter.H:size(1) )
	filter.tmp_pcor4 = torch.Tensor( filter.P_k_minus:size(1), filter.H:size(1) )
	filter.K_k = torch.Tensor( filter.P_k_minus:size(1), filter.H:size(1) )
	filter.K_update = torch.Tensor( filter.K_k:size(1), filter.H:size(2) )
	filter.tmp_scor  = torch.Tensor( filter.H:size(1) )
	return filter
end

-- Generic filter
libKalman.new_filter = function( nDim )
	local f = {}
	-- Default initialization
	f = libKalman.initialize_filter( f, nDim )
	f = libKalman.initialize_temporary_variables( f )
	return f
end

return libKalman