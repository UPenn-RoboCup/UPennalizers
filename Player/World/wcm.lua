module(..., package.seeall);

require('shm');
require('util');
require('vector');
require('Config');

-- shared properties
shared = {};
shsize = {};


--We use shm to monitor all the process states
shared.process={}
shared.process.broadcast = vector.zeros(1)

shared.process.v1 = vector.zeros(3) --tLast sum_tPassed CountCurrent 
shared.process.v2 = vector.zeros(3) 
shared.process.bro = vector.zeros(3) 
shared.process.fsm = vector.zeros(3)






shared.robot = {};
shared.robot.pose = vector.zeros(3);
shared.robot.uTorso = vector.zeros(3);
shared.robot.battery_level = vector.zeros(1);
shared.robot.is_fall_down = vector.zeros(1);
shared.robot.is_emergency_stop = vector.zeros(1);
shared.robot.time = vector.zeros(1);
shared.robot.penalty = vector.zeros(1);
shared.robot.gpspose = vector.zeros(3);
shared.robot.gps_attackbearing = vector.zeros(1);
shared.robot.gps_ball = vector.zeros(3);
shared.robot.odomScale = vector.zeros(3);

shared.robot.team_ball = vector.zeros(3);
shared.robot.team_ball_score = vector.zeros(1);
shared.robot.use_team_ball = vector.zeros(1);

shared.robot.flipped = vector.zeros(1);
shared.robot.is_confused = vector.zeros(1);
shared.robot.t_confused = vector.zeros(1);
shared.robot.resetWorld = vector.zeros(1);
shared.robot.confidence = vector.zeros(1);
shared.robot.resetOrientation = vector.zeros(1);

shared.ball = {};
shared.ball.x = vector.zeros(1);
shared.ball.y = vector.zeros(1);
shared.ball.t = vector.zeros(1);
shared.ball.velx = vector.zeros(1);
shared.ball.vely = vector.zeros(1);
shared.ball.dodge = vector.zeros(1);
shared.ball.locked_on = vector.zeros(1);
shared.ball.p = vector.zeros(1);


shared.ball.v_inf = vector.zeros(2);
shared.ball.t_locked_on = vector.zeros(1);


shared.team = {};


shared.team.my_eta = vector.zeros(1);
shared.team.attacker_eta = vector.zeros(1);
shared.team.defender_eta = vector.zeros(1);
shared.team.defender2_eta = vector.zeros(1);
shared.team.supporter_eta = vector.zeros(1);
shared.team.goalie_alive = vector.zeros(1);

shared.team.attacker_pose = vector.zeros(3);
shared.team.defender_pose = vector.zeros(3);
shared.team.defender2_pose = vector.zeros(3);
shared.team.supporter_pose = vector.zeros(3);
shared.team.goalie_pose = vector.zeros(3);

shared.team.attacker_walkTo = vector.zeros(2);
shared.team.defender_walkTo = vector.zeros(2);
shared.team.defender2_walkTo = vector.zeros(2);
shared.team.supporter_walkTo = vector.zeros(2);
shared.team.goalie_walkTo = vector.zeros(2);

shared.team.players_alive = vector.zeros(1);


shared.goal = {};
shared.goal.t = vector.zeros(1);
shared.goal.attack = vector.zeros(3);
shared.goal.defend = vector.zeros(3);
shared.goal.attack_bearing = vector.zeros(1);
shared.goal.attack_angle = vector.zeros(1);
shared.goal.defend_angle = vector.zeros(1);
shared.goal.attack_post1 = vector.zeros(2);
shared.goal.attack_post2 = vector.zeros(2);


shared.goal.attack_angle2 = vector.zeros(1);
shared.goal.daPost2 = vector.zeros(1);


--Added for side approach/sidekick/kickoff handling
shared.kick = {};
shared.kick.dir=vector.zeros(1);
shared.kick.angle=vector.zeros(1);
shared.kick.type=vector.zeros(1);
shared.kick.kickOff = vector.zeros(1);
shared.kick.tKickOff = vector.zeros(1);

--Added for obstacle avoidance for webots
shared.obstacle = {};
shared.obstacle.num = vector.zeros(1);
shared.obstacle.x = vector.zeros(10);
shared.obstacle.y = vector.zeros(10);
shared.obstacle.dist = vector.zeros(10);
shared.obstacle.role = vector.zeros(10);


