module(..., package.seeall);

require('Config');
require('vector');
require('Body');

ball_log_index=1;
ball_logs={};
ball_log_count = 0;

-------------------------------
-- A very simple velocity filter
-------------------------------

noball_count = 1;
ball_count = 0;
--If ball is not seen for this # of frames, remove ball memory 
noball_threshold = 5; 
--How many succeding ball observations is needed before updating?
--We need at least two observation to update velocity
ball_threshold = 2;

gamma = 0.3;
discount = 0.8;

max_distance = 4.0; --Only check velocity within this radius
max_velocity = 4.0; --Ignore if velocity exceeds this


oldx,oldy=0,0;
olda,oldR = 0,0;
newA,newR = 0,0;

--Now we maintain a cue of ball distance
--Current ball distance is the minimum one
ballR_cue_length = 10;
ballR_cue=vector.zeros(ballR_cue_length);
ballR_index = 1;
min_ballR_old = 0;

goalie_log_balls = Config.goalie_log_balls or 0;
print("GOALIE",goalie_log_balls);

function add_log(x,y,vx,vy)

  role = gcm.get_team_role();

  if role~=0 or goalie_log_balls == 0 then
    return;
  end

  local log={};
  if ball_log_count == 0 then
    t0 = Body.get_time();
  end
  ball_log_count = ball_log_count+1;
  log.time = Body.get_time() - t0;
  log.ballxy = {x,y};
  log.ballvxy = {vx,vy};
  ball_logs[ball_log_count]=log;
end

function flush_log()
  if role~=0 or goalie_log_balls == 0 then
    return;
  end

  filename=string.format("./Data/balllog%d.txt",ball_log_index);
  outfile=assert(io.open(filename,"w"));

  data="";
  for i=1,ball_log_count do
    data=data..string.format(
      "%.2f %.2f %.2f %.2f %.2f\n",
     ball_logs[i].time,
     ball_logs[i].ballxy[1],
     ball_logs[i].ballxy[2],
     ball_logs[i].ballvxy[1],
     ball_logs[i].ballvxy[2]);
  end


  outfile:write(data);
  outfile:flush();
  outfile:close();

  ball_logs={};
  ball_log_count=0;
  ball_log_index = ball_log_index + 1;
end

function entry()
  oldx,oldy,vx,vy,isdodge=0,0,0,0,0;
  vxOld,vyOld = 0,0;
  t0 = Body.get_time();
  tLast=Body.get_time();
  noball_count=1;
end

function update(newx,newy)
  t=Body.get_time();
  ball_count = ball_count + 1;
  ballR = math.sqrt(newx^2+newy^2);
  ballA = math.atan2(newy,newx);

  --Lower gamma if head not locked on at the ball
  locked_on = wcm.get_ball_locked_on();
  if locked_on==0 then
--    vx,vy=0,0;
  end

  --Ball seen for some continuous frames
  if t>tLast and ball_count>=ball_threshold then
      tPassed=t-tLast;

      moveR = ((oldx - newx)^2 + (oldy - newy)^2);
      
      th = ballR * 0.05;
      if ballR > 2.0 then
        th = th*2;
      end
      if ballR > 3.0 then
	vx,vy=0,0;
        oldx = newx;
        oldy = newy;        
        tLast=t;
      elseif moveR>th then
        vxCurrent= (newx-oldx)/tPassed;
        vyCurrent= (newy-oldy)/tPassed;
	vmagCurrent = math.sqrt(vxCurrent^2+vyCurrent^2);

	if vmagCurrent<4.0 then --don't update if outlier
          vx = (1-gamma)*vx + gamma*vxCurrent;
          vy = (1-gamma)*vy + gamma*vyCurrent;
          oldx = newx;
          oldy = newy;        
          tLast=t;
        end
      else
	vx=vx*discount;
	vy=vy*discount;
        tLast=t;
      end
  else 
     --Ball first seen, don't update velocity
     vx=0;vy=0;
     --Update position
     oldx=newx;
     oldy=newy;
     tLast=t;
     noball_count=0;
  end

  vMag = math.sqrt(vx^2+vy^2);

  vR = 0.8;
  add_log(newx,newy,vx,vy);

--[[
  if vx<-vR and vMag > vR then
    print(string.format("BX  %.2f V %.2f====", newx,vx));
  else
    print(string.format("BX  %.2f V %.2f", newx,vx));
  end
--]]
end

function update_noball()
  ball_count = 0;
  noball_count=noball_count+1;
  --Reset velocity if ball was not seen 
  if noball_count==noball_threshold then
    --print("Velocity resetted")
    vx=0;vy=0;
    ballR_cue=vector.zeros(ballR_cue_length);
    min_ballR_old = 0;
    oldx,oldy=0,0;
    flush_log();

  else
   vx=gamma*vx;
   vy=gamma*vy;
  end
end

function getVelocity()
  return vx, vy, isdodge;
end
