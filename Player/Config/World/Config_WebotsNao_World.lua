module(..., package.seeall);
require('vector')

--Localization parameters 

world={};
world.n = 200;
world.xLineBoundary = 4.5;
world.yLineBoundary = 3.0;
world.xMax = 4.7;
world.yMax = 3.2;
world.goalWidth = 1.60;
world.goalHeight= 0.85;
world.postDiameter = 0.10; -- diameter of a post
world.ballYellow= {{4.5,0.0}};
world.ballCyan= {{-4.6,0.0}};
world.postYellow = {};
world.postYellow[1] = {4.5, 0.80};
world.postYellow[2] = {4.5, -0.80};
world.postCyan = {};
world.postCyan[1] = {-4.5, -0.80};
world.postCyan[2] = {-4.5, 0.80};
world.spot = {};
world.spot[1] = {-2.70, 0};
world.spot[2] = {2.70, 0};



--They are SPL 2013 values
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
--
world.Lcorner[21]={0,0.75,-0.25*math.pi};
world.Lcorner[22]={0,0.75,0.25*math.pi};
world.Lcorner[23]={0,0.75,-0.75*math.pi};
world.Lcorner[24]={0,0.75,0.75*math.pi};
world.Lcorner[25]={0,-0.75,-0.25*math.pi};
world.Lcorner[26]={0,-0.75,0.25*math.pi};
world.Lcorner[27]={0,-0.75,-0.75*math.pi};
world.Lcorner[28]={0,-0.75,0.75*math.pi};
--


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






-- default positions for our kickoff
world.initPosition1={
  {4.2,0},   --Goalie
  {0.5, 0}, --Attacker
  {1.2,-1.5}, --Defender
  {1.2, 1.5}, --Supporter
  {2.2, 0}, --Defender2
}
-- default positions for opponents' kickoff
-- Penalty mark : {1.2,0}
world.initPosition2={
  {4.2,0},   --Goalie
  {2.0, 0}, --Attacker
  {2.5, -1.5}, --Defender
  {2.5,1.5}, --Supporter
  {2.5, 0}, --Defender2
}

-- default positions for dropball
-- Center circle radius: 0.6
world.initPosition3={
  {2.8,0},   --Goalie
  {0.5,0}, --Attacker
  {1.5,-1.5}, --Defender
  {0.5,1.0}, --Supporter
  {1.5,1.5}, --Defender2
}



--Resampling parameters
world.cResample = 10; --Resampling interval
world.daNoise = 2.0*math.pi/180;
world.drNoise = 0.01;

-- filter weights

--Sigma value for one landmark observation
world.rSigmaSingle1 = .15;
world.rSigmaSingle2 = 0.10;
world.aSigmaSingle = 30*math.pi/180; --Original value: 5 deg

--Sigma value for two landmark observation
world.rSigmaDouble1 = .25;
world.rSigmaDouble2 = .20;
world.aSigmaDouble = 30*math.pi/180;

--TODO: make this depends on the distance to the goal
--Two post observation
world.rGoalFilter = 0.04 --0.02;
world.aGoalFilter = 0.1 --0.15; smaller seems better

--Single post observation
world.rPostFilter = 0.02;
world.aPostFilter = 0.05;

--Single known post observation
world.rPostFilter2 = 0.01;
world.aPostFilter2 = 0.04;

--Corner observation
world.rCornerFilter = 0.03;
world.aCornerFilter = 0.06;

--Circle observation
world.rCircleFilter = 0.03;
world.aCircleFilter = 0.02; --0.01


--Line observation
world.aLineFilter = 0.02;

-- use sound localization
world.enable_sound_localization = 0;
world.use_same_colored_goal=1;
world.use_new_goalposts = 1;
world.use_line_angles = 1;


world.triangulation_threshold = 3 --4.0; 
world.position_update_threshold = 4.5 --6.0;
world.angle_update_threshold = 2;
world.flip_correction = 1;
