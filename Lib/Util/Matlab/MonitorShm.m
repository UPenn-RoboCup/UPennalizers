% Colormap
cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];

% Players and team to track
nPlayers = 1;
teamNumbers = [18];

%% Enter loop
figure(1);
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
        shmWrappers{p,t} = sw;
    end
end
robots = cell(nPlayers, length(teamNumbers));

while (1)
    nUpdate = nUpdate + 1;
    
    %% Record our information
    % get latest shm data
    for t = 1:length(teamNumbers)
        for p = 1:nPlayers
            robots{p, t} = shm2teammsg(shmWrappers{p,t}.gcmTeam, shmWrappers{p,t}.wcmRobot, shmWrappers{p,t}.wcmBall);
        end
    end
    
    %{
    if(ball.detect==1)
        scale = 4; % For labelB
        centroidB = msg.ball.centroid;
        centroidB.x = centroidB.x/scale;
        centroidB.y = centroidB.y/scale;
        radiusB = (msg.ball.axisMajor/scale)/2;
        ballB = [centroidB.x-radiusB centroidB.y-radiusB 2*radiusB 2*radiusB];
    end
    %}
    
    %% Draw our information
    tElapsed=toc(tStart);
    if( tElapsed>tDisplay )
        %disp(tElapsed)
        tStart = tic;
        
        subplot(2,2,1);
        yuyv = sw.vcmImage.get_yuyv();
        rgb = yuyv2rgb( typecast(yuyv(:), 'uint32') );
        rgb = reshape(rgb,[80,120,3]);
        rgb = permute(rgb,[2 1 3]);
        imagesc( rgb );
        %disp('Received image.')
        
        subplot(2,2,2);
        labelA = sw.vcmImage.get_labelA();
        labelA = typecast( labelA, 'uint8' );
        labelA = reshape(  labelA, [80,60] );
        labelA = permute(  labelA, [2 1]   );
        imagesc(labelA);
        colormap(cmap);
        %disp('Received Label A.')
        
        subplot(2,2,3);
        % Draw the field for localization reasons
        plot_field();
        hold on;
        % plot robots
        for t = 1:length(teamNumbers)
            for p = 1:nPlayers
                if (~isempty(robots{p, t}))
                    plot_robot_struct(robots{p, t});
                end
            end
        end
        
        subplot(2,2,3);
        % What to draw here?
        
        drawnow;
    end
    
end
