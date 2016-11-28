function h=show_nao_monitor_single()
%This is new team monitor with logging and playback function

  global MONITOR LOGGER LUT;  
  
  h.init=@init;
  h.update=@update;
  h.update_single=@update_single;
  h.update_team=@update_team;

  h.logging=0;
  h.lutname=0;




  h.imagetype = 1; %YUYV 1 / labelA 2 / labelB 3
  h.fieldtype=2; %1 for SPL, 2 for grasp 
  h.mapmode = 2;
  h.fontsize = 7;  


  h.count = 0; %To kill non-responding players from view
  h.is_flip = 0;
  h.is_webots = 0;


  function init(target_fps)
    MONITOR.target_fps=target_fps;
    MONITOR.is_webots = 0;
    figure(1);   
    clf;
    set(gcf,'position',[1 1 1200 900]);
    MONITOR.hFpsText=uicontrol('Style','text','Units','Normalized', 'Position',[.40 0.97 0.20 0.03]);
    MONITOR.hButton1=uicontrol('Style','pushbutton','String','FPS -','Units','Normalized','Position',[.30 .97 .10 .03],'Callback',@button1);
    MONITOR.hButton2=uicontrol('Style','pushbutton','String','PAUSE','Units','Normalized', 'Position',[.60 .97 .10 .03],'Callback',@button15);
    MONITOR.hButton2=uicontrol('Style','pushbutton','String','FPS +','Units','Normalized', 'Position',[.70 .97 .10 .03],'Callback',@button2);
    

    MONITOR.hButtonWebots=uicontrol('Style','pushbutton','String','Webots','Units','Normalized', 'Position',[.05 0.97 0.10 0.03],'Callback',@buttonWebots);

    MONITOR.mapAxe = axes('Units','Normalized','position',[0 0.03 0.5 0.94]);

    MONITOR.imageAxeT = axes('position',[0.5 0.52 0.3 0.45]);
    MONITOR.hButton3=uicontrol('Style','pushbutton','String','YUYV','Units','Normalized','Position',[.5 .48 .10 .04],'Callback',@button3);    
    MONITOR.imageAxeB = axes('position',[0.5 0.03 0.3 0.45]);

    MONITOR.hDebugText=uicontrol('Style','text','Units','Normalized', 'Position',[0.8 0.03 0.2 0.94],'FontSize',MONITOR.fontsize);
    MONITOR.hButtonText1=uicontrol('Style','pushbutton','String','-','Units','Normalized','Position',[0.8 0 0.1 0.03],'Callback',@buttonText1);
    MONITOR.hButtonText2=uicontrol('Style','pushbutton','String','+','Units','Normalized','Position',[0.9 0 0.1 0.03],'Callback',@buttonText2);


    
    MONITOR.hButton4=uicontrol('Style','pushbutton','String','MAP2','Units','Normalized','Position',[.10 .0 .10 .03],'Callback',@button4);
    MONITOR.hButtonFlip=uicontrol('Style','pushbutton','String','Flip','Units','Normalized', 'Position',[.20 0 0.10 0.03],'Callback',@buttonFlip);
    MONITOR.hButtonField=uicontrol('Style','pushbutton','String','Grasp','Units','Normalized', 'Position',[.30 0 0.10 0.03],'Callback',@buttonField);
  end


  function update(robot)
    if MONITOR.target_fps==0.5 %Paused state
     set(MONITOR.hFpsText,'String','Paused');
     pause(1);
    else
     tStart = tic;       
     update_monitor(robot);
     drawnow;
     tElapsed=toc(tStart);
     set(MONITOR.hFpsText,'String',sprintf('Plot: %d ms FPS: %.1f / %.1f',	floor(tElapsed*1000),...
         min(1/tElapsed,MONITOR.target_fps), MONITOR.target_fps ));
     if(tElapsed<1/MONITOR.target_fps) pause( 1/MONITOR.target_fps-tElapsed ); end
    end
  end
  
  function update_monitor(robot)
    r_struct = robot.get_team_struct();
    r_mon = robot.get_monitor_struct();

    set(gcf,'CurrentAxes',MONITOR.mapAxe);
    plot_field(gca,MONITOR.fieldtype);
    plot_robot( r_struct, r_mon,1.5,MONITOR.mapmode,'' );
    if MONITOR.is_flip>0 
      view(-90, 90);
    else
      view(90, 90);
    end
    

    if( isempty(r_mon) ) disp('Empty monitor struct!'); return;  end

    if MONITOR.imagetype==1 
      h.imagetype = 1; %YUYV 1 / labelA 2 / labelB 3
      yuyv_type = r_mon.yuyv_type;
      if MONITOR.is_webots
        yuyvT=robot.get_yuyv(1);
        yuyvB=robot.get_yuyv(2);
        overlay_mul = 2;
      elseif yuyv_type==1
        yuyvT=robot.get_yuyv(1);
        yuyvB=robot.get_yuyv(2);
        overlay_mul = 1;
      elseif yuyv_type==2
        yuyvT=robot.get_yuyv2(1);
        yuyvB=robot.get_yuyv2(2);
        overlay_mul = 2;
      elseif yuyv_type==3
        yuyvT=robot.get_yuyv3(1);
        yuyvB=robot.get_yuyv3(2);
        overlay_mul = 4;
      else return; end

      set(gcf,'CurrentAxes',MONITOR.imageAxeT);
      plot_yuyv(yuyvT);
      plot_overlay(r_mon,overlay_mul,1,1);    
      set(gcf,'CurrentAxes',MONITOR.imageAxeB);
      plot_yuyv(yuyvB);
      plot_overlay(r_mon,overlay_mul,1,2);
    else
      if MONITOR.imagetype==2
        labelT = robot.get_labelA(1);
        labelB = robot.get_labelA(2);
        overlay_mul = 1; 
      else
        labelT = robot.get_labelB(1);
        labelB = robot.get_labelB(2);
        overlay_mul = r_mon.camera.scaleBtop;
      end

