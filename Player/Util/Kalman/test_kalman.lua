-- Torch/Lua Kalman Filter based Ball tracker test script
-- (c) 2013 Stephen McGill

local torch = require 'torch'
torch.Tensor = torch.DoubleTensor
local libKalman = require 'libKalman'
-- set the seed
math.randomseed(1234)

-- Debugging options
local show_kalman_gain = false
local debug_each_state = false
local test_two = true

-- 3 dimensional kalman filter
local myDim = 10;
local nIter = 5000;
-- Control input
local u_k_input = torch.Tensor( myDim ):zero()
-- Set the observations
local obs1 = torch.Tensor( myDim ):zero()

-- Initialize the filter
local kalman1 = libKalman.new_filter(myDim)
local x,P = kalman1:get_state()

if test_two then
  kalman2 = libKalman.new_filter(myDim)
  obs2 = torch.Tensor(myDim):zero()
end

-- Print the initial state
local initial_str = 'Initial State:\n'
for d=1,x:size(1) do
	initial_str = initial_str..string.format(' %.3f',x[d])
end
print(initial_str)

-- Begin the test loop
for i=1,nIter do

	-- Make an observation
	obs1[1] = i + .2*(math.random()-.5)
	for p=2,obs1:size(1)-1 do
		obs1[p] = i/p + 1/(5*p)*(math.random()-.5)
	end

	-- Perform prediction
	kalman1:predict( u_k_input )
	local x_pred, P_pred = kalman1:get_prior()
	-- Perform correction
	kalman1:correct( obs1 )
	x,P = kalman1:get_state()
	
if test_two then
	for p=1,obs2:size(1) do
		obs2[p] = 1/obs1[p]
	end
	kalman2:predict( u_k_input )
	kalman2:correct( obs2 )
end

	-- Print debugging information
	if debug_each_state then
		
		-- Save prediction string
		local prior_str = 'Prior:\t'
		for d=1,x_pred:size(1) do
			prior_str = prior_str..string.format(' %f',x_pred[d])
		end
		
		-- Save observation string
		local observation_str = 'Observe:\t'
		for d=1,obs1:size(1) do
			observation_str = observation_str..string.format(' %f',obs1[d])
		end
		
		-- Save corrected state string
		local state_str = 'State:\t'
		for d=1,x:size(1) do
			state_str = state_str..string.format(' %f',x[d])
		end
		
		print('Iteration',i)
		print(prior_str)
		print(observation_str)
		print(state_str)
		if show_kalman_gain then
			-- Save the Kalman gain and A strings
			local kgain_str = 'Kalman gain\n'
			local K = kalman1.K_k;
			for i=1,K:size(1) do
				for j=1,K:size(2) do
					kgain_str = kgain_str..string.format('   %f',K[i][j])
				end
				kgain_str = kgain_str..'\n'
			end
			local a_str = 'A:\n'
			local A = kalman1.A;
			for i=1,A:size(1) do
				for j=1,A:size(2) do
					a_str = a_str..string.format('   %.3f',A[i][j])
				end
				a_str = a_str..'\n'
			end
			print(a_str)
			print(kgain_str)
		end
	end
	
end

x,P = kalman1:get_state()
local final_str = 'Final State:\n'
for d=1,x:size(1) do
	final_str = final_str..string.format(' %.3f',x[d])
end
print(final_str)