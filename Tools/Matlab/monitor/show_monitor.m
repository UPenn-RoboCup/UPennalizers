function h=show_monitor()
  global MONITOR LOGGER LUT;  

  h.init=@init;
  h.update=@update;
  h.update_single=@update_single;
  h.update_team=@update_team;

  %Five screen for single monitor
  h.enable0=1;
  h.enable1=1;
  h.enable2=1;
  h.enable3=1;
  h.enable4=1;
  h.enable5=1;

  %two subscreen for team monitor
  h.enable8=0;   %Label mode, 1/2/0
  h.enable9=1;   %Label mode, 1/0
  h.enable10=1;  %Map mode, 1/2/3

  h.logging=0;
  h.lutname=0;
  h.is_webots=0;

  h.fieldtype=0; %0,1,2 for SPL/Kid/Teen

  h.count = 0; %To kill non-responding players from view
 
  h.timestamp=zeros(1,10);
  h.deadcount=zeros(1,10);

  % subfunctions

  function init(draw_team,target_fps)
    MONITOR.target_fps=target_fps;
    figure(1);
    clf;


    % Single team wireless monitor
    if draw_team==3 

      set(gcf,'position',[1 1 900 700]);

      MONITOR.enable10=2;  %Default 2

      MONITOR.hFpsText=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[.40 0.93 0.20 0.04]);

      MONITOR.hButton6=uicontrol('Style','pushbutton','String','FPS -',...
	'Units','Normalized','Position',[.30 .93 .10 .04],'Callback',@button6);

      MONITOR.hButton7=uicontrol('Style','pushbutton','String','FPS +',...
	'Units','Normalized', 'Position',[.60 .93 .10 .04],'Callback',@button7);

      MONITOR.hButton13=uicontrol('Style','pushbutton','String','Kidsize',...
	'Units','Normalized', 'Position',[.02 .56 .07 .07],'Callback',@button13);

      for i=1:5
        MONITOR.infoTexts(i)=uicontrol('Style','text','FontSize',16,...
	'Units','Normalized', 'Position',[0.92 0.94-0.17*i 0.08 0.15]);
      end

    elseif draw_team==2 % Multiple robot, wireless monitoring (real robots)
      set(gcf,'position',[1 1 900 900]);

      MONITOR.enable10=2;  %Default 2

      MONITOR.hFpsText=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[.40 0.93 0.20 0.04]);

      MONITOR.hButton6=uicontrol('Style','pushbutton','String','FPS -',...
	'Units','Normalized','Position',[.30 .93 .10 .04],'Callback',@button6);

      MONITOR.hButton7=uicontrol('Style','pushbutton','String','FPS +',...
	'Units','Normalized', 'Position',[.60 .93 .10 .04],'Callback',@button7);

      MONITOR.hButton13=uicontrol('Style','pushbutton','String','Kidsize',...
	'Units','Normalized', 'Position',[.02 .56 .07 .07],'Callback',@button13);

      for i=1:5
        MONITOR.infoTexts(i)=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[0.16*(i-1)+0.12 0.71 0.145 0.08]);
      end

      for i=6:10
        MONITOR.infoTexts(i)=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[0.16*(i-6)+0.12 0.01 0.145 0.08]);
      end


    elseif draw_team==1 %Multiple robot full monitoring (webots)
      set(gcf,'position',[1 1 900 900]);

      MONITOR.hFpsText=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[.40 0.93 0.20 0.04]);

      MONITOR.hButton6=uicontrol('Style','pushbutton','String','FPS -',...
	'Units','Normalized','Position',[.30 .93 .10 .04],'Callback',@button6);

      MONITOR.hButton7=uicontrol('Style','pushbutton','String','FPS +',...
	'Units','Normalized', 'Position',[.60 .93 .10 .04],'Callback',@button7);

      MONITOR.hButton8=uicontrol('Style','pushbutton','String','OFF',...
	'Units','Normalized','Position',[.02 .30 .07 .07],'Callback',@button8);

      MONITOR.hButton9=uicontrol('Style','pushbutton','String','2D',...
	'Units','Normalized','Position',[.02 .23 .07 .07],'Callback',@button9);

      MONITOR.hButton10=uicontrol('Style','pushbutton','String','MAP1',...
	'Units','Normalized','Position',[.02 .63 .07 .07],'Callback',@button10);

      MONITOR.hButton13=uicontrol('Style','pushbutton','String','Kidsize',...
	'Units','Normalized', 'Position',[.02 .56 .07 .07],'Callback',@button13);

      MONITOR.infoTexts=[];

      for i=1:5
        MONITOR.infoTexts(i)=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[0.16*(i-1)+0.12 0.01 0.145 0.08]);
      end


    else % Single robot full monitoring mode
      LOGGER=logger();
      LOGGER.init();
      set(gcf,'Position',[1 1 1000 600])
      MONITOR.hFpsText=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[.40 0.93 0.20 0.04]);

      MONITOR.hButton6=uicontrol('Style','pushbutton','String','FPS -',...
	'Units','Normalized','Position',[.30 .93 .10 .04],'Callback',@button6);

      MONITOR.hButton7=uicontrol('Style','pushbutton','String','FPS +',...
	'Units','Normalized', 'Position',[.60 .93 .10 .04],'Callback',@button7);

      MONITOR.hButton12=uicontrol('Style','pushbutton','String','Load LUT',...
	'Units','Normalized', 'Position',[.70 .93 .20 .04],'Callback',@button12);


      MONITOR.hButton0=uicontrol('Style','pushbutton','String','Overlay 1',...
	'Units','Normalized', 'Position',[.02 .80 .07 .07],'Callback',@button0);

      MONITOR.hButton2=uicontrol('Style','pushbutton','String','LABEL A',...
	'Units','Normalized', 'Position',[.02 .73 .07 .07],'Callback',@button2);

      MONITOR.hButton3=uicontrol('Style','pushbutton','String','MAP1',...
	'Units','Normalized', 'Position',[.02 .66 .07 .07],'Callback',@button3);

      MONITOR.hButton4=uicontrol('Style','pushbutton','String','2D ON',...
	'Units','Normalized', 'Position',[.02 .59 .07 .07],'Callback',@button4);

      MONITOR.hButton5=uicontrol('Style','pushbutton','String','DEBUG ON',...
	'Units','Normalized', 'Position',[.02 .52 .07 .07],'Callback',@button5);

      MONITOR.hButton11=uicontrol('Style','pushbutton','String','LOG',...
	'Units','Normalized', 'Position',[.02 .45 .07 .07],'Callback',@button11);

      MONITOR.hInfoText=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[.02 .25 .07 .20]);

      MONITOR.hButton13=uicontrol('Style','pushbutton','String','Kidsize',...
	'Units','Normalized', 'Position',[.02 .18 .07 .07],'Callback',@button13);

      MONITOR.hDebugText=uicontrol('Style','text',...
	'Units','Normalized', 'Position',[.76 .10 .22 .83]);
    end
  end

  function update(robots,  teamNumber, playerNumber , draw_team, ignore_vision)
    if MONITOR.target_fps==0.5 %Paused state
       set(MONITOR.hFpsText,'String','Paused');
       pause(1);
    else 
       tStart = tic;

       if draw_team==3
         update_team_wireless2(robots);
       elseif draw_team==2
         update_team_wireless(robots);
       elseif draw_team==1 
         update_team(robots, teamNumber, playerNumber , ignore_vision)
       else
         update_single( robots, teamNumber, playerNumber )
       end
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

  function update_single( robots, teamNumber, playerNumber )
    % Robot to display
    r_struct = robots{playerNumber,teamNumber}.get_team_struct();
    r_mon = robots{playerNumber,teamNumber}.get_monitor_struct();

    if( isempty(r_mon) )
      disp('Empty monitor struct!'); return;
    end

    % AUTO-SWITCH YUYV TYPE
    yuyv_type = r_mon.yuyv_type;
    if MONITOR.enable1
      MONITOR.h1 = subplot(4,5,[1 2 6 7]);
      if yuyv_type==1
        yuyv = robots{playerNumber,teamNumber}.get_yuyv();
				plot_yuyv(yuyv);
      elseif yuyv_type==2
        yuyv = robots{playerNumber,teamNumber}.get_yuyv2();
				plot_yuyv(yuyv);
      elseif yuyv_type==3
        yuyv = robots{playerNumber,teamNumber}.get_yuyv3();
				plot_yuyv(yuyv);
			else
				return;
      end

      %webots use non-subsampled label (2x size of yuyv)
      if MONITOR.enable0
        if MONITOR.is_webots
          plot_overlay(r_mon,2*MONITOR.enable1,1);
        else
				  if yuyv_type==1
            plot_overlay(r_mon,1,1);
				  elseif yuyv_type==2
            plot_overlay(r_mon,2,1);
				  elseif yuyv_type==3
            plot_overlay(r_mon,4,1);
					else
						return;
				  end
        end
      end

      if MONITOR.logging
        LOGGER.log_data(yuyv + 0,r_mon);
        logstr=sprintf('%d/100',LOGGER.log_count);
        set(MONITOR.hButton11,'String', logstr);
        if LOGGER.log_count==100 
          LOGGER.save_log();
        end
      end
    end

    if MONITOR.enable2==1
      MONITOR.h2 = subplot(4,5,[3 4 8 9]);
      labelA = robots{playerNumber,teamNumber}.get_labelA();
      plot_label(labelA);
      if MONITOR.enable0
        plot_overlay(r_mon,1,MONITOR.enable0);
      end
    elseif MONITOR.enable2==2
      MONITOR.h2 = subplot(4,5,[3 4 8 9]);
      labelB = robots{playerNumber,teamNumber}.get_labelB();
      plot_label(labelB);
      if MONITOR.enable0
        plot_overlay(r_mon,r_mon.camera.scaleB,MONITOR.enable0);
      end
    elseif (MONITOR.enable2==3) && (~isempty(MONITOR.lutname))
      MONITOR.h2 = subplot(4,5,[3 4 8 9]);
      yuyv = robots{playerNumber,teamNumber}.get_yuyv();
      label_lut=yuyv2label(yuyv,LUT);
      plot_label(label_lut);
    end

    if MONITOR.enable3
      MONITOR.h3 = subplot(4,5,[11 12 16 17]);
      cla(MONITOR.h3);


      if MONITOR.enable3==5 
        if isfield(r_mon, 'occ')
          plot_occ(r_mon.occ);            
				end
