--Ashleigh
--This code is used to broadcast each robot's information over network
--Sent string is in lua format (for monitoring)

module(..., package.seeall);


require('MonitorComm')
require('vcm')
require('gcm')
require('wcm')
require('Team')
require('World')
require('Body')
require('Config')
require('serialization');

function update(enable)
  if enable==0 then return; end
  
  send = {};

  send.robot = {};
  local robotpose = wcm.get_robot_pose();
  send.robot.pose = {x=robotpose[1], y=robotpose[2], theta=robotpose[3]};

  send.ball = {};
  send.ball.detect = vcm.get_ball_detect();
  local ballcentroid = vcm.get_ball_centroid();
  send.ball.centroid = {x=ballcentroid[1], y=ballcentroid[2]};
  send.ball.axisMajor = vcm.get_ball_axisMajor();
  send.ball.axisMinor = vcm.get_ball_axisMinor();

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

  send.time = Body.get_time();

  send.team = {};
  send.team.number = gcm.get_team_number();
  send.team.player_id = gcm.get_team_player_id();
  send.team.color = gcm.get_team_color();
  send.team.role = gcm.get_team_role();
  
  MonitorComm.send(serialization.serialize(send));

  -- If level 1, then just send the data, no vision
  if enable==1 then return; end

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

  -- If level 2, then just send labelB
  if enable==2 then return; end
  
  

  --Send image packets--

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
  end

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
  end

end
