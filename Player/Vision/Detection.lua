require('Config');	-- For Ball and Goal Size
require('vcm');
require('unix');
require('gcm');

local Ball = require('detectBall');
local Goal = require('detectGoal');
local Spot = require('detectSpot');
local Line = require('detectLine');
local Corner = require('detectCorner');
--local Robot = require('detectRobot');

local Detection = {}
local role = gcm.get_team_role();

if(role==5) then 
-- SJ: I'll temporarily disable this
-- Ball = require('detectBall_coach');
end



use_point_goal=Config.vision.use_point_goal;

enableLine = Config.vision.enable_line_detection or 0;
enableCorner = Config.vision.enable_corner_detection or 0;
enable_freespace_detection = Config.vision.enable_freespace_detection or 0;
enableBoundary = Config.vision.enable_visible_boundary or 0;
enableRobot = Config.vision.enable_robot_detection or 0;
yellowGoals = Config.world.use_same_colored_goal or 0; 

--enableSpot = Config.vision.enable_spot_detection or 0;
-- For now only enable goalie to detect spot
if Config.game.playerID == 1 then
  enableSpot = 1
else
  --Non-goalie ignores corners, lines and spots
  enableCorner = 1
  enableLine = 1
  enableSpot = 0
end

local update = function(self, parent_vision)
  local cidx = parent_vision.camera_index;
    --top camera
  if cidx == 1 then
    self.goalYellow:update(Config.color.white, parent_vision);
    --the bottom camera does not see the ball
    if vcm.get_ball2_detect() == 0 then
      self.ball:update(Config.color.orange, parent_vision);
    end
  end
  --bottom camera
  if cidx == 2 then
    self.ball:update(Config.color.orange, parent_vision);
    if enableLine == 1 then 
      self.line:update(Config.color.white, parent_vision);
    end
    if enableCorner == 1 then
      self.corner:update(Config.color.white, parent_vision, self.line);
    end
    if enableSpot == 1 then 
      self.spot:update(Config.color.white, parent_vision);
    end

  end
end


local update_shm = function(self, parent_vision)
  indx = parent_vision.camera_index;
  if indx == 1 then
    self.goalYellow:update_shm(parent_vision);
    if vcm.get_ball2_detect() == 0 then
      self.ball:update_shm(parent_vision);
    else
      vcm.set_ball1_detect(0);
    end
  end
  if indx == 2 then
    self.ball:update_shm(parent_vision);
    if enableLine == 1 then
      self.line:update_shm(parent_vision);
    end
    if enableCorner == 1 then
      self.corner:update_shm(parent_vision);
    end
    if enableSpot == 1 then
      self.spot:update_shm(parent_vision);
    end

  end
end

function Detection.exit()
end

function Detection.entry(parent_vision)
  -- Initiate Detection
  local self = {}
  -- add method
  self.update = update
  self.update_shm = update_shm

  self.ball = Ball.entry(parent_vision)
  local indx = parent_vision.camera_index;
  if indx == 1 then
    self.goalYellow = Goal.entry(parent_vision)
  end
  if indx == 2 then
    self.line = Line.entry(parent_vision)
    self.corner = Corner.entry(parent_vision)
    self.spot = Spot.entry(parent_vision)
  end
  return self
end

return Detection
