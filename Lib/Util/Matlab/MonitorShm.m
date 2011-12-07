clear all;
% Players and team to track
nPlayers = 2;
teamNumbers = [1];
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
robots = cell(nPlayers, length(teamNumbers));
for t = 1:length(teamNumbers)
    for p = 1:nPlayers
        robots{p,t} = shm_robot(teamNumbers(t), p);
    end
end

%% Update our plots
while continuous
    nUpdate = nUpdate + 1;
    
    %% Draw our information
    tElapsed=toc(tStart);
    if( tElapsed>tDisplay )
        tStart = tic;
        % Show the monitor
        show_monitor2( robots, scale, team2track, player2track );
        drawnow;
    end
    
end
