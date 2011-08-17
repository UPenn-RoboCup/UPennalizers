module(..., package.seeall);

require('Config');	-- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');	-- For Projection
require('Vision');
require('Body');
require('vcm');

-- Dependency
require('detectBall');
require('detectGoal');
require('detectLine');
require('detectLandmarks'); -- for NSL
require('detectSpot');
--[[
require('detectFreespace');
require('detectObstacles');
require('detectEyes');
require('detectStretcher');
--]]

-- Define Color
colorObstacle = 0;
colorOrange = 1;
colorYellow = 2;
colorCyan = 4;
colorField = 8;
colorWhite = 16;

use_point_goal=Config.vision.use_point_goal;
headInverted=Config.vision.headInverted;

yellowGoalCountThres = Config.vision.yellow_goal_count_thres;
enableLine = Config.vision.enable_line_detection;
enableSpot = Config.vision.enable_spot_detection;
enableMidfieldLandmark = Config.vision.enable_midfield_landmark_detection;

function entry()
	-- Initiate Detection
	ball = {};
	ball.detect = 0;

  ballYellow={};
	ballYellow.detect=0;
	
	ballCyan={};
	ballCyan.detect=0;

	goalYellow = {};
	goalYellow.detect = 0;

	goalCyan = {};
	goalCyan.detect = 0;

	landmarkYellow = {};
	landmarkYellow.detect = 0;

	landmarkCyan = {};
	landmarkCyan.detect = 0;

	line = {};
	line.detect = 0;

	spot = {};
	spot.detect = 0;

	obstacle={};
	obstacle.detect=0;

	freespace={};
	freespace.detect=0;

end

function update()

  if( Config.gametype == "stretcher" ) then
    ball = detectEyes.detect(colorOrange);
    return;
  end

  -- ball detector
  ball = detectBall.detect(colorOrange);

  -- goal detector
  if use_point_goal == 1 then
    ballYellow = detectBall.detect(colorYellow);
    ballCyan = detectBall.detect(colorCyan);
  else
    --if (colorCount[colorYellow] > colorCount[colorCyan]) then
    if (Vision.colorCount[colorYellow] > yellowGoalCountThres) then
      goalYellow = detectGoal.detect(colorYellow);
      goalCyan.detect = 0;
    else
      goalCyan = detectGoal.detect(colorCyan);
      goalYellow.detect = 0;
    end
  end

  -- line detection
  if enableLine == 1 then
    line = detectLine.detect();
  end

  -- spot detection
  if enableSpot == 1 then
--    spot = detectSpot.detect();
  end

  -- TODO: add landmarks to vcm shm (for NSL support)
  -- midfield landmark detection
  if enableMidfieldLandmark == 1 then
  	landmarkCyan = detectLandmarks.detect(colorCyan,colorYellow);
    landmarkYellow = detectLandmarks.detect(colorYellow,colorCyan);
  end

end

function update_shm()
  vcm.set_ball_detect(ball.detect);
  if (ball.detect == 1) then
    vcm.set_ball_centroid(ball.propsA.centroid);
    vcm.set_ball_axisMajor(ball.propsA.axisMajor);
    vcm.set_ball_axisMinor(ball.propsA.axisMinor);
    vcm.set_ball_v(ball.v);
    vcm.set_ball_r(ball.r);
    vcm.set_ball_dr(ball.dr);
    vcm.set_ball_da(ball.da);
    -- Velocity measurements
    
  end

  vcm.set_goal_detect(math.max(goalCyan.detect, goalYellow.detect));
  if (goalCyan.detect == 1) then
    vcm.set_goal_color(colorCyan);
    vcm.set_goal_type(goalCyan.type);
    vcm.set_goal_v1(goalCyan.v[1]);
    vcm.set_goal_v2(goalCyan.v[2]);
  elseif (goalYellow.detect == 1) then
    vcm.set_goal_color(colorYellow);
    vcm.set_goal_type(goalYellow.type);
    vcm.set_goal_v1(goalYellow.v[1]);
    vcm.set_goal_v2(goalYellow.v[2]);
  end

  -- midfield landmark detection
  if enableMidfieldLandmark == 1 then
    --[[
    vcm.etc.landmarkCyan[1]=landmarkCyan.detect;
    if( landmarkCyan.detect == 1 ) then
      vcm.etc.landmarkCyan[2] = landmarkCyan.v[1];
      vcm.etc.landmarkCyan[3] = landmarkCyan.v[2];
    end

    vcm.etc.landmarkYellow[1] = landmarkYellow.detect;
    if (landmarkYellow.detect == 1) then
      vcm.etc.landmarkYellow[2] = landmarkYellow.v[1];
      vcm.etc.landmarkYellow[3] = landmarkYellow.v[2];
    end
    --]]
  end

  vcm.set_line_detect(line.detect);
  if (line.detect == 1) then
    vcm.set_line_v(line.v);
    vcm.set_line_angle(line.angle);
    vcm.set_line_vcentroid(line.vcentroid);
    vcm.set_line_vendpoint(line.vendpoint);
  end

  --vcm.set_spot_detect(spot.detect);
  if (spot.detect == 1) then
  end

end

function exit()
end
