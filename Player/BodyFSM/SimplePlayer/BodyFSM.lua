require('gcm')

--if Config.game.role==0 then
if gcm.get_team_role()==0 then
  print("====Goalie FSM Loaded====")
  BodyFSM = require('BodyFSMGoalie');
elseif Config.fsm.playMode==1 then
  -- Demo FSM (No orbit)
  print("====Demo FSM Loaded====")
  BodyFSM = require('BodyFSMDemo');
else
  -- Simple FSM (Approach and orbit)
  print("====Simple FSM Loaded====")
  BodyFSM = require('BodyFSMPlayer');
end

