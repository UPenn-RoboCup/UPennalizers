function ret = LoggerShm(teamNumber, playerID)
  
if nargin < 2
  playerID  = 1;
  teamNumber = 1;
end

global LOGGER MONITOR

LOGGER=logger();
LOGGER.init();


% create shm interface
robot = shm_robot(teamNumber, playerID);

% camera number
ncamera = 1; %robot.vcmCamera.get_ncamera();

% init window
figure(1);
if ncamera == 2
	set(gcf, 'position', [1, 1, 1200, 400]);
end
clf;


MONITOR=[];
MONITOR.target_fps=16;
MONITOR.logging = 0;

%FPS button and text 
MONITOR.hFpsText=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[.30 0.93 0.40 0.04]);

MONITOR.hButton6=uicontrol('Style','pushbutton','String','FPS -',...
	'Units','Normalized','Position',[.20 .93 .10 .04],'Callback',@button6);

MONITOR.hButton7=uicontrol('Style','pushbutton','String','FPS +',...
  'Units','Normalized', 'Position',[.70 .93 .10 .04],'Callback',@button7);

% Log Button
MONITOR.hButton11 = uicontrol('Style','pushbutton','String','LOG',...
	'Position',[20 50 70 40],'Callback',@button11);

while (1)
  tic;
  r_mon=robot.get_monitor_struct();
%	subplot(1,2,r_mon.camera.select+1);
  yuyv_type = r_mon.yuyv_type;
 	if yuyv_type==1
   	  yuyv = robot.get_yuyv();
%			disp('Got yuyv');
     	plot_yuyv(yuyv);
  elseif yuyv_type==2
 	    yuyv = robot.get_yuyv2();
%			disp('Got yuyv2');
			plot_yuyv(yuyv);
 	elseif yuyv_type==3
   	  yuyv = robot.get_yuyv3();
%			disp('Got yuyv3');
			plot_yuyv(yuyv);
	else 
		continue;
 	end
	drawnow;	


  if MONITOR.logging
    LOGGER.log_data(yuyv + 0,r_mon);
    logstr=sprintf('%d/100',LOGGER.log_count);
    set(MONITOR.hButton11,'String', logstr);
    if LOGGER.log_count==100 
      LOGGER.save_log();
    end
  end

  tPassed=toc;

   set(MONITOR.hFpsText,'String',...
     sprintf('Plot: %d ms FPS: %.1f / %.1f',	floor(tPassed*1000),...
     min(1/tPassed,MONITOR.target_fps), MONITOR.target_fps ));


  if tPassed<1/MONITOR.target_fps
    pause(1/MONITOR.target_fps-tPassed);
  end
end

  function button6(varargin)
    %0.5fps means paused state
    MONITOR.target_fps=max(0.5,MONITOR.target_fps/2);
  end

  function button7(varargin)
    MONITOR.target_fps=min(32,MONITOR.target_fps*2);
  end

  function button11(varargin)
    MONITOR.logging=1-MONITOR.logging;
  end


end