--NEW obstacle variable (just for the costmap)
shared.obspole={}
shared.obspole.num = vector.zeros(1)
shared.obspole.x = vector.zeros(10)
shared.obspole.y = vector.zeros(10)
shared.obspole.t = vector.zeros(10)





--Localization monitoring
shared.particle = {};
shared.particle.x=vector.zeros(Config.world.n);
shared.particle.y=vector.zeros(Config.world.n);
shared.particle.a=vector.zeros(Config.world.n);
shared.particle.w=vector.zeros(Config.world.n);

-- Sound localization
shared.sound = {};
shared.sound.odomPose = vector.zeros(3);
-- TODO: sound histogram filter size should be set in the config
--shared.sound.histogram = vector.zeros(Config.sound.??);
radPerBin = 30*math.pi/180;
shared.sound.detFilter = vector.zeros(math.floor(2*math.pi/radPerBin));
shared.sound.detCount = vector.zeros(1);
shared.sound.detTime = vector.zeros(1);
shared.sound.detLIndex = vector.zeros(1);
shared.sound.detRIndex = vector.zeros(1);


use_planner = Config.use_planner or false


if use_planner then
  local div = Config.planner_div or 0.1
  local xdim = 4.5*2/div + 1
  local ydim = 3*2/div + 1  
  local traj_max = 100

  shared.robot.cost1=vector.zeros(xdim*ydim)
  shared.robot.cost2=vector.zeros(xdim*ydim)
  shared.robot.dist=vector.zeros(xdim*ydim)    

  shared.robot.traj_num=vector.zeros(1)
  shared.robot.traj_x=vector.zeros(traj_max)
  shared.robot.traj_y=vector.zeros(traj_max)

  shsize.robot = xdim*ydim*4*4 + 2^16 --assign big block


end



-----------------------------------------------
-- This shm is used for wireless team monitoring only
-- Indexed by player ID + teamOffset 
-----------------------------------------------
listen_monitor = Config.listen_monitor or 0;

if listen_monitor>0 then
  shared.teamdata={};
  shared.teamdata.teamnum=vector.zeros(1);
  shared.teamdata.teamColor=vector.zeros(10);
  shared.teamdata.robotId=vector.zeros(10);
  shared.teamdata.role=vector.zeros(10);
  shared.teamdata.time=vector.zeros(10);
  --Latency information
  shared.teamdata.gclatency=vector.zeros(10);
  shared.teamdata.tmlatency=vector.zeros(10);


  shared.teamdata.posex=vector.zeros(10);
  shared.teamdata.posey=vector.zeros(10);
  shared.teamdata.posea=vector.zeros(10);

  shared.teamdata.ballx=vector.zeros(10);
  shared.teamdata.bally=vector.zeros(10);
  shared.teamdata.ballt=vector.zeros(10);
  shared.teamdata.ballvx=vector.zeros(10);
  shared.teamdata.ballvy=vector.zeros(10);

  shared.teamdata.attackBearing=vector.zeros(10);
  shared.teamdata.fall=vector.zeros(10);
  shared.teamdata.penalty=vector.zeros(10);
  shared.teamdata.battery_level=vector.zeros(10);

  shared.teamdata.goal=vector.zeros(10);
  shared.teamdata.goalv11=vector.zeros(10);
  shared.teamdata.goalv12=vector.zeros(10);
  shared.teamdata.goalv21=vector.zeros(10);
  shared.teamdata.goalv22=vector.zeros(10);

  shared.teamdata.goalB11=vector.zeros(10);
  shared.teamdata.goalB12=vector.zeros(10);
  shared.teamdata.goalB13=vector.zeros(10);
  shared.teamdata.goalB14=vector.zeros(10);
  shared.teamdata.goalB15=vector.zeros(10);

  shared.teamdata.goalB21=vector.zeros(10);
  shared.teamdata.goalB22=vector.zeros(10);
  shared.teamdata.goalB23=vector.zeros(10);
  shared.teamdata.goalB24=vector.zeros(10);
  shared.teamdata.goalB25=vector.zeros(10);

  shared.teamdata.cornera=vector.zeros(10);
  shared.teamdata.cornerv1=vector.zeros(10);
  shared.teamdata.cornerv2=vector.zeros(10);

