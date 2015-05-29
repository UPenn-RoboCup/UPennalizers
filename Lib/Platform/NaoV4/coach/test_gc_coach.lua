require'unix'
local GameController = require('NaoGameControlReceiver')
local coachcomm = require'CoachComm'
coachcomm.init('192.168.1.255')

local count = 0
-- Rules ays only every 10 seconds a msg
local t_usleep = 1e6
local ret, gc_packet
while true do

	-- Receive GC packets
	gc_packet = GameController.receive()
	-- while gc_packet do
	if gc_packet then

		-- print('\n=========\nGame State', gc_packet.state)
		for i, team in ipairs(gc_packet.teams) do

			--io.write('\nTeam ', team.teamNumber, '\nCoach Message:  (', team.coachMessage, ') ', #team.coachMessage)
			io.write('Coach Message to team '..team.teamNumber..':  (', team.coachMessage, ') \n')
		end
		-- gc_packet = GameController.receive()
	end
	-- Send Coach messages
	count = count +  1
	ret = coachcomm.send(12, 'ball out of bounds'..count)
	print('\n\nCoach Send', count, ret)
	unix.usleep(t_usleep)
end
