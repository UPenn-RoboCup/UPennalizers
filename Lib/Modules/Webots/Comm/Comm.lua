module(..., package.seeall);

require('controller')
require('GameControlPacket')

timeStep = controller.wb_robot_get_basic_time_step();
channel = 13;

-- webots communication modules
receiverTag = controller.wb_robot_get_device("receiver");
emitterTag = controller.wb_robot_get_device("emitter");

-- enable webots communication
controller.wb_receiver_enable(receiverTag, timeStep);
controller.wb_receiver_set_channel(receiverTag, channel);

controller.wb_emitter_set_channel(emitterTag, channel);

-- variable to store most recent game control data
-- needed because webots sends all information on same 'socket'
gameControlData = nil;

function init()
end

function receive()
  while (controller.wb_receiver_get_queue_length(receiverTag) > 0) do
    -- get first message on the queue
    ndata = controller.wb_receiver_get_data_size(receiverTag);
    data = controller.wb_receiver_get_data(receiverTag);
    --print("Packet received", #data);
    controller.wb_receiver_next_packet(receiverTag);

    gameControlRecv = false;
    if (#data == 68) then
      -- if it is a game control packet store it for later
      local pkt = GameControlPacket.parse(data);
      if (pkt) then
        gameControlRecv = true;
        gameControlData = pkt;
      end
    end

    if not gameControlRecv then
      -- return packet data
      return data;
    end
  end
end

function size()
  -- return current queue size
  return controller.wb_receiver_get_queue_length(receiverTag);
end

function get_game_control_data()
  -- return latest game control data
  return gameControlData;
end

function send(s)
   controller.wb_emitter_send(emitterTag, s);   
end