--Team LabelB monitoring
  if type(Config.camera.width) == 'number' then
    processed_img_width = {Config.camera.width, Config.camera.width};
  else
    processed_img_width = Config.camera.width;
  end
  if type(Config.camera.height) == 'number' then
    processed_img_height = {Config.camera.height, Config.camera.height};
  else
    processed_img_height = Config.camera.height;
  end

  top_labelB_size =  ((processed_img_width[1]/Config.vision.scaleA[1]/Config.vision.scaleB[1])*
     (processed_img_height[1]/Config.vision.scaleA[1]/Config.vision.scaleB[1]));

  shared.labelBtop = {};
  shared.labelBtop.p1 = top_labelB_size;
  shared.labelBtop.p2 = top_labelB_size;
  shared.labelBtop.p3 = top_labelB_size;
  shared.labelBtop.p4 = top_labelB_size;
  shared.labelBtop.p5 = top_labelB_size;
  shared.labelBtop.p6 = top_labelB_size;
  shared.labelBtop.p7 = top_labelB_size;
  shared.labelBtop.p8 = top_labelB_size;
  shared.labelBtop.p9 = top_labelB_size;
  shared.labelBtop.p10 = top_labelB_size;
  shsize.labelBtop = 10*top_labelB_size + 2^16;

  btm_labelB_size =  ((processed_img_width[2]/Config.vision.scaleA[2]/Config.vision.scaleB[2])*
     (processed_img_height[2]/Config.vision.scaleA[2]/Config.vision.scaleB[2]));

  shared.labelBbtm = {};
  shared.labelBbtm.p1 = btm_labelB_size;
  shared.labelBbtm.p2 = btm_labelB_size;
  shared.labelBbtm.p3 = btm_labelB_size;
  shared.labelBbtm.p4 = btm_labelB_size;
  shared.labelBbtm.p5 = btm_labelB_size;
  shared.labelBbtm.p6 = btm_labelB_size;
  shared.labelBbtm.p7 = btm_labelB_size;
  shared.labelBbtm.p8 = btm_labelB_size;
  shared.labelBbtm.p9 = btm_labelB_size;
  shared.labelBbtm.p10 = btm_labelB_size;
  shsize.labelBbtm = 10*btm_labelB_size + 2^16;


  shared.robotNames = {};
  shared.robotNames.n1 = '';
  shared.robotNames.n2 = '';
  shared.robotNames.n3 = '';
  shared.robotNames.n4 = '';
  shared.robotNames.n5 = '';
  shared.robotNames.n6 = '';
  shared.robotNames.n7 = '';
  shared.robotNames.n8 = '';
  shared.robotNames.n9 = '';
  shared.robotNames.n10 = '';

  shared.bodyStates = {};
  shared.bodyStates.n1 = '';
  shared.bodyStates.n2 = '';
  shared.bodyStates.n3 = '';
  shared.bodyStates.n4 = '';
  shared.bodyStates.n5 = '';
  shared.bodyStates.n6 = '';
  shared.bodyStates.n7 = '';
  shared.bodyStates.n8 = '';
  shared.bodyStates.n9 = '';
  shared.bodyStates.n10 = '';

end

util.init_shm_segment(getfenv(), _NAME, shared, shsize);


-- helper functions for access the data in the same manner as World

function get_ball()
  return {x=get_ball_x(), y=get_ball_y(), 
	vx=get_ball_velx(), vy=get_ball_vely(), 
	t=get_ball_t(),	p=get_ball_p()};
end

function get_pose()
  pose = get_robot_pose();
  return {x=pose[1], y=pose[2], a=pose[3]};
end

function get_tGoal()
  return get_goal_t();
end

function get_attack_bearing()
  return get_goal_attack_bearing();
end

function get_attack_angle()
  return get_goal_attack_angle();
end

function get_defend_angle()
  return get_goal_defend_angle();
end

function get_sound_detection()
   return {count = get_sound_detCount(),
           time = get_sound_detTime(),
           lIndex = get_sound_detLIndex(),
           rIndex = get_sound_detRIndex()};
end
