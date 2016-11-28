module(..., package.seeall);

require('Config');
require('Body');
require('Comm');
require('Speak');
require('vector');
require('util')
require('serialization');
require('wcm');
require('vcm');
require('gcm');
require('utilMsgDropin')

--Player ID: 1 to 5
--Role enum we used before
ROLE_GOALIE = 0
ROLE_ATTACKER = 1
ROLE_DEFENDER = 2
ROLE_SUPPORTER = 3
ROLE_DEFENDER2 = 4
ROLE_LOST = 5
ROLE_COACH = 6

--New Teamplay code 
--That uses new SPL standardized team message
--Now coach is not even allowed to use the same comm! 
   

local state = utilMsgDropin.get_default_state()

--------------------------------------------------------------
Comm.init(Config.dev.ip_wireless,Config.dev.ip_wireless_port);
print('Receiving Team Message From',Config.dev.ip_wireless);
playerID = gcm.get_team_player_id();
msgTimeout = Config.team.msgTimeout;
nonAttackerPenalty = Config.team.nonAttackerPenalty;
nonDefenderPenalty = Config.team.nonDefenderPenalty;
fallDownPenalty = Config.team.fallDownPenalty;
ballLostPenalty = Config.team.ballLostPenalty;
walkSpeed = Config.team.walkSpeed or 0.25;
turnSpeed = Config.team.turnSpeed;

goalie_ball={0,0,0};
role = gcm.get_team_role();

cidx = 1

states = {};
states[playerID] = state;
ballProb = vector.zeros(5);

--We maintain pose of all robots 
--For obstacle avoidance
poses={};
player_roles=vector.zeros(10);
t_poses=vector.zeros(10);
tLastMessage = 0;
tLastSent = Body.get_time()
send_fps = Config.send_fps or 5

function recv_msgs_new_comm()
  local msg
  if Config.dev.comm == 'WebotsComm' then
    local rcv = Comm.receive();
    if rcv and #rcv==14 then
      --THIS IS BALL POSITION MESSAGE
      ball_gpsx=(tonumber(string.sub(rcv,2,6))-5)*2;
      ball_gpsy=(tonumber(string.sub(rcv,8,12))-5)*2;
      wcm.set_robot_gps_ball({ball_gpsx,ball_gpsy,0});
--      print("Ball gps pos:",ball_gpsx,ball_gpsy)
    end
    msg = serialization.deserialize(rcv);
  else
    msg = Comm.receive()
  end
  while msg do
    t = utilMsgDropin.convert_state_std_to_penn(msg) 
    if t and (t.teamNumber) and (t.id) then
      tLastMessage = Body.get_time();
      if t.id ~= playerID then        
        poses[t.id]=t.pose;
        player_roles[t.id]=t.role;
        t_poses[t.id]=Body.get_time(); 
        t.tReceive = Body.get_time();
        t.labelB = {}; --Kill labelB information
        states[t.id] = t;
      end
    end
    msg=Comm.receive()
  end
end


function entry()
  if Config.dev.comm=='TeamComm' or Config.dev.comm=='WebotsComm'then 
  else
    print("!!! ERROR: SHOULD USE TEAMCOMM !!!")
    return
  end

