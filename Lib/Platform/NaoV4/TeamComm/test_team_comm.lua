require('unix')

local teamcomm = require'TeamComm'
local send_interval, recv_interval, count = 1e6, 2e6, 0

local ip = 'localhost'

local ip = '192.168.123.255'
local port = 10220

local init_ret = teamcomm.init(ip, port)
print('Init ret: ', init_ret)
dummystr = 
'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
datastr = ''

dataarray={ } 
for i=1,20 do

	dataarray[i]=i%5
end
dataarray[1]=12

datastr = datastr..'asdfghjkl;.'
local to_send = { 
header = "SPL ",
version = 5,
playerNum = 1,
teamColor = 22, 
fallen = 0,
pose = { 1,2,3} ,
walkingTo = { 0.2,3} ,
shootingTo = { 2,5} ,
ball = { 1,-1} ,
ballVel = { 0,0} ,
ballAge = -1,
suggestion = {0,1,2,3,4},
intention = 1,
averageWalkSpeed = 50,
maxKickDistance = 200,
currentPositionConfidence = 75,
currentSideConfidence = 40,

numOfDataBytes = #dataarray,
data = dataarray,
} 

function printtable(t)
	for k,v in pairs(t) do

		if type(v) == 'table' then

			-- Assume only two layers
			if type(k)=='string' then

				--print(k, printtable(v))
				print(k, unpack(v))
			else
				print(unpack(v))
			end
		else
			if type(k)=='string' then

				print(k, v)
			else
				print(v)
			end
		end
	end
end

local send_ret, msg
while true do

	send_ret = teamcomm.send(to_send)
	to_send.ballAge = to_send.ballAge+ 1
	msg = teamcomm.receive()
	if msg then
 
		--print(msg.teamColor, unpack(msg.pose), unpack(msg.walkingTo))
		printtable(msg)
	end
	unix.usleep(1E6) 
end

