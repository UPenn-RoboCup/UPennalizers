% Players and team to track
nPlayers = 1;
teamNumbers = [18];

% Should monitor run continuously?
continuous = .5;

%% Enter loop
figure(1);
clf;
tDisplay = 1; % Display every x seconds
tStart = tic;
nUpdate = 0;

%% Initialize data
% Image data
yuyv_arr = construct_array('yuyv');
labelA_arr = construct_array('labelA');
labelB_arr = construct_array('labelB');
yuyv = [];
labelA = [];
labelB = [];
% Object Data
ball = {};
ball.detect = 0;
posts = {};
posts.detect = 0;
% Robots Data
robots = cell(nPlayers, length(teamNumbers));

while continuous
    nUpdate = nUpdate + 1;
    
    %% Update our information
    if(monitorComm('getQueueSize') > 0)
        msg = monitorComm('receive');
        if ~isempty(msg)
            msg = lua2mat(char(msg));
            if (isfield(msg, 'arr'))
                %msg.arr
                yuyv = yuyv_arr.update_always(msg.arr);
                labelA = labelA_arr.update_always(msg.arr);
                labelB = labelB_arr.update(msg.arr);
            else
                if( isfield(msg, 'ball') ) % Circle the ball in the images
                    %scale = 4; % For labelB
                    ball = msg.ball;
                end
                if( isfield(msg, 'goal') ) % Circle the ball in the images
                    %scale = 4; % For labelB
                    posts = msg.goal;
                end
            end
        end
    end
    
    %% Draw our information
    tElapsed=toc(tStart);
    if( tElapsed>tDisplay )
        tStart = tic;
        % Show the monitor
        rgb = yuyv2rgb(yuyv');
        scale = 1;
        show_monitor(rgb, labelA, robots, ball, posts, teamNumbers, 0, scale);
        drawnow;
    end
    
end
