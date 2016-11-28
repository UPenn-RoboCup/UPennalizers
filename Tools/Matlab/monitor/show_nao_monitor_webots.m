function h=show_new_monitor()
%This is new team monitor with logging and playback function

  global MONITOR LOGGER LUT;  
  global TEAM_LOG


  if isfield(TEAM_LOG,'count')==0
    TEAM_LOG=[];
    TEAM_LOG.count = 0;
    TEAM_LOG.viewcount = 1;
    TEAM_LOG.log_struct = {};
    TEAM_LOG.log_labelBT = {};
    TEAM_LOG.log_labelBB = {};
    TEAM_LOG.is_logging = 0;
  end

  h.init=@init;
  h.update=@update;
  h.update_single=@update_single;
  h.update_team=@update_team;

  h.logging=0;
  h.lutname=0;

  h.fieldtype=1; %0,1,2 for SPL/Kid/Teen
  h.count = 0; %To kill non-responding players from view
  h.timestamp=zeros(1,10);
  h.deadcount=zeros(1,10);

  h.disabled= zeros(1,10);
  h.robot_num = 10;

  h.is_flip = 0;
  h.is_webots = 1;
  h.gps_only = 0;


  function init(draw_team,target_fps)
    MONITOR.target_fps=target_fps;
    figure(1);
    MONITOR.teamnum = draw_team;
    clf;
    set(gcf,'position',[1 1 900 600]);

      MONITOR.robot_num = 5;
      MONITOR.enable10=2;  %Default 2
      MONITOR.hFpsText=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[.40 0.97 0.20 0.03]);
      MONITOR.hButton1=uicontrol('Style','pushbutton','String','FPS -',...
	'Units','Normalized','Position',[.30 .97 .10 .03],'Callback',@button1);
      MONITOR.hButton2=uicontrol('Style','pushbutton','String','FPS +',...
	'Units','Normalized', 'Position',[.60 .97 .10 .03],'Callback',@button2);
     
      MONITOR.hButtonFlip=uicontrol('Style','pushbutton','String','Flip',...
	'Units','Normalized', 'Position',[.10 0.97 0.20 0.03],'Callback',@buttonFlip);




      MONITOR.hButton4=uicontrol('Style','pushbutton','String','Start',...
	'Units','Normalized', 'Position',[.25 .01 .07 .05],'Callback',@button4);
      MONITOR.hButton5=uicontrol('Style','pushbutton','String','Save',...
	'Units','Normalized', 'Position',[.32 .01 .07 .05],'Callback',@button5);

      MONITOR.hButton6=uicontrol('Style','pushbutton','String','<<',...
	'Units','Normalized', 'Position',[.39 .01 .07 .05],'Callback',@button6);
      MONITOR.hButton7=uicontrol('Style','pushbutton','String','<',...
	'Units','Normalized', 'Position',[.46 .01 .07 .05],'Callback',@button7);

      MONITOR.hButton10=uicontrol('Style','pushbutton','String','',...
	'Units','Normalized', 'Position',[.53 .01 .07 .05]);

      MONITOR.hButton8=uicontrol('Style','pushbutton','String','>',...
	'Units','Normalized', 'Position',[.60 .01 .07 .05],'Callback',@button8);
      MONITOR.hButton9=uicontrol('Style','pushbutton','String','>>',...
	'Units','Normalized', 'Position',[.67 .01 .07 .05],'Callback',@button9);



      %MONITOR.mainAxe = axes('position',[0.05 0.06 0.7 0.88], 'XTick', [], 'YTick', []);
      MONITOR.mainAxe = axes('position',[0.25 0.06 0.5 0.88], 'XTick', [], 'YTick', []);
      for i=1:3
        MONITOR.labelAxeB(i) = axes('position',...
	       [0.01, (i-1)*0.33+0.005,     0.12 0.15],'XTick',[],'YTick',[]);
        MONITOR.labelAxeT(i) = axes('position',...
         [0.01, (i-1)*0.33+0.16,     0.12 0.15],'XTick',[],'YTick',[]);

        MONITOR.infoTexts(i)=uicontrol('Style','text',...
  	     'Units','Normalized', 'Position',...
  	     [0.13, (i-1)*0.33+0.005,     0.07 0.31]);
      end

      for i=4:6
        MONITOR.labelAxeB(i) = axes('position',...
         [0.80, (i-4)*0.33+0.005,     0.12 0.15], 'XTick',[],'YTick',[]);
        MONITOR.labelAxeT(i) = axes('position',...
         [0.80, (i-4)*0.33+0.16,     0.12 0.15],'XTick',[],'YTick',[]);

        MONITOR.infoTexts(i)=uicontrol('Style','text',...
         'Units','Normalized', 'Position',...
         [0.92, (i-4)*0.33+0.005,     0.07 0.31]);
      end
  end


  function update(robots,player2track)
    if MONITOR.target_fps==0.5 %Paused state
       set(MONITOR.hFpsText,'String','Paused');
       pause(1);
    else
       tStart = tic;
       log_team_wireless(robots,player2track);
       draw_team_wireless(TEAM_LOG.viewcount);
       drawnow;
       tElapsed=toc(tStart);
       set(MONITOR.hFpsText,'String',...
  	 sprintf('Plot: %d ms FPS: %.1f / %.1f',	floor(tElapsed*1000),...
         min(1/tElapsed,MONITOR.target_fps), MONITOR.target_fps ));
       if(tElapsed<1/MONITOR.target_fps)
         pause( 1/MONITOR.target_fps-tElapsed );
       end
    end
  end

  function log_team_wireless(robot_team,player2track)
    if (TEAM_LOG.is_logging ==1)||(TEAM_LOG.count==0)
      TEAM_LOG.count = TEAM_LOG.count + 1;
      MONITOR.count = MONITOR.count + 1;
    end
    if TEAM_LOG.is_logging==1 
      TEAM_LOG.viewcount = TEAM_LOG.count;
    end

    set(MONITOR.hButton10,'String', sprintf('%d/%d',...
 	  TEAM_LOG.viewcount, TEAM_LOG.count));
    TEAM_LOG.log_struct{TEAM_LOG.count} = {};
    TEAM_LOG.log_labelB{TEAM_LOG.count} = {};

    for i=1:6
      TEAM_LOG.log_struct{TEAM_LOG.count}{i}=[];
      TEAM_LOG.log_struct{TEAM_LOG.count}{i}.id = 0;
    end

    for i=1:size(player2track,2)
      robot = robot_team{player2track(i)};
      r_struct = robot.get_team_struct();
      if r_struct.id>0
        timepassed = r_struct.time-MONITOR.timestamp(i);
        MONITOR.timestamp(i)=r_struct.time;
        if timepassed==0 MONITOR.deadcount(i) = MONITOR.deadcount(i)+1;
        else MONITOR.deadcount(i) = 0; 
        end
        deadcount_threshold = 50;
        gps_only = r_struct.gps_only;
        if gps_only==1 
          MONITOR.gps_only = 1; 