%        plot_field(MONITOR.h3,MONITOR.fieldtype);
%        plot_robot( r_struct, r_mon,2,3 );
      else
        plot_field(MONITOR.h3,MONITOR.fieldtype);
        plot_robot( r_struct, r_mon,1.5,MONITOR.enable3,'' );
      end

    end

    if MONITOR.enable4
      MONITOR.h4 = subplot(4,5,[13 14 18 19]);
      plot_surroundings( MONITOR.h4, r_mon );
    end
    
    if MONITOR.enable5
      set(MONITOR.hDebugText,'String',r_mon.debug.message);
    end

    [infostr textcolor]=robot_info(r_struct,r_mon,2);
    set(MONITOR.hInfoText,'String',infostr);

  end

  function update_team(robots, teamNumber, playerNumber , ignore_vision)

    %Draw common field 
    h_c=subplot(5,5,[1:15]);
    cla(h_c);
    plot_field(h_c,MONITOR.fieldtype);

    for i=1:length(playerNumber)
      r_struct = robots{playerNumber(i),teamNumber}.get_team_struct();
      r_mon = robots{playerNumber(i),teamNumber}.get_monitor_struct();
      labelB = robots{playerNumber(i),teamNumber}.get_labelB();
      updated=robots{playerNumber(i),teamNumber}.updated;
      tLastUpdate=robots{playerNumber(i),teamNumber}.tLastUpdate;

