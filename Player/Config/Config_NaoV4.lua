module(..., package.seeall);
local unix = require('unix')
require('vector')
require('util')
--require('parse_hostname')


--Robot CFG should be loafsmd first to set PID values
local robotName = unix.gethostname();

--Speak enable
speakenable = 0;

-- play song
playSong = false
--songName = "./Music/band-march.wav"
songName = "./Music/cheers.wav"

platform = {};
platform.name = 'NaoV4'

listen_monitor=1

-- Game Parameters
-- init game table first since fsm need it
game = {};

-- Parameters Files
params = {}
params.name = {"Walk", "World", "Kick", "Vision", "FSM", "Camera","Robot"};
-- Select walk Confif file {from Player/Config folder}

params.Walk = "AlexNew"



----------    Select world file    -------------------
local worldFiles = {
	"SPL16Grasp",
	"SPL16",
}
params.World = worldFiles[2]
--------Setting Player ID's----------
--we define all names here for team monitor (now we are not sending robot names)
--Now ids should not overlap
robot_names_ids={
  tink=2,
  ticktock=3,
  hook=5,
  pockets=2, --sub   
  dickens=1,
  ruffio=4
}

-- Assign team number(To receive commands from game controller)
game.teamNumber = 22 --22. for testing new game controller;
game.robotName = robotName
game.playerID = robot_names_ids[robotName] or 0
game.robotID = game.playerID
game.teamColor = 0 --{ 0 is blue team, 1 is red team} -- parse_hostname.get_team_color()
game.nPlayers = 7
game.whistle_pitch = 100
game.whistle_mag = 10000

if game.playerID == 6 then
    game.role = 6;
elseif game.playerID == 7 then
    game.role = 5;
else
    game.role = game.playerID - 1; -- 0 for goalie
end

--- Location Specific Camera Parameters --
cameraFiles= {
        "Grasp_NewCarpet",
		"Sagar_July10_9PM",
        "Ellen_GRASP_Nov20_2",
		"Wang_Grasp_May202016_3pm",
		"Wang_GRASP_June232016_11am",
		"Germany2016_June28_10am"
}
params.Camera = cameraFiles[6];

--if (robotName == "bacon" or robotName == "tink") then params.Camera = cameraFiles[5] end
--if (game.role == 5) then
--        params.Camera = cameraFiles[4]
--end
 util.LoadConfig(params, platform)
------------------------------------------

-- Devive Interface Libraries
dev = {};
dev.comm = 'TeamComm' -- {This is .so file in Lib} --New one with STD comm moduled
dev.body = 'NaoBody'; -- {This file is in Player/Lib}
dev.camera = 'uvc'; -- {This is .so file in Lib} 
dev.kinematics = 'NaoKinematics'; -- {This is .so file in Lib} 
dev.ip_wired = '192.168.123.255';
dev.ip_wired_port = 111111;
--dev.ip_wireless = '192.168.1.255';
dev.ip_wireless = '10.0.255.255';
dev.ip_wireless_port = 10022
--dev.ip_wireless_gc = '192.168.1.44';
dev.ip_wireless_gc = '10.0.0.1';
dev.ip_wireless_coach = '192.168.1.255';
dev.game_control = 'NaoGameControl';
dev.team = 'TeamSPL'; -- {This file is in Player/World} 


-- FSM Parameters
fsm.game = ''; -- select GameFSM
fsm.body = {''}; -- select BodyFSM
fsm.head = {''}; -- select HeadFSM

-- Team Parameters
team = {};
team.msgTimeout = 5.0;
team.tKickOffWear =7.0;
team.turnSpeed = 1.0; --Average turning time for 360 deg
team.ballLostPenalty = 4.0; --ETA penalty per ball loss time
team.fallDownPenalty = 4.0; --ETA penalty per ball loss time
team.standStillPenalty = 3.0; --ETA penalty per emergency stop time
team.nonAttackerPenalty = 0.8; -- distance penalty from ball
team.nonDefenderPenalty = 0.5; -- distance penalty from goal
team.force_defender = 0;--Enable this to force defender mode
team.test_teamplay = 0; --Enable this to immobilize attacker to test team beha$