end
---------------------------------------
--[[prevMessage = '';
currentMessage = '';
messageTime = 0;
function readCoachMessage() 
    --print('gcm.coachMessage '..gcm.get_game_coachMessage());
    currentMessage = gcm.get_game_coachMessage();
    if (currentMessage ~= prevMessage) then
        msg = util.split(currentMessage, " ");
        messageTime = Body.get_time();
        gcm.set_game_coachMessageTime(messageTime);
        prevMessage = currentMessage;
    else 
        msg = nil;
    end
    if (msg ~= nil) then 
        if (#msg > 1 and msg[1] ~= no) then 
            coach_fix_flip(msg);
        end
    end
        elseif (msg[2] == 'ball') then
        elseif (msg[3] == 'ball') then
        elseif (msg[1] == 'in') then
end]]--
---------------------------------------
--[[function coach_fix_flip(msg)
    local pose = wcm.get_pose();
    local ball = wcm.get_ball();
    local ball_global = util.pose_global({ball.x,ball.y,0},{pose.x,pose.y,pose.a});
    local t = Body.get_time();
    local messageTime = gcm.get_game_coachMessageTime();
    
    if (t - messageTime < flip_threshold_t and t - ball.t < flip_threshold_t) then
        if (msg[2] == 'ball' and #msg > 7) then  --ball is to the left, ball global x should be negative
            if (ball_global[1] > 1.5 and Config.vision.coach.home_left) then  --if ball_global is positive, then robot is flipped
                print('====================coach is flipping other robots========================');
                wcm.set_robot_flipped(1);
                Speak.talk('coach is flipping the other robots');
	    elseif (ball_global[1] < - 1.5 and not Config.vision.coach.home_left) then
		wcm.set_robot_flipped(1);
	    end 
        elseif (msg[3] == 'ball' and #msg > 8) then  --ball is to the right, ball global x should be positive
            if (ball_global[1] < -1.5 and Config.vision.coach.home_left) then  --if ball_global is negative, then robot is flipped
                print('====================coach is flipping other robots========================');
                wcm.set_robot_flipped(1);
                Speak.talk('coach is flipping the other robots');
	    elseif (ball_global[1] > 1.5 and not Config.vision.coach.home_left)then
		wcm.set_robot_flipped(1);
	    end
        end
    end 
end]]--
---------------------------------------


function build_state()

  state.time = Body.get_time();
  state.teamNumber = gcm.get_team_number();
  state.teamColor = gcm.get_team_color();
  state.pose = wcm.get_pose();
  state.ball = wcm.get_ball();
  state.ball.t_seen = Body.get_time() - state.ball.t  --added
  state.role = role;
  state.attackBearing = wcm.get_attack_bearing();
  state.battery_level = wcm.get_robot_battery_level();
  --put emergency stop penalty in 
  if wcm.get_robot_is_fall_down() == 1 then
    state.fall=1;
  else
    state.fall=0;
  end
  if gcm.in_penalty() then  state.penalty = 1 else  state.penalty = 0 end
  state.gc_latency=gcm.get_game_gc_latency();
  state.tm_latency=Body.get_time()-tLastMessage;
  --state.body_state = gcm.get_fsm_body_state();
  --the previous line crashed once. This is a temporary hack - Dickens
  state.body_state = ' '
  state.walkingTo = gcm.get_game_walkingto()
  state.shootingTo = gcm.get_game_shootingto()

  gcm.set_team_body_state(state.body_state) --hack

  utilMsgDropin.pack_vision_info(state)
  randind = 1 
  if math.random()>0.5 then
    randind = 2
  end

  state.currentPositionConfidence = wcm.get_robot_confidence();

  --use a random number to pack labelB to avoid always having top when receiving packages
  utilMsgDropin.pack_labelB_TeamMsg(state, randind)

  return state;

end



function update()
    if Config.game.playerID==6 then return end --Coach does not send anything

    --Update state struct
    state = build_state();

    --Send state
    t = Body.get_time()
    if t-tLastSent > 1/send_fps then
        tLastSent = t
        if Config.dev.comm == 'WebotsComm' then
            msg=serialization.serialize(state)
            Comm.send(msg,#msg)
        else
            msg = utilMsgDropin.convert_state_penn_to_std(state)
            Comm.send(msg)      
        end
        state.tReceive = Body.get_time();
        states[playerID] = state;
    end

    -- receive new messages every frame
    recv_msgs_new_comm();

    -- eta and defend distance calculation:
    eta = {};
    ddefend = {};
    roles = {};
    t = Body.get_time();

    --Get team ball
    teamball_loc,teamball_score = calc_team_ball();

    --figure out how many players are alive
    goalie_alive = 0;
    num_players = 0;
    alive_ids = {};
    for id = 1,5 do         
        --make sure we have comms from player and he isn't in penalty  
        if states[id] and states[id].penalty == 0 then
            
            --dont count the goalie in player numbers
            if states[id].role == ROLE_GOALIE then
                goalie_alive = 1;
            else
                num_players = num_players + 1;
                alive_ids[num_players] = id; 
            end           
        end
    end

    --calculate eta to ball and distance to goal (ddefend) for each player
    for id = 1,5 do 
	    -- no info from player, ignore him
	    if not states[id] then  
            eta[id] = math.huge;
            ddefend[id] = math.huge;
            roles[id]=ROLE_LOST

        --player is alive so we can do calculations for him
	    else
            --grab roles 
            roles[id]=states[id].role;

            --ETA calculation considering turning, ball uncertainty
            --walkSpeed: seconds needed to walk 1m
            --turnSpeed: seconds needed to turn 360 degrees
            rBall = math.sqrt((teamball_loc[1]-states[id].pose.x)^2 + (teamball_loc[2]-states[id].pose.y)^2);
            eta[id] = rBall/walkSpeed + --Walking time
                math.abs(states[id].attackBearing)/(2*math.pi)*turnSpeed+ --Turning 
                ballLostPenalty * teamball_score;  --Ball uncertainty

            --Find distance to our goal
            dgoalPosition = vector.new(wcm.get_goal_defend());
            ddefend[id] = math.sqrt((states[id].pose.x - dgoalPosition[1])^2 + 
                (states[id].pose.y - dgoalPosition[2])^2);

            --Add penalties for various roles to prevent rapid switching
            if (states[id].role ~= ROLE_ATTACKER ) then 
                eta[id] = eta[id] + nonAttackerPenalty/walkSpeed 
            end
            if (states[id].role ~= ROLE_DEFENDER and states[id].role~=ROLE_DEFENDER2) then 
                ddefend[id] = ddefend[id] + 0.3;
            end
            if (states[id].fall==1) then 
                eta[id] = eta[id] + fallDownPenalty 
            end

            --Store this for later
            if id==playerID then wcm.set_team_my_eta(eta[id]) end

            --Ignore goalie, reserver, penalized player, confused player
            if (states[id].penalty > 0) or 
              (t - states[id].tReceive > msgTimeout) or
              (states[id].role ==ROLE_LOST) or 
              (states[id].role ==ROLE_GOALIE) then
                
                eta[id] = math.huge;
                ddefend[id] = math.huge;
            
            end --endif
            
	    end --endif
    end --endfor

    --For behavior testing
    force_defender = Config.team.force_defender or 0;
    force_attacker = Config.team.force_attacker or 0;
    if force_defender == 1 then
        set_role(ROLE_DEFENDER);
    end
    if force_attacker == 1 then
        set_role(ROLE_ATTACKER);
    end
    
    --Now that we know how many players are alive and have eta and ddefend, we can decide how to allocate roles
    -- 
    --  goalie_alive | num_players |                  roles
    --        1            0         GOALIE - we have a problem if this happens....
    --        1            1         GOALIE,ATTACKER
    --        1            2         GOALIE,ATTACKER,DEFENDER
    --        1            3         GOALIE,ATTACKER,DEFENDER,SUPPORTER
    --        1            4         GOALIE,ATTACKER,DEFENDER,SUPPORTER,DEFENDER2
    --        0            1         ATTACKER
    --        0            2         ATTACKER,DEFENDER         
    --        0            3         ATTACKER,DEFENDER,DEFENDER2
    --        0            4         ATTACKER,DEFENDER,DEFENDER2,SUPPORTER


    --dynamic role switch only if we are playing, not forcing role, and not goalie, lost, or penalized
    if gcm.get_game_state()==3 and force_defender == 0 and force_attacker == 0 and
      role~=ROLE_GOALIE and states[playerID].penalty == 0 then
        
        ETApos = {};
        newETA = util.SortTable(eta);
        for i=1,#newETA do
            id = newETA[i][1];
            pos = i;
            ETApos[id] = pos;
        end
         
        DDefpos = {};
        newDDef = util.SortTable(ddefend);
        for i=1,#newDDef do
            id = newDDef[i][1];
            pos = i;
            DDefpos[id] = pos;
        end
        
        --print("ETApos", ETApos[playerID])
        --print("DDefpos",DDefpos[playerID])
        
        --useful info to know
        myETApos = ETApos[playerID];
        myDDefpos = DDefpos[playerID];
        attackerID = newETA[1][1];
        attackerDDefpos = DDefpos[attackerID];        
        
        --if we are the closest or the only one, then we become attacker
        if myETApos == 1 or num_players == 1 then 
            set_role(ROLE_ATTACKER);
            --print("I'm Attacking!")
            
        --if there are only 2 players or we are closest to goal, we are automatically defender
        --if attacker is also closest to goal and we are second closest, then we are defender
        elseif myDDefpos == 1 or num_players == 2 or (myDDefpos == 2 and attackerDDefpos == 1) then
            set_role(ROLE_DEFENDER);
            --print("I'm defending");
            
        --to get here means there are more than 2 players and we are not closest to ball or goal
        --this means we must be either defender2 or supporter
        --If there are exactly 3 players, we can choose based off of goalie status
        elseif num_players == 3 then
            
            --if goalie is alive we can have supporter
            --print("Goalie Alive?",goalie_alive)
            if goalie_alive then
                set_role(ROLE_SUPPORTER);
                --print("I'm supporting");
            --if goalie is dead then we should have an extra defender
            else
                set_role(ROLE_DEFENDER2);
                --print("I'm defending 2");
            end            
        
        --To get here all four players are alive and we are not attacker or defender
        --so we are either defender2 or supporter
        elseif num_players == 4 then
            
            --We know we will not be pos 1 for EATA or DDefend
            --If we are close to the ball or far from the goal, we can be support
            --For everything else we will just be 2nd defender
            if myETApos == 2 or myDDefpos == num_players then
                set_role(ROLE_SUPPORTER);
                --print("I'm supporting");
            else
                set_role(ROLE_DEFENDER2);
                --print("I'm defending 2");
            end
            
        else --we should never get here, but just in case
            set_role(ROLE_LOST);
            --print("I'm confus... :(");
        end  
              
        --Switch roles between left and right defender
        if role==ROLE_DEFENDER or role == ROLE_DEFENDER2 then 
            for id = 1,5 do
            
                --Are there any other defenders?
                if id ~= playerID and 	  
                  (roles[id]==ROLE_DEFENDER or roles[id]==ROLE_DEFENDER2) then 
                           
                    --Check if he is on my right side (Def on right, Def2 on left)
                    goalDefend =  wcm.get_goal_defend();
                    if state.pose.y * goalDefend[1] < states[id].pose.y * goalDefend[1] then
                        set_role(ROLE_DEFENDER);
                    else
                        set_role(ROLDE_DEFENDER2);
                    end
                    
                end --endif
            end --endfor
        end --endif defender switch
    
    --We assign role based on player ID during initial and ready state
    elseif gcm.get_game_state()<=2 and force_defender == 0 and force_attacker == 0 and
      role~=ROLE_GOALIE and states[playerID].penalty == 0 then
    
        for i=1,#alive_ids do
            if alive_ids[i] == playerID then RolePos = i end
        end    
        
        --this ensures even if a player or two is missing, we will always fill in roles in this order
        if RolePos == 1 then 
            set_role(ROLE_ATTACKER);
        elseif RolePos == 2 then
            set_role(ROLE_DEFENDER);
        elseif RolePos == 3 then
            set_role(ROLE_SUPPORTER);
        else
            set_role(ROLE_DEFENDER2);
        end     
        
    end --endif playing state vs ready state
        
    update_shm(); 
    update_teamdata(goalie_alive,teamball_score,teamball_loc);
    update_obstacle();
    
    --Don't need to use these anymore
    --check_confused();
    --fix_flip();

end --end update function


function update_teamdata(goalie_alive,ball_score,ball_loc)
    attacker_eta = math.huge;
    defender_eta = math.huge;
    defender2_eta = math.huge;
    supporter_eta = math.huge;
    goalie_alive = 0; 

    attacker_pose = {0,0,0};
    defender_pose = {0,0,0};
    defender2_pose = {0,0,0};
    supporter_pose = {0,0,0};
    goalie_pose = {0,0,0};

    --Update teammates pose information
    for id = 1,5 do
        
        if states[id] and states[id].tReceive and
          (t - states[id].tReceive < msgTimeout) then

            if states[id].role==ROLE_GOALIE then
                goalie_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
                --goalie_ball = util.pose_global({states[id].ball.x,states[id].ball.y,0},	  goalie_pose);
                --goalie_ball[3] = states[id].ball.t_seen
            elseif states[id].role==ROLE_ATTACKER then
                attacker_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
                attacker_eta = eta[id];
            elseif states[id].role==ROLE_DEFENDER then
                defender_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
                defender_eta = eta[id];
            elseif states[id].role==ROLE_SUPPORTER then
                supporter_eta = eta[id];
                supporter_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
            else
                defender2_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
                defender2_eta = eta[id];
            end
        end
    end

    wcm.set_robot_team_ball(ball_loc);
    wcm.set_robot_team_ball_score(ball_score);

    wcm.set_team_attacker_eta(attacker_eta);
    wcm.set_team_defender_eta(defender_eta);
    wcm.set_team_supporter_eta(supporter_eta);
    wcm.set_team_defender2_eta(defender2_eta);
    
    wcm.set_team_goalie_alive(goalie_alive);

    wcm.set_team_attacker_pose(attacker_pose);
    wcm.set_team_defender_pose(defender_pose);
    wcm.set_team_goalie_pose(goalie_pose);
    wcm.set_team_supporter_pose(supporter_pose);
    wcm.set_team_defender2_pose(defender2_pose);

end


--calculate the team ball
--@return averaged ball location {x,y,a}, averaged score
--  score is 0 if nobody has seen it
--  score is 0-1 if one player has seen it
--  score is n+avg_score if n players have seen it
function calc_team_ball()
    
    local scoreBall = vector.zeros(5);
    local numBalls = 0;
    local ballID = {};
    local ball_global = vector.zeros(5);
    
    --loop through all team members
    for id = 1,5 do       
                
        --check to see if we have a message from this player that isn't too old
        if states[id] and states[id].tReceive and (t - states[id].tReceive < msgTimeout) then
            
            --grab current player state we are considering
            cur_state = states[id]
            
            --find their position and ball location
            posexya = vector.new({cur_state.pose.x, cur_state.pose.y, cur_state.pose.a});
            ball_global[id] = util.pose_global({cur_state.ball.x,cur_state.ball.y,0},posexya);
   
            --find distance and time to ball
            rBall2 = cur_state.ball.x^2 + cur_state.ball.y^2;
            tBall = cur_state.ball.t_seen
            
            --Create our own ball.p metric to evaluate other team members
            ball_gamma = 0.3;
            if id == playerID then
                ball = wcm.get_ball();
                ballProb[id] = ball.p;
            else
                print('TBALL: ',tBall)
                if tBall < 0.3 then
                    ballProb[id] = (1-ball_gamma)*ballProb[id]+ball_gamma;
                else
                    ballProb[id] = (1-ball_gamma)*ballProb[id];
                end
            end
            
            --give their ball a confidence rating based on:
            --  ball probability, ball distance, time seen
            scoreBall[id] = ballProb[id] * math.exp(-rBall2/12.0) * math.max(0,1.0-tBall);
            
            print('Player ID: ', id)
            print('ballProb: ',ballProb[id])
            print('ballScore: ',scoreBall[id])
            
            
            --count how many potential sightings we have and who saw them
            if scoreBall[id] > 0 then 
                numBalls = numBalls + 1; 
                ballID[numBalls] = id;
            end
        end
    end
    
    --Now that we have all scores, we need to decide what to do with them
    --If nobody has seen the ball then there isn't much we can do
    if numBalls == 0 then
        ball_loc = {0,0,0};
        ball_score = 0;
    
    --If only one person has seen the ball then just trust them
    elseif numBalls == 1 then
        id = ballID[1];
        ball_loc = ball_global[id];
        ball_score = scoreBall[id];
        
    --Multiple people have seen the ball so we need to figure out if they are the same ball or not    
    else
        dist_thresh = 0.2;
        sees_teamball = vector.zeros(5);
        
        --check if any of the balls seen are actually the same
        --NOTE: This assumes that any two balls that are close to each other are automatically the team ball. This does not account for two pairs of robots seeing different balls, since this would be very rare (I think..)
        for i=1,numBalls-1 do
            for j = i+1,numBalls do
                id1 = ballID[i];
                id2 = ballID[j]
                ball1 = ball_global[id1];
                ball2 = ball_global[id2];
                dist = math.sqrt((ball1[1]-ball2[1])^2 + (ball1[2] - ball2[2])^2); 
                if dist < dist_thresh then
                    sees_teamball[id1] = 1;
                    sees_teamball[id2] = 1;
                end
            end
        end
       
        --Now count up how many people agree on team ball and find location and score
        --Location is an average of all ball positions and score is average score plus how many players have seen it
        num_teamball = 0;
        ball_score = 0;
        ball_loc = {0,0,0};
        for i = 1,5 do
            if sees_teamball[i] == 1 then
                num_teamball = num_teamball + 1;
                ball_score = ball_score + scoreBall[i];
                ball_loc[1] = ball_loc[1] + ball_global[i][1];
                ball_loc[2] = ball_loc[2] + ball_global[i][2];
            end
        end
        
        --If we are actually seeing the teamball, then average the score and location
        if num_teamball > 0 then        
            ball_score = ball_score/num_teamball + num_teamball;
            ball_loc = {ball_loc[1]/num_teamball, ball_loc[2]/num_teamball,0};
        
        --If not, we are seeing different balls, so just choose the one with the highest individual score
        else
            for i = 1,5 do
                if scoreBall[i] > ball_score then
                    ball_score = scoreBall[i];
                    ball_loc[1] = ball_global[i][1];
                    ball_loc[2] = ball_global[i][2];
                end
            end
        end               
    end    
    return ball_loc,ball_score  
end


function exit() end
function get_role()   return role; end
function get_player_id()    return playerID; end
function update_shm() gcm.set_team_role(role);end

function set_role(r)
    if role ~= r then
        role = r;
        Body.set_indicator_role(role);
    end
    
    if role == nil then
        role = ROLE_DEFENDER2; -- just in case, we had role become nil before and crash stuff
    end
    update_shm();
end

--NSL role can be set arbitarily, so use config value
--set_role(Config.game.role or 1);

--Dont need to use any flipping or confused checks anymore

--[[confused_threshold_x= Config.team.confused_threshold_x or 3.0;
confused_threshold_y= Config.team.confused_threshold_y or 3.0;
flip_threshold_x= Config.team.flip_threshold_x or 1.0;
flip_threshold_y= Config.team.flip_threshold_y or 1.5;
flip_threshold_t= Config.team.flip_threshold_t or 0.5;
flip_check_t = Config.team_flip_check_t or 3.0;
flip_threshold_hard_x= Config.team.flip_threshold_hard_x or 2.0;]]--

--[[function check_confused()
  
  if wcm.get_team_goalie_alive()==0 then  --Goalie's dead, we're doomed. Kick randomly
    wcm.set_robot_is_confused(0);
    return; 
  end 
   --Goalie or reserve players never get confused
  if role==ROLE_GOALIE or role > ROLE_DEFENDER2  then 
    wcm.set_robot_is_confused(0);
    return; 
  end

  pose = wcm.get_pose();
  t = Body.get_time();
  is_confused = wcm.get_robot_is_confused();

  if is_confused>0 then  --Currently confused
    if gcm.get_game_state() ~= 3     --If game state is not gamePlaying
       or gcm.in_penalty() then     --Or the robot is penalized
      wcm.set_robot_is_confused(0); --Robot gets out of confused state!
    end
  else     --Should we turn confused?
    if wcm.get_robot_is_fall_down()>0 
       and math.abs(pose.x)<confused_threshold_x 
       and math.abs(pose.y)<confused_threshold_y 
       and gcm.get_game_state() == 3 then --Only get confused during playing
      wcm.set_robot_is_confused(1);
      wcm.set_robot_t_confused(t);
    end
  end

end

function fix_flip()
  local pose = wcm.get_pose();
  local ball = wcm.get_ball();
  local ball_global = util.pose_global({ball.x,ball.y,0},{pose.x,pose.y,pose.a});
  local t = Body.get_time();


  --TODO: Can we trust FAR bal observations?

  --Even the robot thinks he's not flipped, fix flipping if it's too obvious
  if t-ball.t<flip_threshold_t  and goalie_ball[3]<flip_threshold_t then --Both robot seeing the ball
   if (math.abs(ball_global[1])>flip_threshold_hard_x) and
      (math.abs(goalie_ball[1])>flip_threshold_hard_x) and      --Check X position
      ball_global[1]*goalie_ball[1]<0 then 
      wcm.set_robot_flipped(1) 
	  print('flip1');
	  print(debug.traceback());
    end
  else
    return --cannot fix flip if both robot are not seeing the ball
  end

  if wcm.get_robot_is_confused()==0 then return; end
  local t_confused = wcm.get_robot_t_confused();
  if t-t_confused < flip_check_t then return; end   --Give the robot some time to localize

  --Both I and goalie should see the ball
  if (math.abs(ball_global[1])>flip_threshold_x) and
    (math.abs(goalie_ball[1])>flip_threshold_x) then      --Check X position
    if ball_global[1]*goalie_ball[1]<0 then wcm.set_robot_flipped(1)
		print('flip2');
		print(debug.traceback());
	 end

   --Now we are sure about our position
   wcm.set_robot_is_confused(0);
  elseif (math.abs(ball_global[2])>flip_threshold_y) and
        (math.abs(goalie_ball[2])>flip_threshold_y) then      --Check Y position
    if ball_global[2]*goalie_ball[2]<0 then wcm.set_robot_flipped(1)
		print('flip3');
		print(debug.traceback());
    end   
   --Now we are sure about our position
   wcm.set_robot_is_confused(0);
  end

end]]--

--Update local obstacle information based on other robots' localization info
function update_obstacle()
    
    local t = Body.get_time();
    local t_timeout = 2.0;
    pose = wcm.get_pose();
    obstacle_count = 0;
    obstacle_x=vector.zeros(10);
    obstacle_y=vector.zeros(10);
    obstacle_dist=vector.zeros(10);
    obstacle_role=vector.zeros(10);
    
    --loop through own team and opponenets
    for i=1,10 do
        
        --check to make sure the data we have is valid
        if t_poses[i]~=0 and t-t_poses[i]<t_timeout and player_roles[i]< ROLE_LOST  then
            
            obstacle_count = obstacle_count+1;
            
            --get location of obstacle relative to my current position
            local obstacle_local = util.pose_relative({poses[i].x,poses[i].y,0},{pose.x,pose.y,pose.a}); 
            
            --use relative positoin to find distance and xy coords
            dist = math.sqrt(obstacle_local[1]^2+obstacle_local[2]^2);
            obstacle_x[obstacle_count]=obstacle_local[1];
            obstacle_y[obstacle_count]=obstacle_local[2];
            obstacle_dist[obstacle_count]=dist;
            
            --assig obstacle role based on team
            if i<6 then --Same team
                obstacle_role[obstacle_count] = player_roles[i]; --0,1,2,3,4
            else --Opponent team
                obstacle_role[obstacle_count] = player_roles[i]+5; --5,6,7,8,9
            end
        end
    end
    
    --update shm with this info
    wcm.set_obstacle_num(obstacle_count);
    wcm.set_obstacle_x(obstacle_x);
    wcm.set_obstacle_y(obstacle_y);
    wcm.set_obstacle_dist(obstacle_dist);
    wcm.set_obstacle_role(obstacle_role);
end