%      if updated 
        h_c=subplot(5,5,[1:15]);
        plot_robot( r_struct, r_mon,2,MONITOR.enable10);
        updated = 0;
%      end

      if MONITOR.enable8==1 && ignore_vision==0
        h1=subplot(5,5,15+playerNumber(i));
        plot_label(labelB);
        plot_overlay(r_mon,4,1);
      elseif MONITOR.enable8==2
        h1=subplot(5,5,15+playerNumber(i));
        cla(h1);
        plot_overlay(r_mon,4,1);
      end
	
      if MONITOR.enable9
        h2=subplot(5,5,20+playerNumber(i));
        plot_surroundings( h2, r_mon );
      end


      h2=subplot(5,5,20+playerNumber(i));
      [infostr textcolor]=robot_info(r_struct,r_mon,2);
      set(MONITOR.infoTexts(i),'String',infostr);
    end
  end

  function update_team_wireless(robot_team)

    MONITOR.count = MONITOR.count + 1;

    %Draw common field 
    h_c=subplot(5,5,[6:20]);
    cla(h_c);
    plot_field(h_c,MONITOR.fieldtype);
    hold on;
    for i=1:10
      r_struct = robot_team.get_team_struct_wireless(i);
      %Alive check

      if r_struct.id>0

        timepassed = r_struct.time-MONITOR.timestamp(i);
        MONITOR.timestamp(i)=r_struct.time;

        if timepassed==0
          MONITOR.deadcount(i) = MONITOR.deadcount(i)+1;
        else
          MONITOR.deadcount(i) = 0;
        end

deadcount_threshold = 50;


