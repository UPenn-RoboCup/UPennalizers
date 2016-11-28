function MonitorWebots()
%-----------------------------------------------------
%
%  Monitor for wireless robot team monitoring
%  Usage:  MonitorWireless
%
%-----------------------------------------------------

  global MONITOR LOGGER SHM_DIR_LINUX SHM_DIR_OSX

  if ismac == 1
    SHM_DIR='/tmp/boost_interprocess';  
  elseif isunix == 1
    SHM_DIR='/dev/shm';
  end

  team=1;
  player=1;

  tFPS = 4; % Target FPS
  dInterval = 5; %Vision update interval for team view

  %%%%% Init SHM for robots
  t0=tic;

  max_player_id = 6;
  team2track = 1;

  robots=cell(max_player_id,1);
  %Search SHM for players
  player2track=[];
  for i=1:max_player_id,
    if shm_check(team2track,i)>0
      robots{i,1}=shm_robot_nao(team2track,i);
      player2track=[player2track i];
    end
  end
  if isempty(player2track)
    disp('Team/Player ID error!');
    return;
  end
  draw_team=1;

  %% Init monitor display
  MONITOR=show_nao_monitor_webots();
  MONITOR.init(draw_team,tFPS);
  t = toc( t0 );
  fprintf('Initialization time: %f\n',t);

  %% Enter loop
  nUpdate = 0;
  while 1
    nUpdate = nUpdate + 1;
    MONITOR.update(robots,player2track);
  end

  %% subfunction for checking the existnace of SHM
  function h = shm_check(team, player)
    %Checks the existence of shm with team and player ID
    shm_name_wcmRobot = sprintf('%s/wcmRobot%d%d%s', SHM_DIR, team, player, getenv('USER'));
    h = exist(shm_name_wcmRobot,'file');
  end

end
