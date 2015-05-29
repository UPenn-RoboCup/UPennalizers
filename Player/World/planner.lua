module(..., package.seeall);

require('Config');
require('vector');
require('vcm');
require('gcm');
require('util');

costmap={}
costmap.div=Config.planner_div or 0.1
costmap.xdim = 4.5*2/costmap.div + 1
costmap.ydim = 3*2/costmap.div + 1
costmap.x={}
costmap.y={}
costmap.cost={}

costmap.cost_l=vector.zeros(costmap.xdim*costmap.ydim)
costmap.dist_l=vector.zeros(costmap.xdim*costmap.ydim)

s2=math.sqrt(2)
neighbor={{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}}
neighbor_d={s2,1,s2,1,1,s2,1,s2}

neighbor2={{-1,-1},{-1,0},{-1,1},{0,-1},{0,0},{0,1},{1,-1},{1,0},{1,1}}
neighbor2_d={s2,1,s2,1,0,1,s2,1,s2}

for i=1,costmap.xdim do costmap.x[i]=(i-1)*costmap.div-4.5 end
for i=1,costmap.ydim do costmap.y[i]=(i-1)*costmap.div-3 end

function init()
  for i=1,costmap.xdim do costmap.cost[i]=vector.zeros(costmap.ydim) end
  costmap.cost_l=vector.zeros(costmap.xdim*costmap.ydim)
end

costmap.state=0 

function update()
  t0=unix.time()    
  if costmap.state==0 then
    update_obstacle()
    init_astar()
--    print("obstacle updating time:",unix.time()-t0)
  elseif costmap.state==1 then
    update_astar(50)  
--    print("astar updating time:",unix.time()-t0)
  elseif costmap.state==2 then
    init_trajectory()
    calculate_trajectory()
--    print("trajectory updating time:",unix.time()-t0)
    costmap.state=0
  end
end


local obs_bound = 1
function update_obstacle()
  init()
  local obsx = wcm.get_obspole_x()
  local obsy = wcm.get_obspole_y()
  for k=1,wcm.get_obspole_num() do
--    local xy0 = xy_to_index({obsx[k]-1, obsy[k]-1})
--    local xy1 = xy_to_index({obsx[k]+1, obsy[k]+1})
    local xy0 = xy_to_index({obsx[k]-obs_bound, obsy[k]-obs_bound})
    local xy1 = xy_to_index({obsx[k]+obs_bound, obsy[k]+obs_bound})
    for i=xy0[1],xy1[1] do
      for j=xy0[2],xy1[2] do
        local xpos = (i-1)*costmap.div-4.5
        local ypos = (j-1)*costmap.div-3
        local dist = (obsx[k]-xpos)^2+(obsy[k]-ypos)^2
        costmap.cost[i][j]=costmap.cost[i][j]+(1/2/math.pi/0.1)*math.exp(-dist/2/0.1)
        costmap.cost_l[(j-1)*costmap.xdim + i]=costmap.cost[i][j]
      end
    end

  end
  wcm.set_robot_cost1(costmap.cost_l)
end

function init_astar()

  costmap.state=1

  costmap.dist={}
  costmap.closed={}
  costmap.dist_l = vector.ones(costmap.xdim*costmap.ydim)*100
  for i=1,costmap.xdim do
    costmap.dist[i]=vector.ones(costmap.ydim)*100
    costmap.closed[i]=vector.zeros(costmap.ydim)
  end
  local target = gcm.get_team_pose_target()
  local pose = wcm.get_robot_pose()
  costmap.openset={xy_to_index(target)}  --temporary
  costmap.start=xy_to_index(pose)
--  print("start index",unpack(xy_to_index(target)))
--  print("end index",unpack(xy_to_index(pose)))
  costmap.dist[costmap.openset[1][1]][costmap.openset[1][2]]=0
end

