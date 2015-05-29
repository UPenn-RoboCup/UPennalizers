-- Since we have more then one camera
-- arbitrator will be used to make decision
module(... or "",package.seeall)
cwd = os.getenv('PWD')
require('init')
require('unix')
require('vcm')
require('wcm')
require('World')


comm_inited = false
monitor_inited =false
processcount = 0;
wcm.set_process_broadcast(0) --disable broadcast for default


function monitor_update()
  broadcast_enable = wcm.get_process_broadcast()
  if broadcast_enable==0 then return end

  if not monitor_inited then
    require('getch')
    require('Broadcast')
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

function update()
  processcount = processcount+1;
  ball_arbitration();
  World.update_odometry();
  World.update_vision();
  if vcm.get_camera_teambroadcast()>0 then 
    if not comm_inited then 
      require('Team');
      print("requiring GameControl")
      require('GameControl');
      Team.entry();
      GameControl.entry();
      print("Starting to send wireless team message..");
      comm_inited = true;
    else
      local t0 = unix.time()
      GameControl.update();
      if processcount % 3 ==0 then
        --10 fps team update
        Team.update();
      end

    end
  end
  local t0 = unix.time()
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

