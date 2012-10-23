function MonitorWireless(team,player)
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
  draw_team=2; %Wireless Team Monitor Mode

  %Check SHM for players
  if shm_check(team,player)>0 
    team_robots=shm_robot(team,player);
  else
    disp('Team/Player ID error!');
    return;
  end


  %% Init monitor display
  MONITOR=show_monitor();
  MONITOR.init(draw_team,tFPS);
  t = toc( t0 );
  fprintf('Initialization time: %f\n',t);

  %% Enter loop
  nUpdate = 0;
  while 1
    nUpdate = nUpdate + 1;
    MONITOR.update(team_robots,0,0,draw_team,0);
  end

  %% subfunction for checking the existnace of SHM
  function h = shm_check(team, player)
    %Checks the existence of shm with team and player ID
    shm_name_wcmRobot = sprintf('%s/wcmRobot%d%d%s', SHM_DIR, team, player, getenv('USER'));
    h = exist(shm_name_wcmRobot,'file');
  end

end
