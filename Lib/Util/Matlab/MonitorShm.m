% Players and team to track
nPlayers = 1;
teamNumbers = [18];

% Should monitor run continuously?
continuous = 1;

%% Enter loop
figure(1);
clf;
tDisplay = .1; % Display every .1 seconds
tStart = tic;
nUpdate = 0;

%% create shm wrappers
user = getenv('USER');
shmWrappers = cell(nPlayers, length(teamNumbers));
for t = 1:length(teamNumbers)
    for p = 1:nPlayers
        sw = [];
        sw.gcmTeam  = shm(sprintf('gcmTeam%d%d%s',  teamNumbers(t), p, user));
        sw.wcmRobot = shm(sprintf('wcmRobot%d%d%s', teamNumbers(t), p, user));
        sw.wcmBall  = shm(sprintf('wcmBall%d%d%s',  teamNumbers(t), p, user));
        sw.vcmImage = shm(sprintf('vcmImage%d%d%s', teamNumbers(t), p, user));
        sw.vcmBall  = shm(sprintf('vcmBall%d%d%s',  teamNumbers(t), p, user));
        sw.vcmGoal  = shm(sprintf('vcmGoal%d%d%s',  teamNumbers(t), p, user));
        shmWrappers{p,t} = sw;
    end
end
robots = cell(nPlayers, length(teamNumbers));

while continuous
    nUpdate = nUpdate + 1;
    
    %% Record our information
    % get latest shm data
    for t = 1:length(teamNumbers)
        for p = 1:nPlayers
            robots{p, t} = shm2teammsg(shmWrappers{p,t}.gcmTeam, shmWrappers{p,t}.wcmRobot, shmWrappers{p,t}.wcmBall);
        end
    end
    
    
    %% Draw our information
    tElapsed=toc(tStart);
    if( tElapsed>tDisplay )
        %disp(tElapsed)
        tStart = tic;
        
        %% Gather data for show_monitor
        % Gather Image data
        yuyv = sw.vcmImage.get_yuyv();
        rgb = yuyv2rgb( typecast(yuyv(:), 'uint32') );
        rgb = reshape(rgb,[sw.vcmImage.get_width()/2,sw.vcmImage.get_height(),3]);
        rgb = permute(rgb,[2 1 3]);
        labelA = sw.vcmImage.get_labelA();
        labelA = typecast( labelA, 'uint8' );
        % Assume subsampling for labelA
        labelA = reshape(  labelA, [sw.vcmImage.get_width(),sw.vcmImage.get_height()]/2 );
        % Gather Object Data
        ball = {};
        ball.detect = sw.vcmBall.get_detect();
        ball.centroid = sw.vcmBall.get_centroid();
        ball.axisMajor = sw.vcmBall.get_axisMajor();
        posts = {};
        posts.detect = sw.vcmGoal.get_detect();
        posts.type = sw.vcmGoal.get_type();
        posts.color = sw.vcmGoal.get_type();
        posts.postBoundingBox1 = sw.vcmGoal.get_postBoundingBox1();
        posts.postBoundingBox2 = sw.vcmGoal.get_postBoundingBox2();
        
        %% Show the monitor
        show_monitor(rgb, labelA, robots, ball, posts, teamNumbers, nPlayers);
        drawnow;
    end
    
end
