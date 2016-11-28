-- Since we have more then one camera
-- arbitrator will be used to make decision
module(... or "",package.seeall)
cwd = os.getenv('PWD')
require('init')
require('unix')
require('vcm')
require('wcm')
require('World')
require('Speak')
require('vector')
require('Broadcast')
require('getch')
require('Body')

teamNumber = Config.game.teamNumber;
comm_inited = false
monitor_inited =false
processcount = 0;
wcm.set_process_broadcast(0) --disable broadcast for default
coach_message = '';

function monitor_update()
  broadcast_enable = wcm.get_process_broadcast()
  if broadcast_enable==0 then return end

  if not monitor_inited then
    --require('getch')
    --require('Broadcast')
    monitor_inited = true
  end
  vcm.set_camera_broadcast(broadcast_enable) 
  Broadcast.update(broadcast_enable)
  Broadcast.update_img(broadcast_enable)    
end

function ball_decision(cidx, detect)
--  print(cidx)
  if detect == 0 then
    return vcm.set_ball_detect(0);
  end
  vcm.set_ball_detect(detect)
  vcm.set_ball_color_count(vcm['get_ball'..cidx..'_color_count']())
  vcm.set_ball_centroid(vcm['get_ball'..cidx..'_centroid']())
  vcm.set_ball_axisMajor(vcm['get_ball'..cidx..'_axisMajor']())
  vcm.set_ball_axisMinor(vcm['get_ball'..cidx..'_axisMinor']())
  vcm.set_ball_v( vcm['get_ball'..cidx..'_v']())
  vcm.set_ball_r( vcm['get_ball'..cidx..'_r']())
  vcm.set_ball_dr(vcm['get_ball'..cidx..'_dr']())
  vcm.set_ball_da(vcm['get_ball'..cidx..'_da']())
end

function ball_arbitration()
  if Config.camera.ncamera < 2 then
    return ball_decision(1, vcm.get_ball1_detect())
  end

  local detect1 = vcm.get_ball1_detect();
  local detect2 = vcm.get_ball2_detect();
  
  if detect2 == 1 then
  --if bottom camera detects the ball, trust it
    return ball_decision(2, detect2)
  elseif detect1 == 1 then 
  --otherwise use top camera 
    return ball_decision(1, detect1)
  else 
    return ball_decision(0, 0)
  end

end

------------------------------------------------
function coach_observation()
    coach_message = 'no ball'; 
    headAngle = Body.get_head_position();
    --print('Nao Body headAngle '..headAngle[1]..' '..headAngle[2]);
    if (vcm.get_ball_detect() == 1) then
        local ballv = vcm.get_ball_v();
        local posex = Config.vision.coach.posex;
        local posey = Config.vision.coach.posey;
        local fieldx = ballv[1] + 3 + posey;
        local fieldy = posex - ballv[2];
        ballvx = math.floor(ballv[1]*10);
        ballvy = math.floor(ballv[2]*10);
        if (fieldx > 0 and fieldx < 5.7) then
            if (headAngle[1] > 0 and headAngle[1] < 1.7) then
                if (fieldy >= 1.5 and fieldy < 2) then
                    --coach_message = 'ball is close to the left'
                    coach_message = ballvx.." "..ballvy..' ball is close to the left'
                elseif (fieldy >= 2 and fieldy < 3) then
                    --coach_message = 'ball is very close to the left'
                    coach_message = ballvx.." "..ballvy..' ball is very close to the left'
                elseif (fieldy >= 3 and fieldy < 4.5) then
                    --coach_message = 'ball is very very close to the left'
                    coach_message = ballvx.." "..ballvy..' ball is very very close to the left'
                end
            elseif (headAngle[1] < 0 and headAngle[1] > -1.7) then
                if (fieldy <= -1.5 and fieldy > -2) then
                    --coach_message = 'the ball is close to the right'
                    coach_message = ballvx.." "..ballvy..' the ball is close to the right'
                elseif (fieldy <= -2 and fieldy > -3) then
                    --coach_message = 'the ball is very close to the right'
                    coach_message = ballvx.." "..ballvy..' the ball is very close to the right'
                elseif (fieldy <= -3 and fieldy > -4.5) then
                    --coach_message = 'the ball is very very close to the right'
                    coach_message = ballvx.." "..ballvy..' the ball is very very close to the right'
                end
            elseif (fieldy > -1.5 and fieldy < 1.5) then
                --coach_message = 'in the middle'
                coach_message = ballvx.." "..ballvy..' in the middle'
            else
                coach_message = 'false ball y coordinate'
            end
        else
                coach_message = 'false ball x coordinate'
        end
    end
    --print('@@@@@@@@@@@@@@@@coach message '..coach_message);
    CoachComm.send(teamNumber, coach_message);
    --add_coach_message(coach_message);
    --coach_message_filter();
end
coach_message_t = {}
count = 0;
------------------------------------------------
function add_coach_message(coach_message) 
    count = count % 3 + 1;
    coach_message_t[count] = coach_message;
    count = count + 1;