% We have big scaleB issue everywhere
%TODO: automatically calculate overlay multiplier!!!!!!!
      
      if length(overlay_mul)==1 
        overlay_mul=[overlay_mul overlay_mul];
      end


      set(gcf,'CurrentAxes',MONITOR.imageAxeT);
      plot_label(labelT);
      plot_overlay(r_mon,overlay_mul(1),2,1);    

      set(gcf,'CurrentAxes',MONITOR.imageAxeB);
      plot_label(labelB);
      plot_overlay(r_mon,overlay_mul(2),2,2);

    end
    
    debugmsg='';
    if isfield(r_mon,'debugtop') debugmsg=[debugmsg r_mon.debugtop.message];  end
    if isfield(r_mon,'debugbtm') debugmsg=[debugmsg r_mon.debugbtm.message];  end
    set(MONITOR.hDebugText,'String',debugmsg);

  end


  function button1(varargin)
    %0.5fps means paused state
    MONITOR.target_fps=max(0.5,MONITOR.target_fps/2);
  end
  function button15(varargin)
    %0.5fps means paused state
    if MONITOR.target_fps==0.5 
      MONITOR.target_fps = 8;
    else
      MONITOR.target_fps=0.5;
    end
  end
  function button2(varargin)
    MONITOR.target_fps=min(32,MONITOR.target_fps*2);
  end
  function button3(varargin)
    MONITOR.imagetype = MONITOR.imagetype+1;
    if MONITOR.imagetype==2 
      set(MONITOR.hButton3,'String', 'LabelA');
    elseif MONITOR.imagetype==3 
      set(MONITOR.hButton3,'String', 'LabelB');
    else
      set(MONITOR.hButton3,'String', 'YUYV');
      MONITOR.imagetype = 1;
    end
  end

  function button4(varargin)
    MONITOR.mapmode=MONITOR.mapmode+1;
    if MONITOR.mapmode==5 MONITOR.mapmode = 2;end
    if MONITOR.mapmode==2 set(MONITOR.hButton4,'String', 'MAP2');
    elseif MONITOR.mapmode==3 set(MONITOR.hButton4,'String', 'MAP3');
    elseif MONITOR.mapmode==4 set(MONITOR.hButton4,'String', 'PVIEW');
    else set(MONITOR.hButton4,'String', 'MAP OFF');
      cla(MONITOR.h3);
    end
  end
  
  function buttonFlip(varargin)
    MONITOR.is_flip = 1- MONITOR.is_flip;
  end
  function buttonText1(varargin)
    MONITOR.fontsize = max(7,MONITOR.fontsize-1);      
    set(MONITOR.hDebugText,'FontSize',MONITOR.fontsize);
  end
  function buttonText2(varargin)
    MONITOR.fontsize = min(15,MONITOR.fontsize+1);      
    set(MONITOR.hDebugText,'FontSize',MONITOR.fontsize);
  end
  function buttonWebots(varargin)
    MONITOR.is_webots = 1- MONITOR.is_webots;
  end
  function buttonField(varargin)
    if MONITOR.fieldtype==2 
      MONITOR.fieldtype=1;
      set(MONITOR.hButtonField,'String', 'SPL');
    else
      MONITOR.fieldtype=2;
      set(MONITOR.hButtonField,'String', 'Grasp');
    end
  end

end
