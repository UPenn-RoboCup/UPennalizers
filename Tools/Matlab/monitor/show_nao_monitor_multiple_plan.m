function h=show_nao_monitor_single()
%This is new team monitor with logging and playback function

  global MONITOR LOGGER LUT;

  h.init=@init;
  h.update=@update;
  h.update_single=@update_single;
  h.update_team=@update_team;

  h.logging=0;
  h.lutname=0;

  h.fieldtype=1; %0,1,2 for SPL/Kid/Teen


  h.imagetype = 1; %YUYV 1 / labelA 2 / labelB 3
  h.mapmode = 1;
  h.fontsize = 7;  


  h.count = 0; %To kill non-responding players from view
  h.is_flip = 0;


  h.cost2_type = 0;


  COSTMAP = costmap();
 


  function init(target_fps)
    MONITOR.target_fps=target_fps;
    MONITOR.is_webots = 0;
    figure(1);   
    clf;
    set(gcf,'position',[1 1 1200 900]);
    MONITOR.hFpsText=uicontrol('Style','text','Units','Normalized', 'Position',[.40 0.97 0.20 0.03]);
    MONITOR.hButton1=uicontrol('Style','pushbutton','String','FPS -','Units','Normalized','Position',[.30 .97 .10 .03],'Callback',@button1);
    MONITOR.hButton2=uicontrol('Style','pushbutton','String','FPS +','Units','Normalized', 'Position',[.60 .97 .10 .03],'Callback',@button2);
    MONITOR.hButtonFlip=uicontrol('Style','pushbutton','String','Flip','Units','Normalized', 'Position',[.20 0.97 0.10 0.03],'Callback',@buttonFlip);

    MONITOR.mapAxe = axes('Units','Normalized','position',[0 0.03 0.5 0.47]);


    MONITOR.mapAxe = axes('position',[0.25 0.06 0.5 0.88], 'XTick', [], 'YTick', []);
    for i=1:5 
      MONITOR.costAxe(i)= axes('position',...
         [0.01, (i-1)*0.2+0.005,     0.2 0.2],'XTick',[],'YTick',[]);
      MONITOR.distAxe(i)= axes('position',...
         [0.76, (i-1)*0.2+0.005,     0.2 0.2],'XTick',[],'YTick',[]);
    end
    
    MONITOR.hButton3=uicontrol('Style','pushbutton','String','None','Units','Normalized','Position',[.00 .0 .10 .03],'Callback',@button3);


%{
    MONITOR.imageAxeT = axes('position',[0.5 0.52 0.3 0.45]);
    MONITOR.imageAxeB = axes('position',[0.5 0.03 0.3 0.45]);
    MONITOR.hDebugText=uicontrol('Style','text','Units','Normalized', 'Position',[0.8 0.03 0.2 0.94],'FontSize',MONITOR.fontsize);
    
    MONITOR.hButton3=uicontrol('Style','pushbutton','String','YUYV','Units','Normalized','Position',[.00 .0 .10 .03],'Callback',@button3);
    MONITOR.hButton4=uicontrol('Style','pushbutton','String','MAP1','Units','Normalized','Position',[.10 .0 .10 .03],'Callback',@button4);
%}
  end


  function update(robot,player2track)
    if MONITOR.target_fps==0.5 %Paused state
     set(MONITOR.hFpsText,'String','Paused');
     pause(1);
    else
     tStart = tic;       
     update_monitor(robot,player2track);
     drawnow;
     tElapsed=toc(tStart);
     set(MONITOR.hFpsText,'String',sprintf('Plot: %d ms FPS: %.1f / %.1f',	floor(tElapsed*1000),...
         min(1/tElapsed,MONITOR.target_fps), MONITOR.target_fps ));
     if(tElapsed<1/MONITOR.target_fps) pause( 1/MONITOR.target_fps-tElapsed ); end
    end
  end
  
  function update_monitor(robots,player2track)
    set(gcf,'CurrentAxes',MONITOR.mapAxe); 
    plot_field(gca,MONITOR.fieldtype);
    for i=1:length(player2track)
      robot = robots{player2track(i),1};
      r_struct = robot.get_team_struct();
      r_mon = robot.get_monitor_struct();
      set(gcf,'CurrentAxes',MONITOR.mapAxe); 
      plot_robot( r_struct, r_mon,1.5,MONITOR.mapmode,'' );
      plot_trajectory(r_mon,'ro');

      set(gcf,'CurrentAxes',MONITOR.costAxe(i));       
      plot_map(r_mon.robot.cost1);      

      set(gcf,'CurrentAxes',MONITOR.distAxe(i));       
      plot_map(r_mon.robot.dist);      
      plot_trajectory(r_mon,'ko');
    end
      