function update_astar(maxcount)
  local reached = false
  local count = 0
  
  while #costmap.openset>0 and reached==false and count<maxcount do
    count = count +     1
    local mindist=999
    local minindex=1
    for i=1,#costmap.openset do
      local curdist = costmap.dist[costmap.openset[i][1]][costmap.openset[i][2]]
      curdist = curdist + math.sqrt(
        (costmap.openset[i][1]-costmap.start[1])^2+(costmap.openset[i][2]-costmap.start[2])^2
        )
      if curdist<mindist then mindist,minindex=curdist,i end
    end

    local current = costmap.openset[minindex]
    costmap.closed[current[1]][current[2]]=2
    table.remove(costmap.openset,minindex)
    if current[1]==costmap.start[1] and current[2]==costmap.start[2] then reached=true end
    for k=1,#neighbor do
      local neighbor_i = {neighbor[k][1]+current[1], neighbor[k][2]+current[2]}
      if neighbor_i[1]>0 and neighbor_i[1]<=costmap.xdim and
        neighbor_i[2]>0 and neighbor_i[2]<=costmap.ydim and
        costmap.closed[neighbor_i[1]][neighbor_i[2]]<2 then

         local neighbor_dist = neighbor_d[k]*
            (1+costmap.cost[neighbor_i[1]][neighbor_i[2]]*10)
         costmap.dist[neighbor_i[1]][neighbor_i[2]]=math.min(
          costmap.dist[neighbor_i[1]][neighbor_i[2]],
          costmap.dist[current[1]][current[2]]+neighbor_dist
          )
         if costmap.closed[neighbor_i[1]][neighbor_i[2]]==0 then
           costmap.closed[neighbor_i[1]][neighbor_i[2]]=1
           costmap.openset[#costmap.openset+1]=neighbor_i
         end
      end
    end
  end
--  print("searched state:",count)
  if count==maxcount then
  else
    for i=1,costmap.xdim do
      for j=1,costmap.ydim do
        costmap.dist_l[(j-1)*costmap.xdim + i]=costmap.dist[i][j]
      end
    end
    wcm.set_robot_dist(costmap.dist_l)
    costmap.state=2 --Updating done
  end
end

local traj_count,traj_x,traj_y
local current_xy,target_xy


function init_trajectory()
  traj_x=vector.zeros(100)
  traj_y=vector.zeros(100)
  traj_count = 0

  local pose = wcm.get_robot_pose()
  current=xy_to_index(pose)
  current_dist = costmap.dist[current[1]][current[2]]
  current_xy = pose
  target_xy = gcm.get_team_pose_target()
end


function calculate_trajectory()
  local reached =false
  while reached==false and traj_count<100 do
    reached = true
    traj_count = traj_count + 1
    traj_x[traj_count]=current_xy[1]
    traj_y[traj_count]=current_xy[2]
  
    local current = xy_to_index(current_xy)
    local current_dist = costmap.dist[current[1]][current[2]]
    local min_dist = current_dist
    for k=1,#neighbor2 do
      local neighbor_i = {current[1]+neighbor2[k][1],current[2]+neighbor2[k][2]}
      neighbor_i[1] = math.max(1,math.min(costmap.xdim,neighbor_i[1]))
      neighbor_i[2] = math.max(1,math.min(costmap.ydim,neighbor_i[2]))
      neighbor_dist = costmap.dist[neighbor_i[1]][neighbor_i[2]]
      if neighbor_dist<min_dist and k~=5 then
        reached = false
        next_index=neighbor_i
        min_dist = neighbor_dist
      end
    end

    local target_dist=math.sqrt((current_xy[1]-target_xy[1])^2+(current_xy[2]-target_xy[2])^2)
    if target_dist<0.2 then reached = true end

    if not reached then
--    if true then
      if current[1]==1 or current[2]==1 or 
        current[1]==costmap.xdim or current[2]==costmap.ydim then
        current_xy[1]= (next_index[1]-1)*0.1-4.5
        current_xy[2]= (next_index[2]-1)*0.1-3
      else
        local x_grad = costmap.dist[next_index[1]+1][next_index[2]]
                      -costmap.dist[next_index[1]-1][next_index[2]]
        local y_grad = costmap.dist[next_index[1]][next_index[2]+1]
                      -costmap.dist[next_index[1]][next_index[2]-1]
        local grad_mag = math.sqrt(x_grad*x_grad+y_grad*y_grad)                      
        current_xy[1] = current_xy[1]-x_grad/grad_mag*0.1
        current_xy[2] = current_xy[2]-y_grad/grad_mag*0.1
      end
    end
  end
  wcm.set_robot_traj_num(traj_count)
  wcm.set_robot_traj_x(traj_x)
  wcm.set_robot_traj_y(traj_y)
--  print("trajectory calc: ",traj_count)
end



function xy_to_index(xy)
  local x_i =  math.floor ( (xy[1]+4.5)/costmap.div + 0.5)+1
  local y_i =  math.floor ( (xy[2]+3)/costmap.div + 0.5)+1
  x_i=math.max(1,math.min(costmap.xdim,x_i))
  y_i=math.max(1,math.min(costmap.ydim,y_i))
  return{x_i,y_i}
end