function MonitorNaoSingle(team,player)
%-----------------------------------------------------
%
%  Usage: Monitor(1,2)       : single monitor
%
%-----------------------------------------------------

global MONITOR

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

if nargin==2  %2 args... track specified player (for webots)
  team2track=team;player2track=player;  % somehow needs a shift by 1
else %Track actual robot using default team/player value
  %Default value is 1,1
  %listen_monitor and listen_team_monitor saves to this SHM
  team2track = 1;player2track = 1;
end

if shm_check(team2track,player2track)==0
  disp('Team/Player ID error!');
  return;
end
robot=shm_robot_nao(team2track,player2track);



%% Init monitor display
MONITOR=show_nao_monitor_single();
MONITOR.init(tFPS);
if nargin==2 MONITOR.is_webots =1;end 
t = toc( t0 );
fprintf('Initialization time: %f\n',t);

%% Enter loop

%% Update our plots
nUpdate = 0;
while 1
  nUpdate = nUpdate + 1;
  MONITOR.update(robot);
end

%% subfunction for checking the existnace of SHM
  function h = shm_check(team, player)
    %Checks the existence of shm with team and player ID
    shm_name_wcmRobot = sprintf('%s/wcmRobot%d%d%s', SHM_DIR, team, player, getenv('USER'));
    h = exist(shm_name_wcmRobot,'file');
  end
end