%        if MONITOR.deadcount(i) < 20 % ~2 sec interval until turning off
        if MONITOR.deadcount(i) < deadcount_threshold % ~5 sec interval until turning off

          h_c=subplot(5,5,[6:20]);
          plot_robot( r_struct, [],2,5,r_struct.robotName);
          updated = 0;
  	  if i<6 
            h1=subplot(5,5,i);
	    labelB = robot_team.get_labelB_wireless(i);
            plot_label(labelB);
	  else
            h1=subplot(5,5,i+15);
	    labelB = robot_team.get_labelB_wireless(i);
            plot_label(labelB);
	  end
	  plot_overlay_wireless(r_struct);
          [infostr textcolor]=robot_info(r_struct,[],3,r_struct.robotName);

          set(MONITOR.infoTexts(i),'String',infostr);

%          infostr2 = sprintf('%s\nDC:%d',MONITOR.deadcount(i));
%          set(MONITOR.infoTexts(i),'String',infostr2);

        elseif MONITOR.deadcount(i)==deadcount_threshold
          labelB = robot_team.get_labelB_wireless(i);
  	  if i<6 
            h1=subplot(5,5,i);
            plot_label(labelB*0);
	  else
            h1=subplot(5,5,i+15);
            plot_label(labelB*0);
	  end
          set(MONITOR.infoTexts(i),'String','');
	end
      end
    end
    hold off;
  end

  function update_team_wireless2(robot_team)

    MONITOR.count = MONITOR.count + 1;

    %Draw common field 
    h_c=subplot(5,5,[1 2 3 4 6 7 8 9 11 12 13 14 16 17 18 19 21 22 23 24]);
    cla(h_c);
    plot_field(h_c,MONITOR.fieldtype);
    hold on;
    for i=1:5
      r_struct = robot_team.get_team_struct_wireless(i);
      %Alive check

      if r_struct.id>0

        timepassed = r_struct.time-MONITOR.timestamp(i);
        MONITOR.timestamp(i)=r_struct.time;

        if timepassed==0
          MONITOR.deadcount(i) = MONITOR.deadcount(i)+1;
        else
          MONITOR.deadcount(i) = 0;
        end

%        if MONITOR.deadcount(i) < 20 % ~2 sec interval until turning off
        if MONITOR.deadcount(i) < 50 % ~5 sec interval until turning off
    h_c=subplot(5,5,[1 2 3 4 6 7 8 9 11 12 13 14 16 17 18 19 21 22 23 24]);
          plot_robot( r_struct, [],2,5,r_struct.robotName);
          updated = 0;
  	  if i<6 
            h1=subplot(5,5,i*5);
	    labelB = robot_team.get_labelB_wireless(i);
            plot_label(labelB);

	    %SHOW whether the robot is inactive
            role=r_struct.role;
	    if role==5
	      b_name=text(10,30, 'W_GOALIE');
	      set(b_name,'FontSize',28,'Color','r');
	    elseif role==4
	      b_name=text(10,30, 'W_PLAYER');
	      set(b_name,'FontSize',28,'Color','r');
            end
	  else
            h1=subplot(5,5,i+15);
	    labelB = robot_team.get_labelB_wireless(i);
            plot_label(labelB);
	  end
	  plot_overlay_wireless(r_struct);
          [infostr textcolor]=robot_info(r_struct,[],3,r_struct.robotName);


