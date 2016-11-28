function MonitorMotion(team,player)
  tFPS = 8; % Target FPS
  %%%%% Init SHM for robots
  t0=tic;
  robot=shm_robot_nao(1,1);
  t = toc( t0 );
  fprintf('Initialization time: %f\n',t);

  %% Enter loop

  nUpdate = 0;
  t0=tic;

  r=robot.get_motion_struct();
  t_last = r.t;

  dat=[];
  dat.t=[];
  dat.imuP=[];
  dat.imuR=[];

global MONITOR
MONITOR=show_motion_monitor();
MONITOR.init(r.t/1000);


  while 1
    MONITOR.update(robot);
    nUpdate = nUpdate + 1;
  end
end