------- if ball is away than this from our goal, go support ------
team.support_dist = 3.0; 
team.supportPenalty = 0.5; --dist from goal
team.use_team_ball = 1;
team.team_ball_timeout = 3.0;  --use team ball info after this delay
team.team_ball_threshold = 0.5;
team.avoid_own_team = 0;
team.avoid_other_team = 0;
team.defender_pos_0 = {1.0,0}
team.defender_pos_1 = {2,0.3}
team.defender_pos_2 = {2,0.4}
team.defender_pos_3 = {2,-0.4}
team.supporter_pos = {3,1.25}
team.flip_correction = 0;



-- keyframe files
km = {};
if robotName ~= "ruffio" then
	km.standup_front = 'km_NaoV4_StandupFromFrontBH_Stream.lua';
	km.standup_front2= 'km_NaoV4_StandupFromFrontBH_Stream.lua';
	km.standup_back = 'km_NaoV4_StandupFromBackBH.lua';
	km.standup_back2 = 'km_NaoV4_StandupFromBackBH.lua';
else
  km.standup_front = 'km_NaoV4_StandupFromFront_Germany2016Ruffio.lua';
  km.standup_front2= 'km_NaoV4_StandupFromFront_Germany2016Ruffio.lua';
  km.standup_back = 'km_NaoV4_StandupFromBackBH.lua';
  km.standup_back2 = 'km_NaoV4_StandupFromBackBH.lua';
end

--if robotName == "pockets" then
--	km.standup_back='km_NaoV4_StandupFromBack_Fast.lua'; --commented out to test getups for germany 2016
--end

km.time_to_stand = 30; -- average time it takes to stand up in seconds

--vision.ball.max_distance = 2.5; --temporary fix for GRASP lab
vision.ball.fieldsize_factor = 1.2; --check whether the ball is inside the field
vision.ball.max_distance = 2; --if ball is this close, just pass the test

--Should we use ultrasound?
team.avoid_ultrasound = 1;

use_kalman_velocity = 0;

team.flip_threshold_x = 3;
team.flip_threshold_y =2.5;


team.vision_send_interval = 30


walk.variable_step = 1--disable this if you don't have invhyp.so
fsm.goalie_type = 2 --Moving and stopping goalie
fsm.goalie_reposition = 2 --Position reposition
fsm.goalie_use_walkkick = 1 
team.flip_correction = 1

--Logging
log = {};
log.enableLogFiles = true; --enables writing to file
log.overwriteFiles = false; --overwrites the file everytime (not working yet)
log.logLevel = 'debug'; --order is: trace,debug,info,warn,error,fatal
log.behaviorFile = 'Logs/behavior.txt';
log.teamFile = 'Logs/team.txt';
log.worldFile = 'Logs/world.txt';
log.motionFile = 'Logs/motion.txt';
log.visionFile = 'Logs/vision.txt';


--[[
fsm.bodyApproach.yTarget21 = {0.025,0.04,0.055}
--]]

--ENABLE THIS BLOCK FOR THE NEW KICK
--[[
largestep_enable = true
dev.walk = 'DirtyAwesomeWalk'
--OG value: {0.18 0.20} / {0.03 0.045 0.06}
fsm.bodyApproach.xTarget21 = {0,0.21,0.23} --little away
--]]

fsm.new_head_fsm = 1

roll_feedback_enable = 1
pitch_feedback_enable = 1

enable_getup = true; 
disable_walk = false

disable_gyro_feedback = false

--Change values here for dropin
--Make sure to change player number too!
dropinGame = false 
if dropinGame then
    game.teamNumber = 99;
    dev.ip_wireless_port = 10099;
    dev.team = 'TeamDropin';
    team.force_attacker = 1;  
end


