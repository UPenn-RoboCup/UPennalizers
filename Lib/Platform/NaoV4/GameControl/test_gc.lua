--require'init'
local GameController = require('GameControlReceiver')
local pktNum = 0
local ip = '192.168.1.255'
while true do
  GameController.send(5,1,1,ip)
	packet = GameController.receive()
  if packet and packet.packetNumber>pktNum then

		pktNum = packet.packetNumber
		for k,v in pairs(packet) do
 print(k,v) end
	end
	-- os.execute('sleep 1')
end