%          disp('GPS ONLY');
        end
        if MONITOR.deadcount(i)<deadcount_threshold 
          TEAM_LOG.log_struct{TEAM_LOG.count}{i}=r_struct;
          if MONITOR.gps_only==0
            TEAM_LOG.log_labelBT{TEAM_LOG.count}{i}=robot.get_labelB(1);
            TEAM_LOG.log_labelBB{TEAM_LOG.count}{i}=robot.get_labelB(2);
          end
        end
      end
     end
  end

  function draw_team_wireless(count)
    set(gcf,'CurrentAxes',MONITOR.mainAxe);
    cla;
    hold on;
    plot_field(MONITOR.mainAxe,MONITOR.fieldtype);
    hold on;
    for i=1:MONITOR.robot_num
      r_struct = TEAM_LOG.log_struct{count}{i};
      if r_struct.id>0
        set(gcf,'CurrentAxes',MONITOR.mainAxe);
        plot_robot( r_struct, [],2,5,r_struct.robotName);
        updated = 0;

%TODO: set(gcf,'CurrentAxes',newaxe) should be used instead

        if MONITOR.gps_only==0
          labelBT = TEAM_LOG.log_labelBT{count}{i};
          labelBB = TEAM_LOG.log_labelBB{count}{i};
          set(gcf,'CurrentAxes',MONITOR.labelAxeT(i));
          plot_label(labelBT);
          plot_overlay_wireless(r_struct);
          set(gcf,'CurrentAxes',MONITOR.labelAxeB(i));
          plot_label(labelBB);
        end
