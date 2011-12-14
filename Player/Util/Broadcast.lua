--Steve
--Ashleigh
--This code is used to broadcast each robot's information over network
--Sent string is in lua format (for monitoring)

module(..., package.seeall);


require('MonitorComm')
-- Only send items from shared memory
require('vcm')
require('gcm')
require('wcm')
require('serialization');
require('ImageProc')

-- Add a little delay between packet sending
pktDelay = 500; -- time in us

function sendB()
  -- labelB --
  labelB = vcm.get_image_labelB();
  width = vcm.get_image_width()/8; 
  height = vcm.get_image_height()/8;
  count = vcm.get_image_count();
  
  array = serialization.serialize_array(labelB, width, height, 'uint8', 'labelB', count);
  sendlabelB = {};
  sendlabelB.team = {};
  sendlabelB.team.number = gcm.get_team_number();
  sendlabelB.team.player_id = gcm.get_team_player_id();
  
  for i=1,#array do
    sendlabelB.arr = array[i];
    MonitorComm.send(serialization.serialize(sendlabelB));
  end 
end

function sendA()
  -- labelA --
  labelA = vcm.get_image_labelA();
  width = vcm.get_image_width()/2; 
  height = vcm.get_image_height()/2;
  count = vcm.get_image_count();
  
  array = serialization.serialize_array(labelA, width, height, 'uint8', 'labelA', count);
  sendlabelA = {};
  sendlabelA.team = {};
  sendlabelA.team.number = gcm.get_team_number();
  sendlabelA.team.player_id = gcm.get_team_player_id();
  
  for i=1,#array do
    sendlabelA.arr = array[i];
  	MonitorComm.send(serialization.serialize(sendlabelA));
    -- Need to sleep in order to stop drinking out of firehose
    unix.usleep(pktDelay);
  end
end

-- labelA (subsampled) --
function sendAsub()
  labelA = vcm.get_image_labelA();
  labelAsub = ImageProc.subsample( labelA );
  width = vcm.get_image_width()/4;
  height = vcm.get_image_height()/4;
  count = vcm.get_image_count();
  
  array = serialization.serialize_array(labelAsub, width, height, 'uint8', 'labelAsub', count);
  sendlabelAsub = {};
  sendlabelAsub.team = {};
  sendlabelAsub.team.number = gcm.get_team_number();
  sendlabelAsub.team.player_id = gcm.get_team_player_id();
  
  for i=1,#array do
    sendlabelAsub.arr = array[i];
  	MonitorComm.send(serialization.serialize(sendlabelAsub));
    -- Need to sleep in order to stop drinking out of firehose
    unix.usleep(pktDelay);
  end
end

function sendImg()
  -- yuyv --
  yuyv = vcm.get_image_yuyv();
  width = vcm.get_image_width()/2; -- number of yuyv packages
  height = vcm.get_image_height();
  count = vcm.get_image_count();
  
  array = serialization.serialize_array(yuyv, width, height, 'int32', 'yuyv', count);
  sendyuyv = {};
  sendyuyv.team = {};
  sendyuyv.team.number = gcm.get_team_number();
  sendyuyv.team.player_id = gcm.get_team_player_id();
  
  for i=1,#array do
    sendyuyv.arr = array[i];
  	MonitorComm.send(serialization.serialize(sendyuyv));
    -- Need to sleep in order to stop drinking out of firehose
    unix.usleep(pktDelay);
  end

end

-- yuv (subsampled from yuyv) --
function sendImgSub()
  yuyv = vcm.get_image_yuyv();
  yuvSub = ImageProc.subsample_yuyv2yuv( yuyv );
  -- TODO: I am sending 3 bytes per pixel.
  width = vcm.get_image_width()/2; -- number of yuyv packages
  height = vcm.get_image_height()/2;
  count = vcm.get_image_count();
  
  array = serialization.serialize_array(yuvSub, width, height, 'uint8', 'yuvSub', count);
  sendyuvSub = {};
  sendyuvSub.team = {};
  sendyuvSub.team.number = gcm.get_team_number();
  sendyuvSub.team.player_id = gcm.get_team_player_id();
  
  for i=1,#array do
    sendyuvSub.arr = array[i];
  	MonitorComm.send(serialization.serialize(sendyuvSub));
    -- Need to sleep in order to stop drinking out of firehose
    unix.usleep(pktDelay);
  end

end


function update(enable)
  if enable==0 then return; end
  
  send = {};

  send.robot = {};
--[[
  local robotpose = wcm.get_robot_pose();
  send.robot.pose = {x=robotpose[1], y=robotpose[2], a=robotpose[3]};
--]]
  send.robot.pose = wcm.get_pose();

  send.ball = {};
  send.ball.detect = vcm.get_ball_detect();
  local ballcentroid = vcm.get_ball_centroid();
  send.ball.centroid = {x=ballcentroid[1], y=ballcentroid[2]};
  send.ball.axisMajor = vcm.get_ball_axisMajor();
  send.ball.axisMinor = vcm.get_ball_axisMinor();
  local ballxy = wcm.get_ball_xy();
  send.ball.x = ballxy[1];
  send.ball.y = ballxy[2];
  send.ball.t = wcm.get_ball_t();

  send.goal = {};
  send.goal.detect = vcm.get_goal_detect();
  send.goal.color = vcm.get_goal_color();
  send.goal.type = vcm.get_goal_type();
  local goalv1 = vcm.get_goal_v1();
  send.goal.v1 = {x=goalv1[1], y=goalv1[2], z=goalv1[3], scale=goalv1[4]};
  local goalv2 = vcm.get_goal_v2();
  send.goal.v2 = {x=goalv2[1], y=goalv2[2], z=goalv2[3], scale=goalv2[4]};
  local bb1 = vcm.get_goal_postBoundingBox1();
  send.goal.postBoundingBox1 = {x1=bb1[1], x2=bb1[2], y1=bb1[3], y2=bb1[4]};
  local bb2 = vcm.get_goal_postBoundingBox2();
  send.goal.postBoundingBox2 = {x1=bb2[1], x2=bb2[2], y1=bb2[3], y2=bb2[4]};

  send.time = unix.time();

  send.team = {};
  send.team.number = gcm.get_team_number();
  send.team.player_id = gcm.get_team_player_id();
  send.team.color = gcm.get_team_color();
  send.team.role = gcm.get_team_role();
  send.team.attackBearing = wcm.get_attack_bearing();
  send.team.penalty = gcm.get_game_penalty( gcm.get_team_player_id() );

  MonitorComm.send(serialization.serialize(send));
  
  -- Send camera frames
  if enable==1 then -- just send the data, no vision
    return;
  elseif enable==2 then -- send labelB in addition to data
    sendB();
  elseif enable==3 then -- send labelA in addition to data
    -- Send labelA image      
    sendA();
    -- Send image packets
    sendImg();
  end

end

function update_img()
end
