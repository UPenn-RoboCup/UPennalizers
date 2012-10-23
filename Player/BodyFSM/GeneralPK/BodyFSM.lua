if Config.game.role==0 then
  print("====Goalie PenaltyKick FSM Loaded====")
  BodyFSM = require('BodyFSMGoalie');
else
  print("====Kicker PenaltyKick FSM Loaded====")
  BodyFSM = require('BodyFSMKicker');
end
