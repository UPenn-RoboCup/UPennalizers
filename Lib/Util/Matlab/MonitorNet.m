% Players and team to track
nPlayers = 3;
teamNumbers = [18];
team2track = 1;
player2track = 2;

% Should monitor run continuously?
continuous = 1;

%% Enter loop
figure(1);
clf;
tDisplay = .2; % Display every x seconds
tStart = tic;
nUpdate = 0;
scale = 1; % 1: labelA, 4: labelB

%% Initialize data
t0=tic;
robots = cell(nPlayers, length(teamNumbers));
for t = 1:length(teamNumbers)
    for p = 1:nPlayers
        robots{p,t} = net_robot(teamNumbers(t), p);
    end
end
t = toc( t0 );
fprintf('Initialization time: %f\n',t);

%% Update our plots
while continuous
    nUpdate = nUpdate + 1;
    
    %% Draw our information
    tElapsed=toc(tStart);
    if( tElapsed>tDisplay )
        tStart = tic;
        % Show the monitor
        show_monitor( robots, scale, team2track, player2track );
        drawnow;
    end
    
    %% Update our information
    if(monitorComm('getQueueSize') > 0)
        msg = monitorComm('receive');
        if ~isempty(msg)
            msg = lua2mat(char(msg));
            % Only track one robot...
            scale = robots{player2track,team2track}.update( msg );
        end
    end
    
end
