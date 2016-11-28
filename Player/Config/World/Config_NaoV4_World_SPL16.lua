module(..., package.seeall);
require('vector')
require('unix')
local unix = require('unix');
local robotName = unix.gethostname();
--Localization parameters 


--These measurements are from Robocup 2016 in Germany
world={};
world.n = 200;
world.xLineBoundary = 4.5;
world.yLineBoundary = 3.0;
--the boundary is 70 cm wide than the actual field
--use 20 cm boundary for detection and localization
world.xMax = 4.7;
world.yMax = 3.2;
world.goalWidth = 1.60;
world.goalHeight= 0.85;
world.goalDiameter=0.0950; -- diameter of a post
world.ballYellow= {{4.5,0.0}};
world.ballCyan= {{-4.5,0.0}};
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

--constrain the goalie to only certain goals
world.Lgoalie_corner = {}
world.Lgoalie_corner[1] = world.Lcorner[5];
world.Lgoalie_corner[2] = world.Lcorner[6];
world.Lgoalie_corner[3] = world.Lcorner[11];
world.Lgoalie_corner[4] = world.Lcorner[12];
world.Lgoalie_corner[5] = world.Lcorner[15];
world.Lgoalie_corner[6] = world.Lcorner[16];

--T corners
world.Tcorner = {};
--Penalty box T corners
world.Tcorner[1]={4.5,1.1,math.pi};
world.Tcorner[2]={4.5,-1.1,math.pi};
world.Tcorner[3]={-4.5,1.1,0};
world.Tcorner[4]={-4.5,-1.1,0};
--cirlce T corners
world.Tcorner[5]={0,3,-0.5*math.pi};
world.Tcorner[6]={0,-3,0.5*math.pi};

--T corners for goalie
world.Tgoalie_corner = {};
--Penalty box T corners
world.Tgoalie_corner[1]=world.Tcorner[3];
world.Tgoalie_corner[2]=world.Tcorner[4];


--Sigma values for one landmark observation
world.rSigmaSingle1 = .15;
world.rSigmaSingle2 = .10;
world.aSigmaSingle = 10*math.pi/180;

--Sigma values for goal observation
world.rSigmaDouble1 = .25;
world.rSigmaDouble2 = .20;
world.aSigmaDouble = 20*math.pi/180;


--same-colored goalposts
world.use_same_colored_goal=1;

--should we use new triangulation?
world.use_new_goalposts=1;


--Player filter weights
if Config.game.playerID > 1 then
	--Two post observation
	world.rGoalFilter = 0;
	world.aGoalFilter = 0;

	--Single post observation
	world.rPostFilter = 0;
	world.aPostFilter = 0;

	--Single known post observation
	world.rPostFilter2 = 0;
	world.aPostFilter2 = 0;

	--Spot
	world.rSpotFilter = 0.01;
	world.aSpotFilter = 0.0001;

	--L Corner observation
	world.rLCornerFilter = 0.02
	world.aLCornerFilter = 0.01
	
	--T Corner observation
	world.rTCornerFilter = 0.03;
	world.aTCornerFilter = 0.01;
	
	--Top line observation
    world.rLineFilterTop = 0.0001
    world.aLineFilterTop = 0.005;
    
    --Bottom Line observation
    world.rLineFilterBtm = 0.01;
    world.aLineFilterBtm = 0.01;

	--Circle observation
	world.rCircleFilter = 0.02;
	world.aCircleFilter = 0.01;

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
	 world.rSpotFilter = 0.01;
	 world.aSpotFilter = 0.001; 
	 
	 --L Corner observation
	 world.rLCornerFilter = 0.01;
	 world.aLCornerFilter = 0.01;
	
	 --T Corner observation
	 world.rTCornerFilter = 0.01;
	 world.aTCornerFilter = 0.01;
	 
	--Top line observation
    world.rLineFilterTop = 0.0001;
    world.aLineFilterTop = 0.005;
    
    --Bottom Line observation
    world.rLineFilterBtm = 0.0001;
    world.aLineFilterBtm = 0.01;
	 
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
  {4.5, 0},   --Goalie
  {0.6, 0}, --Attacker
  {1.7, 1.2}, --Defender
  {1.7,-1.2}, --Supporter
  {3.5, 0},  --Defender2
}
-- default positions for opponents' kickoff
--_________________
--|    \    /     |
--|     \__/      |
--|       A       |
--|   S   .   D   |
--|     _D2___    |
--|____|__G__|____|
world.initPosition2={
  {4.5, 0},   --Goalie
  {1.2, 0}, --Attacker
  {2.0, 1}, --Defender
  {2.0,-1}, --Supporter
  {3.5, -0.5}, --Defender2
}

--Set default positions for robots when set up on sidelines
--Left and right defined as facing towards opponents goal
--{xPos, yPos, Ang}
--      _________________
--      |    \    /     |
--      |     \__/      |
--      |               |
-- S(#4)|       .       |A(#2)
--D2(#5)|     _____     |D(#3)
--      |____|_____|____|G(#1)

world.initPositionSidelines={
  {4.5, 3.0,-math.pi/2}, --Player 1, goalie on field corner to right of goal
  {3.2, 3 ,-math.pi/2}, --Player 2, attacker aligned with spot on right side of goal
  {3.9, 3.0,-math.pi/2}, --Player 3, defender aligned with penalty box on right side
  {3.2,-3.0, math.pi/2}, --Player 4, supporter aligned with spot on left side of goal
  {3.9,-3.0, math.pi/2}, --Player 5, defender2 aligned with penalty box on left side
}

--parameters to specify deviation of robot placement at start
--Values[units] {dx[m], dy[m], da[rad]}
world.initPositionSidelinesSpread = {0.05, 0.05, 5*math.pi/180};

--parameters for bimodal distibution during manual placement
world.pCircle = {0.7,0,0};
world.dpCircle = {0.1,0.1,10*math.pi/180};
world.pLine = {3.9,0,0};
world.dpLine = {0.1,5,10*math.pi/180};
world.fraction = 0.75; -- there is a 3/4 chance we get placed on the line

--Goalie pose during manual placement
world.pGoalie = {4.5,0};
world.dpGoalie = {0.04,0.04,math.pi/8};

--How much noise to add to model while walking
--More means the particles will diverge quicker
world.daNoise = 0.5*math.pi/180;
world.drNoise = 0.02;

--can enable for debugging, forces localization to always re-initialize
-- to sideline position defined above
world.forceSidelinePos = 0;

-- use sound localization
world.enable_sound_localization = 0;

--Scales odometry {x, y, angle}
world.odomScale = {1.05, 1, 1} --for walking forwards
world.odomScale2 = {0.9, 1, 1} -- for walking backwards

--Various thresholds
world.angle_update_threshold = 3.0
world.angle_update_threshold_goalie = math.huge
world.triangulation_threshold = 4.0;
world.position_update_threshold = 6.0;
world.triangulation_threshold_goalie = 0;
world.position_update_threshold_goalie =0;
