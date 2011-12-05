function MonitorShm(teamNumbers, nPlayers, dispDir)
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

  while (1)
    nUpdate = nUpdate + 1;

    % get latest shm data
    for t = 1:length(teamNumbers)
      for p = 1:nPlayers
        robots{p, t} = shm2teammsg(shmWrappers{p,t}.gcmTeam, shmWrappers{p,t}.wcmRobot, shmWrappers{p,t}.wcmBall);
      end
    end

    % plot current robot positions
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

    if (dispDir == 'y')
      set(gca, 'CameraUpVector', [1, 0, 0]);
    elseif (dispDir == 'b' || dispDir == 'c')
      set(gca, 'CameraUpVector', [-1, 0, 0]);
    end

    drawnow;

  end


end
