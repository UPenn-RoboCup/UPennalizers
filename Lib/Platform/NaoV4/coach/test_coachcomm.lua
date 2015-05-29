require'unix'
local coachcomm = require'CoachComm'
coachcomm.init('192.168.123.255')

local count = 0
local t_usleep = 1e6
local ret
while true do

	local ret = coachcomm.send(0, 'ball out of bounds')
	count = count +  1
	print('Coach', count, ret)
	unix.usleep(t_usleep)
end
