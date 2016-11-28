module(..., package.seeall);
require('vector')
require('unix')
local unix = require('unix');
local robotName = unix.gethostname();
--Localization parameters 

world={};
world.n = 200;
world.xLineBoundary = 4.5;
world.yLineBoundary = 3.0;
--the boundary is 70 cm wide than the actual field
--use 20 cm boundary for detection and localization
world.xMax = 4.7;
world.yMax = 3.2;
world.goalWidth = 1.60;
world.goalHeight= 0.65;
world.goalDiameter=0.1150; -- diameter of a post
world.ballYellow= {{4.5,0.0}};
world.ballCyan= {{-4.6,0.0}};
world.postYellow = {};
world.postYellow[1] = {4.5, 0.80};
world.postYellow[2] = {4.5, -0.80};
world.postCyan = {};
world.postCyan[1] = {-4.5, -0.80};
world.postCyan[2] = {-4.5, 0.80};
world.spot = {};
world.spot[1] = {-3.2, 0};
world.spot[2] = {3.2, 0};
world.cResample = 10; --Resampling interval


--These are SPL 2013 values
world.Lcorner={};
--Field edge
world.Lcorner[1]={4.5,3,-0.75*math.pi};
world.Lcorner[2]={4.5,-3,0.75*math.pi};
world.Lcorner[3]={-4.5,3,-0.25*math.pi};
world.Lcorner[4]={-4.5,-3,0.25*math.pi};
--Penalty box edge
world.Lcorner[5]={-3.9,1.1,-0.75*math.pi};
world.Lcorner[6]={-3.9,-1.1,0.75*math.pi};
world.Lcorner[7]={3.9,1.1,-0.25*math.pi};
world.Lcorner[8]={3.9,-1.1,0.25*math.pi};
--Penalty box T edge
world.Lcorner[9]={4.5,1.1,-0.75*math.pi};
world.Lcorner[10]={4.5,-1.1,0.75*math.pi};
world.Lcorner[11]={-4.5,1.1,-0.25*math.pi};
world.Lcorner[12]={-4.5,-1.1,0.25*math.pi};
world.Lcorner[13]={4.5,1.1,0.75*math.pi};
world.Lcorner[14]={4.5,-1.1,-0.75*math.pi};
world.Lcorner[15]={-4.5,1.1,0.25*math.pi};
world.Lcorner[16]={-4.5,-1.1,-0.25*math.pi};
--Center T edge
world.Lcorner[17]={0,3,-0.25*math.pi};
world.Lcorner[18]={0,3,-0.75*math.pi};
world.Lcorner[19]={0,-3,0.25*math.pi};
world.Lcorner[20]={0,-3,0.75*math.pi};
--Center Circle Junction
world.Lcorner[21]={0,0.75,-0.25*math.pi};
world.Lcorner[22]={0,0.75,0.25*math.pi};
world.Lcorner[23]={0,0.75,-0.75*math.pi};
world.Lcorner[24]={0,0.75,0.75*math.pi};
world.Lcorner[25]={0,-0.75,-0.25*math.pi};
world.Lcorner[26]={0,-0.75,0.25*math.pi};
world.Lcorner[27]={0,-0.75,-0.75*math.pi};
world.Lcorner[28]={0,-0.75,0.75*math.pi};

--Center circle junction
--[[
world.Lcorner[15]={0,0.6375};
world.Lcorner[16]={0,-0.6375};
world.Lcorner[17]={0.6375,0};
world.Lcorner[18]={-0.6375,0};
--]]

--constrain the goalie to only certain goals
world.Lgoalie_corner = {}
world.Lgoalie_corner[1] = world.Lcorner[5];
world.Lgoalie_corner[2] = world.Lcorner[6];
world.Lgoalie_corner[3] = world.Lcorner[11];
world.Lgoalie_corner[4] = world.Lcorner[12];
world.Lgoalie_corner[5] = world.Lcorner[15];
world.Lgoalie_corner[6] = world.Lcorner[16];

--same-colored goalposts
world.use_same_colored_goal=1;

--should we use new triangulation?
world.use_new_goalposts=1;


