module(..., package.seeall);

require('Config');
require('vector');
require('Body');

ball_log_index=1;
ball_logs={};
ball_log_count = 0;
no_ball = 0;
yes_ball = 0;

-------------------
-- Kalman filter -- 
-------------------

local torch = require 'torch'
torch.Tensor = torch.DoubleTensor
local libBallTrack = require 'libBallTrack'

-- myDim dimensional kalman filter
local myDim = 2;  -- 2 states: (x,y) -> (x,y,vx,vy)

-- Set the observations
local observation = torch.Tensor( 2 * myDim ):zero()

-- Initialize the filter
local tracker = libBallTrack.new_tracker();

max_distance = 3.0; --Only check velocity within this radius
max_velocity = 4.0; --Ignore if velocity exceeds this

oldx,oldy = 0,0;
olda,oldR = 0,0;
newA,newR = 0,0;

ballR_index = 1;
fps = 30;

goalie_log_balls = Config.goalie_log_balls or 0;
print("GOALIE",goalie_log_balls);

function add_log(x,y,vx,vy,t)
  role = gcm.get_team_role(); -- Goalie => role = 0 

  if role~=0 or goalie_log_balls == 0 then
    return;
  end

  local log={};

  ball_log_count = ball_log_count+1;
  log.time = t;
  log.ballxy = {x,y};
  log.ballvxy = {vx,vy};
  ball_logs[ball_log_count]=log;

--  print(string.format("ball log count %d",ball_log_count));

  if(ball_log_count == 500) then
    flush_log();
  end


end

function flush_log()

  if role~=0 or goalie_log_balls == 0 then
    return;
  end

  print("Flushing log");

  filename=string.format("./Data/balllog%d.txt",ball_log_index);
  outfile=assert(io.open(filename,"w"));

  data="";
  for i=1,ball_log_count do
  data=data..string.format(
      "%f %f %f %f %f\n",
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
  x,y,vx,vy,isdodge=0,0,0,0,0;
  oldx,oldy = 0,0;
end

function update(newx,newy,t)
  -- Perform correction
  local observation = {newx,newy};
  local a,b = newx-oldx,newy-oldy;
  local R = math.sqrt(math.pow(a,2)+math.pow(b,2));
  local position,vel,confidence;
  local dist = math.sqrt(math.pow(newx,2)+math.pow(newy,2));

  if( (R>0.3) or (a==0 and b==0) or (dist>max_distance) ) then
     tracker:reset();
     position, vel, confidence = tracker:update();
  else
     position, vel, confidence = tracker:update(observation);
  end

  yes_ball = yes_ball + 1;
  if(yes_ball > 2)  then
  	no_ball = 0;
  end
  oldx = newx;
  oldy = newy;
  vx = vel[1] * 30;
  vy = vel[2] * 30;
  add_log(oldx,oldy,vx,vy,t);
end

function update_noball(t)
-- Perform prediction
  no_ball = no_ball + 1;
  if(no_ball > 2) then
    tracker:reset();
    local position,velocity,confidence = tracker:update();
    yes_ball = 0;
  else  
    local position,velocity,confidence = tracker:update();
    vx = velocity[1] * 30;
    vy = velocity[2] * 30;
    add_log(position[1],position[2],vx,vy,t);
  end
end

function getVelocity()
  if(math.abs(vx)>0.5) then
   local n = 1;
-- n frames into the future
    local pp = (vx * n/ 30) + x;
     if(pp<0) then 
--     print('Predicted position',pp);
    end
  end
  return vx, vy, isdodge;
end