end
------------------------------------------------
function coach_message_filter()
    if coach_message_t[1] == coach_message_t[2] and coach_message_t[2] == coach_message_t[3] then
    local cm = coach_message_t[1];
    CoachComm.send(teamNumber, coach_message);
end
end
------------------------------------------------
function coach_observation_check()
    coach_message = 'no ball'; 
    if (vcm.get_ball_detect() == 1) then
        local ballv = vcm.get_ball_v();
        local linev = vector.zeros(4);
        local posex = Config.vision.coach.posex;
        if (vcm.get_line_detect() == 1) then
            linev = vcm.get_line_v();
        end

        --[[if (ballv[2] > posex or ballv[2] > linev[2]) then
            toLeft = true;
        else
            toLeft = false;
        end--]]

        local fieldy = ballv[2] - posex;
        ballvx = math.floor(ballv[1]*10);
        ballvy = math.floor(ballv[2]*10);
        if (fieldy >= 1.5 and fieldy < 2) then
            coach_message = ballvx.." "..ballvy..' ball is close to the left'
        elseif (fieldy >= 2 and fieldy < 3) then
            coach_message = ballvx.." "..ballvy..' ball is very close to the left'
        elseif (fieldy >= 3) then
            coach_message = ballvx.." "..ballvy..' ball is very very close to the left'
        elseif (fieldy <= -1.5 and fieldy > -2) then
            coach_message = ballvx.." "..ballvy..' the ball is close to the right'
        elseif (fieldy <= -2 and fieldy > -3) then
            coach_message = ballvx.." "..ballvy..' the ball is very close to the right'
        elseif (fieldy <= -3) then
            coach_message = ballvx.." "..ballvy..' the ball is very very close to the right'
        else
            coach_message = ballvx.." "..ballvy..' in the middle'
        end
        
    end
    print('@@@@@@@@@@@@@@@@coach message '..coach_message);
    CoachComm.send(teamNumber, coach_message);
end
------------------------------------------------
function coach_observation_old()
  if (vcm.get_line_detect() == 1) then
        local linev = vcm.get_line_v();
        print("====Line====", linev, "\n");
        if (linev ~= vector.zeros(4)) then
            if (vcm.get_ball_detect() == 1) then
                local ballv = vcm.get_ball_v();
                print("~~~~Ball~~~~", ballv, "\n");
                if (ballv[2] >= linev[2]) then
                    --print(t.."@@@@Ball is on the left side!");
                    coach_message = tag..", Ball is on the left side, y value is, "..tostring(ballv[2])
                    --CoachComm.send(teamNumber, coach_message);            
                elseif (ballv[2] < linev[2]) then 
                    --print(t.."@@@@Ball is on the right side!");
                    coach_message = tag..", Ball is on the right side, y value is, "..tostring(ballv[2])
                    --CoachComm.send(teamNumber, coach_message);
                end
            else 
                coach_message = tag..", no ball in sight"
                --CoachComm.send(teamNumber, coach_message);
        end
      end
    end
    CoachComm.send(teamNumber, coach_message);
end
---------------------------------------
local currentTime = unix.time();
local checkTime = 0;
local checkTimeInt = 0;
local checkCount = 0;
tag=0;
function check()
    --print('check function being called');
    --print('currentTime '..currentTime);
    --print('checkTime '..checkTime);
    currentTime = unix.time();
    if (currentTime - checkTime > 1) then
        --print('if statement true');
        checkTime = currentTime;
        checkTimeInt = math.floor(checkTime);
        checkCount = checkCount + 1;
        if (checkCount >= 10) then
            --print('~~~~~~~~~~~~~~~~~~~~~SHOULD BE A NEW MESSAGE~~~~~~~~~~~~~~~~~~~~~')
            checkCount = 0;
        end
        tag = checkTimeInt % 13;
        --print('TAG '..tag);
        coach_observation_check();
    end
end
--------------------------------------

function update()
  processcount = processcount+1;
  ball_arbitration();
  if vcm.get_camera_teambroadcast()>0 then 
    if not comm_inited then 
      require('CoachComm');
      CoachComm.init(Config.dev.ip_wireless_coach)
      require('GameControl');
      GameControl.entry();
      comm_inited = true;
      tlast = unix.time();
    else
      local t0 = unix.time()
      World.update_vision();
      GameControl.update();
      --[[if (t0 - tlast > 1*1E6 ) then 
        coach_observation(t0); 
        print('coach_observation called');
        tlast = unix.time();
      end--]]
        --coach_observation(t0);
        --check();  --use check function when testing and debugging because the message is slower so you can actually read it.
        coach_observation();
    end
  end
  local t0 = unix.time()
  local tlast;
  monitor_update()
  local t_loop = unix.time()-t0
	
  local broadcast_enable = wcm.get_process_broadcast()
  if broadcast_enable>0 then
    local v =wcm.get_process_bro()
    wcm.set_process_bro({v[1],v[2]+t_loop, v[3]+1})
  end

end

function entry()
  print "Start Vision Arbitrator"
  World.entry(); 
end