%          set(MONITOR.infoTexts(i),'String',infostr);

          infostr2 = sprintf('%s\n DC:%d\n',infostr,MONITOR.deadcount(i));
          set(MONITOR.infoTexts(i),'String',infostr2);

        elseif MONITOR.deadcount(i)==50 %Clear vision at 20
          labelB = robot_team.get_labelB_wireless(i);
          h1=subplot(5,5,i*5);
          plot_label(labelB*0);
          set(MONITOR.infoTexts(i),'String','');
	end
      end
    end
    hold off;
  end



  function plot_grid(map)
    %map: -1 to 1
    siz=sqrt(length(map)/6/4);    
    map=reshape(map,[4*siz 6*siz]);
    map_black=max(0,map);
    map_green=max(0,-map);

    rgbc=zeros([4*siz 6*siz 3]);
    rgbc(:,:,1)=1-map_black-map_green;
    rgbc(:,:,2)=1-map_black;
    rgbc(:,:,3)=1-map_black-map_green;
    image('XData',[-3:1/siz:3],'YData',[-2:1/siz:2],...
	'CData',rgbc);  
  end


  function button0(varargin)
    MONITOR.enable0=mod(MONITOR.enable0+1,3);
    if MONITOR.enable0==1 set(MONITOR.hButton0,'String', 'Overlay 1');
    elseif MONITOR.enable0==2 set(MONITOR.hButton0,'String', 'Overlay 2');
    else set(MONITOR.hButton0,'String', 'Overlay OFF');
    end
  end

  function button1(varargin)
    MONITOR.enable1=mod(MONITOR.enable1+1,4);
    if MONITOR.enable1==1 set(MONITOR.hButton1,'String', 'YUYV1');
    elseif MONITOR.enable1==2 set(MONITOR.hButton1,'String', 'YUYV2');
    elseif MONITOR.enable1==3 set(MONITOR.hButton1,'String', 'YUYV4');
    else set(MONITOR.hButton1,'String', 'YUYV OFF');
      cla(MONITOR.h1);
    end
  end

  function button2(varargin)
    MONITOR.enable2=mod(MONITOR.enable2+1,4);
    if MONITOR.lutname==0 
      MONITOR.enable2=mod(MONITOR.enable2,3);
    end 
    if MONITOR.enable2==1 set(MONITOR.hButton2,'String', 'LABEL A');
    elseif MONITOR.enable2==2 set(MONITOR.hButton2,'String', 'LABEL B');
    elseif MONITOR.enable2==3 set(MONITOR.hButton2,'String', 'LUT');
    else set(MONITOR.hButton2,'String', 'LABEL OFF');
      cla(MONITOR.h2);
    end
  end

  function button3(varargin)
    MONITOR.enable3=mod(MONITOR.enable3+1,6);
    if MONITOR.enable3==1 set(MONITOR.hButton3,'String', 'MAP1');
    elseif MONITOR.enable3==2 set(MONITOR.hButton3,'String', 'MAP2');
    elseif MONITOR.enable3==3 set(MONITOR.hButton3,'String', 'MAP3');
    elseif MONITOR.enable3==4 set(MONITOR.hButton3,'String', 'PVIEW');
    elseif MONITOR.enable3==5 set(MONITOR.hButton3,'String', 'OccVIEW');
    else set(MONITOR.hButton3,'String', 'MAP OFF');
      cla(MONITOR.h3);
    end
  end

  function button4(varargin)
    MONITOR.enable4=1-MONITOR.enable4;
    if MONITOR.enable4 set(MONITOR.hButton4,'String', '2D ON');
    else set(MONITOR.hButton4,'String', '2D OFF');
      cla(MONITOR.h4);
    end
  end

  function button5(varargin)
    MONITOR.enable5=1-MONITOR.enable5;
    if MONITOR.enable5 set(MONITOR.hButton5,'String', 'DEBUG ON');
    else set(MONITOR.hButton5,'String', 'DEBUG OFF');
      set(MONITOR.hDebugText,'String','');
    end
  end

  function button6(varargin)
    %0.5fps means paused state
    MONITOR.target_fps=max(0.5,MONITOR.target_fps/2);
  end

  function button7(varargin)
    MONITOR.target_fps=min(32,MONITOR.target_fps*2);
  end

  function button8(varargin)
    MONITOR.enable8=mod(MONITOR.enable8+1,3);
    if MONITOR.enable8==1 set(MONITOR.hButton8,'String', 'LABEL');
    elseif MONITOR.enable8==2 set(MONITOR.hButton8,'String', 'Overlay');
    else set(MONITOR.hButton8,'String', 'OFF');
    end
  end

  function button9(varargin)
    MONITOR.enable9=1-MONITOR.enable9;
    if MONITOR.enable9 set(MONITOR.hButton9,'String', '2D ON');
    else set(MONITOR.hButton9,'String', '2D OFF');
    end
  end

  function button10(varargin)
    MONITOR.enable10=mod(MONITOR.enable10,3)+1;  %1,2,3
    if MONITOR.enable10==1 set(MONITOR.hButton10,'String', 'MAP1');
    elseif MONITOR.enable10==2 set(MONITOR.hButton10,'String', 'MAP2');
    elseif MONITOR.enable10==3 set(MONITOR.hButton10,'String', 'MAP3');
    end
  end

  function button11(varargin)
    MONITOR.logging=1-MONITOR.logging;
  end

  function button12(varargin) % Load lut file
    [filename, pathname] = uigetfile('*.raw', 'Select lut file to load');
    if (filename ~= 0)
      MONITOR.lutname=filename;
      fid = fopen([pathname filename], 'r');
      LUT = fread(fid, 'uint8');
      fclose(fid);
      set(MONITOR.hButton12,'String', filename);
    end
  end

  function button13(varargin)
    MONITOR.fieldtype=mod(MONITOR.fieldtype+1,3);
    if MONITOR.fieldtype==1 set(MONITOR.hButton13,'String', 'SPL');
    elseif MONITOR.fieldtype==2 set(MONITOR.hButton13,'String', 'TeenSize');
    else set(MONITOR.hButton13,'String', 'Kidsize');
    end
  end
end
