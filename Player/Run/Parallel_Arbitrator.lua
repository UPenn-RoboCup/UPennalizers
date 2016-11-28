-- Since we have more then one camera
-- arbitrator will be used to make decision
module(... or "",package.seeall)
cwd = os.getenv('PWD')
require('init')
require('unix')
require('vcm')
require('wcm')
require('World')
--require('Speak')

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

function line_decision(cidx, detect)
  if detect == 0 then
    return vcm.set_line_detect(0);
  end
  vcm.set_line_detect(detect)
  vcm.set_line_v1x(vcm['get_line'..cidx..'_v1x']())
  vcm.set_line_v1y(vcm['get_line'..cidx..'_v1y']())
  vcm.set_line_v2x(vcm['get_line'..cidx..'_v2x']())
  vcm.set_line_v2y(vcm['get_line'..cidx..'_v2y']())
  vcm.set_line_real_length(vcm['get_line'..cidx..'_real_length']())
  vcm.set_line_endpoint11(vcm['get_line'..cidx..'_endpoint11']())
  vcm.set_line_endpoint12(vcm['get_line'..cidx..'_endpoint12']())
  vcm.set_line_endpoint21(vcm['get_line'..cidx..'_endpoint21']())
  vcm.set_line_endpoint22(vcm['get_line'..cidx..'_endpoint22']())
  vcm.set_line_xMean(vcm['get_line'..cidx..'_xMean']())
  vcm.set_line_yMean(vcm['get_line'..cidx..'_yMean']())
  vcm.set_line_v(vcm['get_line'..cidx..'_v']())
  vcm.set_line_angle(vcm['get_line'..cidx..'_angle']())
  vcm.set_line_nLines(vcm['get_line'..cidx..'_nLines']())
  vcm.set_line_lengthB(vcm['get_line'..cidx..'_lengthB']())
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

function line_arbitration()

  if Config.camera.ncamera < 2 then
    return line_decision(1, vcm.get_ball1_detect())
  end

  local detect1 = vcm.get_line1_detect();
  local detect2 = vcm.get_line2_detect();

  if detect2 == 1 then
  -- if bottom camera sees lines, use them
    return line_decision(2, detect2)
  elseif detect1 == 1 then
  -- otherwise use top camera
    return line_decision(1, detect1)
  else
    return line_decision(0, 0)
  end
end

function update()
  processcount = processcount+1;
  ball_arbitration();
  line_arbitration();
  
  --manually reset world pose for debugging/testing
  --any other process can set this shm value to call world reset
  if wcm.get_robot_resetWorld() == 1 then
	World.init_particles()
	wcm.set_robot_resetWorld(0);
  end

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
      --Speak.talk('Game Control Updating');
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

