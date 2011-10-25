function MonitorTeam(teamNumber, nPlayers, dispDir)

  if (nargin < 1)
    teamNumber = 26;
  end
  if (nargin < 2)
    nPlayers = 4;
  end
  if (nargin < 3)
    dispDir = 'y';
  end


  robots = cell(2, nPlayers);

  nUpdate = 0;

  localization_plot = plot_localization();

  while (1)
    nUpdate = nUpdate + 1;

    % receive UDP packets
    while(naoComm('getQueueSize') > 0)
      msg = naoComm('receive');
      if ~isempty(msg)
        try
          % convert lua serialized data to matlab struct
          msg = lua2mat(char(msg));
          msg.tReceive = time;
          if (isfield(msg, 'teamNumber') && msg.teamNumber == teamNumber)
            robots{msg.id} = msg;
          end
        catch
          disp('failed to parse')
          disp(char(msg))
        end
      end
    end

    % time out messages after 10 seconds
    for i = 1:nPlayers
      if (~isempty(robots{i}))
        if (robots{i}.tReceive - time > 10)
          robots{i} = [];
        end
      end
    end
          
  end

end
