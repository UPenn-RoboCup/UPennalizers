function h = net_robot(teamNumber, playerID)
% function create the same struct as the team message from
% shared memory. for local debugging use

h.teamNumber = teamNumber;
h.playerID = playerID;
h.user = getenv('USER');
h.robot_msg = {};
h.team_msg = {};
h.yuyv = [];
h.labelA = [];
h.labelB = [];
h.scale = 1;

% Setup arrays to track the images
h.yuyv_arr = construct_array('yuyv');
h.labelA_arr = construct_array('labelA');
h.labelB_arr = construct_array('labelB');

% set function pointers
h.update = @update;
h.get_team_struct = @get_team_struct;
h.get_monitor_struct = @get_monitor_struct;
h.get_yuyv = @get_yuyv;
h.get_rgb = @get_rgb;
h.get_labelA = @get_labelA;
h.get_labelB = @get_labelB;

    function scale = update( msg )
        %fprintf('msg.team# / h.team#:\t %d / %d\n',msg.team.number,h.teamNumber);
        %fprintf('msg.playerid# / h.playerid#:\t %d / %d\n', msg.team.id, h.playerID);
        % Check if the id field is correct before updating this robot
        if( msg.team.player_id == h.playerID && msg.team.number == h.teamNumber )
            if (isfield(msg, 'arr'))
                h.yuyv  = h.yuyv_arr.update_always(msg.arr);
                h.labelA = h.labelA_arr.update_always(msg.arr);
                h.labelB = h.labelB_arr.update(msg.arr);
                if(~isempty(h.labelB)) % labelB is gotten in one packet
                    h.scale = 4;
                else
                    h.scale = 1;
                end
            else
                % Update the robot
                h.robot_msg = msg;
                h.team_msg = msg.team;
                h.team_msg.id = h.playerID;
                h.team_msg.teamNumber = h.teamNumber;
                h.team_msg.ball = msg.ball;
                h.team_msg.pose = msg.robot.pose;
                h.team_msg.teamColor = msg.team.color;
            end
        end
        scale = h.scale;
    end

    function r = get_team_struct()
        % returns the robot struct (in the same form as the team messages)
        r = h.team_msg;
        %{
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
            
        catch
        end
        %}
    end

    function r = get_monitor_struct()
        % returns the monitor struct (in the same form as the monitor messages)
        r = h.robot_msg;
        %{
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
        catch
        end
        %}
    end

    function yuyv = get_yuyv()
        % returns the raw YUYV image
        yuyv = h.yuyv;
    end

    function rgb = get_rgb()
        % returns the raw RGB image (not full size)
        yuyv = h.get_yuyv();
        rgb = yuyv2rgb(yuyv);
    end

    function labelA = get_labelA()
        % returns the labeled image
        labelA = h.labelA;
    end

    function labelB = get_labelB()
        % returns the bit-ored labeled image
        labelB = h.labelB;
    end
end

