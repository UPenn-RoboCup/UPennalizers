function h = shm_robot(teamNumber, playerID)
% function create the same struct as the team message from
% shared memory. for local debugging use

h.teamNumber = teamNumber;
h.playerID = playerID;
h.user = getenv('USER');

% create shm wrappers
h.gcmTeam  = shm(sprintf('gcmTeam%d%d%s',  h.teamNumber, h.playerID, h.user));
h.wcmRobot = shm(sprintf('wcmRobot%d%d%s', h.teamNumber, h.playerID, h.user));
h.wcmBall  = shm(sprintf('wcmBall%d%d%s',  h.teamNumber, h.playerID, h.user));
h.vcmImage = shm(sprintf('vcmImage%d%d%s', h.teamNumber, h.playerID, h.user));
h.vcmBall  = shm(sprintf('vcmBall%d%d%s',  h.teamNumber, h.playerID, h.user));
h.vcmGoal  = shm(sprintf('vcmGoal%d%d%s',  h.teamNumber, h.playerID, h.user));

% set function pointers
h.update = @update;
h.get_team_struct = @get_team_struct;
h.get_monitor_struct = @get_monitor_struct;
h.get_yuyv = @get_yuyv;
h.get_rgb = @get_rgb;
h.get_labelA = @get_labelA;
h.get_labelB = @get_labelB;

    function update(vargin)
        % do nothing
    end

    function r = get_team_struct()
        % returns the robot struct (in the same form as the team messages)
        r = [];
        try
            r.teamNumber = h.gcmTeam.get_number();
            r.teamColor = h.gcmTeam.get_color();
            r.id = h.gcmTeam.get_player_id();
            r.role = h.gcmTeam.get_role();
            
            pose = h.wcmRobot.get_pose();
            r.pose = struct('x', pose(1), 'y', pose(2), 'a', pose(3));
            
            ballxy = h.wcmBall.get_xy();
            ballt = h.wcmBall.get_t();
            r.ball = struct('x', ballxy(1), 'y', ballxy(2), 't', ballt );
            
            posts = {};
            posts.detect = h.vcmGoal.get_detect();
            posts.type = h.vcmGoal.get_type();
            posts.color = h.vcmGoal.get_color();
            posts.postBoundingBox1 = h.vcmGoal.get_postBoundingBox1();
            posts.postBoundingBox2 = h.vcmGoal.get_postBoundingBox2();
            r.goal = posts;
            
        catch
        end
    end

    function r = get_monitor_struct()
        % returns the monitor struct (in the same form as the monitor messages)
        r = [];
        try
            r.team = struct(...
                'number', h.gcmTeam.get_number(),...
                'color', h.gcmTeam.get_color(),...
                'player_id', h.gcmTeam.get_player_id(),...
                'role', h.gcmTeam.get_role()...
                );
            
            pose = h.wcmRobot.get_pose();
            r.robot = {};
            r.robot.pose = struct('x', pose(1), 'y', pose(2), 'a', pose(3));
            
            ballxy = h.wcmBall.get_xy();
            ballt = h.wcmBall.get_t();
            ball = {};
            ball.detect = h.vcmBall.get_detect();
            ball.centroid = {};
            centroid = h.vcmBall.get_centroid();
            ball.centroid.x = centroid(1);
            ball.centroid.y = centroid(2);
            ball.axisMajor = h.vcmBall.get_axisMajor();
            r.ball = struct('x', ballxy(1), 'y', ballxy(2), 't', ballt, ...
                'centroid', ball.centroid, 'axisMajor', ball.axisMajor, ...
                'detect', ball.detect);
            r.goal = {};
            r.goal.detect = h.vcmGoal.get_detect();
            r.goal.type = h.vcmGoal.get_type();
            r.goal.color = h.vcmGoal.get_color();
            
            % Add the goal positions
            goalv1 = h.vcmGoal.get_v1();
            r.goal.v1 = struct('x',goalv1(1), 'y',goalv1(2), 'z',goalv1(3), 'scale',goalv1(4));
            goalv2 = h.vcmGoal.get_v2();
            r.goal.v2 = struct('x',goalv2(1), 'y',goalv2(2), 'z',goalv2(3), 'scale',goalv2(4));
            
            % Add the bounding boxes
            bb1 = h.vcmGoal.get_postBoundingBox1();
            r.goal.postBoundingBox1 = struct('x1',bb1(1), 'x2',bb1(2), 'y1',bb1(3), 'y2',bb1(4));
            bb2 = h.vcmGoal.get_postBoundingBox2();
            r.goal.postBoundingBox2 = struct('x1',bb2(1), 'x2',bb2(2), 'y1',bb2(3), 'y2',bb2(4));
            
        catch
        end
    end

    function yuyv = get_yuyv()
        % returns the raw YUYV image
        width = h.vcmImage.get_width();
        height = h.vcmImage.get_height();
        rawData = h.vcmImage.get_yuyv();
        yuyv = raw2yuyv(rawData, width, height);
    end

    function rgb = get_rgb()
        % returns the raw RGB image (not full size)
        yuyv = h.get_yuyv();
        rgb = yuyv2rgb(yuyv);
    end

    function labelA = get_labelA()
        % returns the labeled image
        width = h.vcmImage.get_width()/2;
        height = h.vcmImage.get_height()/2;
        rawData = h.vcmImage.get_labelA();
        labelA = raw2label(rawData, width, height)';
    end

    function labelB = get_labelB()
        % returns the bit-ored labeled image
        width = h.vcmImage.get_width()/2/4;
        height = h.vcmImage.get_height()/2/4;
        rawData = h.vcmImage.get_labelB();
        labelB = raw2label(rawData, width, height);
    end
end