%{
    
    set(gcf,'CurrentAxes',MONITOR.cost2Axe); 
    plot_map(r_mon.robot.cost1);    
    plot_trajectory(r_mon,'ro');
    if MONITOR.is_flip>0 view(180, 90);
    else view(0, 90); end

    set(gcf,'CurrentAxes',MONITOR.distAxe); 
    plot_map(r_mon.robot.dist);
    plot_trajectory(r_mon,'ko');
    if MONITOR.is_flip>0 view(180, 90);
    else view(0, 90); end

    if( isempty(r_mon) ) disp('Empty monitor struct!'); return;  end
%}    


  end


  function plot_map(cost)
    cost2d = reshape(cost,[91 61]);
    surf([-4.5:0.1:4.5]-0.1,[-3:0.1:3]-0.1,cost2d','EdgeColor','none');%'
    axis(gca, [-5 5 -3.5 3.5]);
  end


  function plot_trajectory(r,marker)
    trajnum=r.robot.trajnum;
    traj_x = r.robot.traj_x([1:trajnum]);
    traj_y = r.robot.traj_y([1:trajnum]);

    hold on;
    %plot3( (traj_x-1)*0.1-4.5,(traj_y-1)*0.1-3,110*ones(size(traj_x)),marker);
    plot3( traj_x,traj_y,110*ones(size(traj_x)),marker);
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

    MONITOR.cost2_type = MONITOR.cost2_type+1;
    if MONITOR.cost2_type==1 
      set(MONITOR.hButton3,'String', 'Defend');
      COSTMAP.update_cost2(1);
    elseif MONITOR.cost2_type==2 
      set(MONITOR.hButton3,'String', 'Survivability');
      COSTMAP.update_cost2(2);
    elseif MONITOR.cost2_type==3 
      set(MONITOR.hButton3,'String', 'None');
      COSTMAP.update_cost2(0);      
      MONITOR.cost2_type=0;
    end
    
  %{
    MONITOR.imagetype = MONITOR.imagetype+1;
    if MONITOR.imagetype==2 
      set(MONITOR.hButton3,'String', 'LabelA');
    elseif MONITOR.imagetype==3 
      set(MONITOR.hButton3,'String', 'LabelB');
    else
      set(MONITOR.hButton3,'String', 'YUYV');
      MONITOR.imagetype = 1;
    end
    %}
    
  end

  function button4(varargin)
    MONITOR.mapmode=mod(MONITOR.mapmode+1,6);
    if MONITOR.mapmode==1 set(MONITOR.hButton4,'String', 'MAP1');
    elseif MONITOR.mapmode==2 set(MONITOR.hButton4,'String', 'MAP2');
    elseif MONITOR.mapmode==3 set(MONITOR.hButton4,'String', 'MAP3');
    elseif MONITOR.mapmode==4 set(MONITOR.hButton4,'String', 'PVIEW');
    elseif MONITOR.mapmode==5 set(MONITOR.hButton4,'String', 'OccVIEW');
    else set(MONITOR.hButton4,'String', 'MAP OFF');
      cla(MONITOR.h3);
    end
  end
  
  function buttonFlip(varargin)
    MONITOR.is_flip = 1- MONITOR.is_flip;
  end
end