%        plot_overlay_wireless(r_struct);

        if isfield(r_struct,'bodyState')
        bodyState = r_struct.bodyState;
        else bodyState = 'Undefined';
        end

        [infostr textcolor]=robot_info(...
      		r_struct,[],3,r_struct.robotName, bodyState);
        set(MONITOR.infoTexts(i),'String',infostr);
        MONITOR.disabled(i)=0;
      else
	     if MONITOR.disabled(i)==0 
          set(gcf,'CurrentAxes',MONITOR.labelAxeT(i));
          plot_label([0 0;0 0]);
          set(gcf,'CurrentAxes',MONITOR.labelAxeB(i));
          plot_label([0 0;0 0]);
	     MONITOR.disabled(i)=1;
	     end
      end
    end
    hold off;
  end


  function button1(varargin)
    %0.5fps means paused state
    MONITOR.target_fps=max(0.5,MONITOR.target_fps/2);
  end
  function button2(varargin)
    MONITOR.target_fps=min(32,MONITOR.target_fps*2);
  end
  function button3(varargin)
  end

  function button4(varargin)
    if TEAM_LOG.is_logging==0 
      TEAM_LOG.is_logging =1;
      set(MONITOR.hButton4,'String', 'Stop');
    else
      TEAM_LOG.is_logging =0;
      set(MONITOR.hButton4,'String', 'Start');
    end
  end
  function button5(varargin)
    savefile1 = ['./logs/teamlog_' datestr(now,30) '.mat'];
    fprintf('\nSaving team log file: %s...', savefile1)
    save(savefile1, 'TEAM_LOG'); 
    disp('Done');
  end
  function button6(varargin)
    TEAM_LOG.is_logging = 0;
    TEAM_LOG.viewcount = max(1,TEAM_LOG.viewcount - 10);
    set(MONITOR.hButton4,'String', 'Start');
  end
  function button7(varargin)
    TEAM_LOG.is_logging = 0;
    TEAM_LOG.viewcount = max(1,TEAM_LOG.viewcount - 1);
    set(MONITOR.hButton4,'String', 'Start');
  end
  function button8(varargin)
    TEAM_LOG.is_logging = 0;
    TEAM_LOG.viewcount = min(TEAM_LOG.count,TEAM_LOG.viewcount + 1);
    set(MONITOR.hButton4,'String', 'Start');
  end
  function button9(varargin)
    TEAM_LOG.is_logging = 0;
    TEAM_LOG.viewcount = min(TEAM_LOG.count,TEAM_LOG.viewcount + 10);
    set(MONITOR.hButton4,'String', 'Start');
  end

  function buttonFlip(varargin)
    MONITOR.is_flip = 1- MONITOR.is_flip;
    if MONITOR.is_flip>0 
      set(MONITOR.mainAxe, 'XDir', 'reverse');
      set(MONITOR.mainAxe, 'YDir', 'reverse');
    else
      set(MONITOR.mainAxe, 'XDir', 'normal');
      set(MONITOR.mainAxe, 'YDir', 'normal');
    end

    disp('FLIP')
  end


end
