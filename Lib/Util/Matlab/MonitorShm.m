function MonitorShm(teamNumbers, nPlayers, dispDir)

  if (nargin < 2)
    nPlayers = 4;
  end
  if (nargin < 3)
    dispDir = 'y';
  end

  % create shm wrappers
  user = getenv('USER');
  shmWrappers = cell(nPlayers, length(teamNumbers));
  for t = 1:length(teamNumbers)
    for p = 1:nPlayers
      sw = [];
      sw.gcmTeam = shm(sprintf('gcmTeam%d%d%s', teamNumbers(t), p, user));
      sw.wcmRobot = shm(sprintf('wcmRobot%d%d%s', teamNumbers(t), p, user));
      sw.wcmBall = shm(sprintf('wcmBall%d%d%s', teamNumbers(t), p, user));
      shmWrappers{p,t} = sw;
    end
  end

  robots = cell(nPlayers, length(teamNumbers));

  nUpdate = 0;

  localization_plot = plot_localization();

  while (1)
    nUpdate = nUpdate + 1;

    % get latest shm data
    for t = 1:length(teamNumbers)
      for p = 1:nPlayers
        robots{p, t} = shm2teammsg(shmWrappers{p,t}.gcmTeam, ...
                                    shmWrappers{p,t}.wcmRobot, ...
                                    shmWrappers{p,t}.wcmBall);
      end
    end

    localization_plot.update(robots); 

    pause(0.05);
  end


end
