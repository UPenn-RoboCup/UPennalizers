module(..., package.seeall);

require('controller')
require('GameControlPacket')

timeStep = controller.wb_robot_get_basic_time_step();
channel = 13;

receiverTag = controller.wb_robot_get_device("receiver");
emitterTag = controller.wb_robot_get_device("emitter");

playerID = os.getenv('PLAYER_ID') + 0;
teamID = os.getenv('TEAM_ID') + 0;

gameControlData = nil;
gameControlState = nil;
gameControlTeamColor = 1;

recv_mesg_handler = nil;

function entry()
  controller.wb_receiver_enable(receiverTag, timeStep);
  controller.wb_receiver_set_channel(receiverTag, channel);

  controller.wb_emitter_set_channel(emitterTag, channel);
end

function update()
  while (controller.wb_receiver_get_queue_length(receiverTag) > 0) do
    ndata = controller.wb_receiver_get_data_size(receiverTag);
    data = controller.wb_receiver_get_data(receiverTag);
    --print("Packet received", #data);

    local gameControlRecv = false;
    if (#data == 68) then
      --Check if Game Control Data:
      local pkt = GameControlPacket.parse(data);
      if (pkt) then
        gameControlRecv = true;
        gameControlData = pkt;
        gameControlState = gameControlData.state;
        for i = 1,2 do
          if (gameControlData.teams[i].teamNumber == teamID) then
            gameControlTeamColor = gameControlData.teams[i].teamColour;
          end
        end
      end
    end

    if ((not gameControlRecv) and (recv_mesg_handler)) then
      --print("Packet received", #data);
      recv_mesg_handler(data);
    end

    controller.wb_receiver_next_packet(receiverTag);
  end
end

function exit()
end

function set_recv_mesg_handler(f)
  recv_mesg_handler = f;
end

function get_game_control_data()
   return gameControlData;
end

function get_game_control_state()
   return gameControlState;
end

function get_game_control_team_color()
   return gameControlTeamColor;
end

function send_emitter(s)
   controller.wb_emitter_send(emitterTag, s);   
end

function serialize(o)
  local str = "";
  if type(o) == "number" then
    str = tostring(o);
  elseif type(o) == "string" then
    str = string.format("%q",o);
  elseif type(o) == "table" then
    str = "{";
    for k,v in pairs(o) do
      str = str..string.format("[%s]=%s,",serialize(k),serialize(v));
    end
    str = str.."}";
  else
    str = "nil";
  end
  return str;
end

function deserialize(s)
  --local x = assert(loadstring("return "..s))();
  local x = loadstring("return "..s)();
  if (not x) then
    print(string.format("Could not deserialize: %s",s));
  end
  return x;
end
