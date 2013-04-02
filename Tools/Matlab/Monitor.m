function Monitor(team,player)
%-----------------------------------------------------
%
%  Usage: Monitor(1,2)       : single monitor
%         Monitor(1,[2 3 4]) : team monitor
%  	  		Monitor(1)         : team auto-detect
%
%-----------------------------------------------------

  global MONITOR LOGGER SHM_DIR_LINUX SHM_DIR_OSX

  if ismac == 1
    SHM_DIR='/tmp/boost_interprocess';  
  elseif isunix == 1
    SHM_DIR='/dev/shm';
  end

  tFPS = 8; % Target FPS
  dInterval = 5; %Vision update interval for team view
  dInterval = 1; 

%%%%% Init SHM for robots
  t0=tic;

  max_player_id = 5; 
  draw_team = 0;
  if nargin==1
    %1 args.. track the whole players in the team
    team2track=team;
    robots = cell(max_player_id, 1);

    %Search SHM for players
    player2track=[];
    for i=1:max_player_id,
      if shm_check(team2track,i)>0 
        robots{i,1}=shm_robot(team2track,i);
	player2track=[player2track i];
      end
    end
    if length(player2track)==0
      disp('Team/Player ID error!');
      return;
    end
    draw_team=1;
  else
    if nargin==2  %2 args... track specified player 
      team2track=team;player2track=player;
    else
      %Default value is 1,1 
      %listen_monitor and listen_team_monitor saves to this SHM
      team2track = 1;player2track = 1;
    end
    if length(player2track)>1, draw_team=1; end
    for i=1:length(player2track)
      if shm_check(team2track,player2track(i))==0 
        disp('Team/Player ID error!');
        return;
      end
      robots{player2track(i),1}=shm_robot(team2track,player2track(i));
    end
  end

%% Init monitor display

  MONITOR=show_monitor();
  MONITOR.init(draw_team,tFPS);
  t = toc( t0 );
  fprintf('Initialization time: %f\n',t);

%% Enter loop

  %% Update our plots
  nUpdate = 0;
  while 1
    nUpdate = nUpdate + 1;
    MONITOR.update( robots, 1 , player2track,...
	 draw_team, mod(nUpdate,dInterval));
  end

%% subfunction for checking the existnace of SHM
  function h = shm_check(team, player)
    %Checks the existence of shm with team and player ID
    shm_name_wcmRobot = sprintf('%s/wcmRobot%d%d%s', SHM_DIR, team, player, getenv('USER'));
    h = exist(shm_name_wcmRobot,'file');
  end

end
