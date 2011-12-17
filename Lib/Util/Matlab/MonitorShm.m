% Players and team to track
nPlayers = 1;
teamNumbers = [0 1];
team2track = 1;
player2track = 1;

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
        robots{p,t} = shm_robot(teamNumbers(t), p);
    end
end
t = toc( t0 );
fprintf('Initialization time: %f\n',t);

%% Update our plots
while continuous
    nUpdate = nUpdate + 1;

    %% Draw our information
    tStart = tic;
    show_monitor( robots, scale, team2track, player2track );
    drawnow;
    tElapsed=toc(tStart);

    if(tElapsed<tDisplay)
        pause( tDisplay-tElapsed );
    end

end