--Player filter weights
if Config.game.playerID > 1 then
	--Two post observation
	world.rGoalFilter = 0; --0.03;
	world.aGoalFilter = 0; --0.02;

	--Single post observation
	world.rPostFilter = 0; --0.01;
	world.aPostFilter = 0; --0.01;

	--Single known post observation
	world.rPostFilter2 = 0; --0.01;
	world.aPostFilter2 = 0; --0.01;

	--Spot
	world.rSpotFilter = 0;
	world.aSpotFilter = 0;

	--Corner observation
	world.rCornerFilter = 0.03;
	world.aCornerFilter = 0.05;

	--Line observation, these weights are different than others
	--wLineFilter specifies how much to scale weight error when observing lines
	--wLineBounds specifies how much to scale weight error that is out of bounds
	world.wLineFilter = 2;
	world.wLineBounds = 1;

	--Circle observation
	world.rCircleFilter = 0.03;
	world.aCircleFilter = 0.02;

else --for goalie
	--goal observation
	world.rGoalFilter = 0;
	world.aGoalFilter = 0;
	 
	 --Single post observation
	 world.rPostFilter = 0;
	 world.aPostFilter = 0;
	 
	 --Single known post observation
	 world.rPostFilter2 = 0;
	 world.aPostFilter2 = 0;
	 
	 --Spot
	 world.rSpotFilter = 0;
	 world.aSpotFilter = 0; 
	 
	--Corner observation
	 world.rCornerFilter = 0.03;
	 world.aCornerFilter = 0.06;
	 
	--Line observation, these weights are different than others
	--wLineFilter specifies how much to scale weight error when observing lines
	--wLineBounds specifies how much to scale weight error that is out of bounds
	world.wLineFilter = 2;
	world.wLineBounds = 1;
	 
	 --Circle observation
	world.rCircleFilter = 0;
	world.aCircleFilter = 0;
end

-- default positions for our kickoff
--_________________
--|    \  A /     |
--|     \__/      |
--|   S       D   |
--|      D2       |
--|     _____     |
--|____|__G__|____|
world.initPosition1={
  {4.3, 0},   --Goalie
  {0.4, 0}, --Attacker
  {1.5, 1.0}, --Defender
  {1.5,-1.0}, --Supporter
  {2.2, 0},  --Defender2
}
-- default positions for opponents' kickoff
--_________________
--|    \    /     |
--|     \__/      |
--|       A       |
--|   S   .   D   |
--|     ___D2_    |
--|____|__G__|____|
world.initPosition2={
  {4.0, 0},   --Goalie
  {1.0, 0}, --Attacker
  {2.0, 1}, --Defender
  {2.0,-1}, --Supporter
  {3.0, 0.5}, --Defender2
}

--Set default positions for robots when set up on sidelines
--Left and right defined as facing towards opponents goal
--{xPos, yPos, Ang}
--      _________________
--      |    \    /     |
--      |     \__/      |
-- S(#4)|               |A(#2)
--      |       .       |
--D2(#5)|     _____     |D(#3)
--      |____|_____|____|G(#1)
world.initPositionSidelines={
  {4.5, 3,-math.pi/2}, --Player 1, goalie on field corner to right of goal
  {1.6, 3,-math.pi/2}, --Player 2, attacker halfway b/w spot and half line on right side
  {3.9, 3,-math.pi/2}, --Player 3, defender aligned with penalty box on right side
  {1.6,-3, math.pi/2}, --Player 4, supporter halfway b/w spot and half line on left side
  {3.9,-3, math.pi/2}, --Player 5, defender2 aligned with penalty box on left side
}
--parameters to specify deviation of robot placement at start
--Values[units] {dx[m], dy[m], da[rad]}
world.initPositionSidelinesSpread = {0.05, 0.05, 5*math.pi/180};


--parameters for bimodal distibution during manual placement
world.pCircle = {0,0.7,0};
world.dpCircle = {0.1,0.1,10*math.pi/180};
world.pLine = {3.9,0,0};
world.dpLine = {0.1,1.5,10*math.pi/180};
world.fraction = 0.75; -- there is a 3/4 chance we get placed on the line

--Goalie pose during manual placement
world.pGoalie = {4.5,0};
world.dpGoalie = {0.04,0.04,math.pi/8};


--How much noise to add to model while walking
--More means the particles will diverge quicker
world.daNoise = 1*math.pi/180;
world.drNoise = 0.02;

--can enable for debugging, forces localization to always re-initialize
-- to sideline position defined above
world.forceSidelinePos = 0;

-- use sound localization
world.enable_sound_localization = 0;

--Scales odometry {x, y, angle} (tested in GRASP, probably needs to be changed for SPL)
world.odomScale = {1, 1, 1}

--Various thresholds
world.angle_update_threshold = 3.0
world.angle_update_threshold_goalie = math.huge
world.triangulation_threshold = 4.0;
world.position_update_threshold = 6.0;
world.triangulation_threshold_goalie = 0;
world.position_update_threshold_goalie =0;
