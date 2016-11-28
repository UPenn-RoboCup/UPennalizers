function h=show_motion_monitor()


  global MONITOR

  h.init=@init;
  h.update=@update;
  h.t_last =0;
  h.motion_struct=[];

  h.data=[];
  h.data.t=[];
  h.data.imuP=[];
  h.data.imuR=[];

  h.ldata=[];
  h.ldata.t=[];
  h.ldata.t_d=[];
  h.ldata.imuP=[];
  h.ldata.imuR=[];
  h.ldata.errP=[];
  h.ldata.errR=[];
  h.ldata.errX=[];
  h.ldata.errY=[];
  h.ldata.torsoP=[];
  h.ldata.torsoPF=[];

  h.rdata=[];
  h.rdata.t=[];
  h.rdata.t_d=[];
  h.rdata.imuP=[];
  h.rdata.imuR=[];
  h.rdata.errP=[];
  h.rdata.errR=[];
  h.rdata.errX=[];
  h.rdata.errY=[];
  h.rdata.torsoP=[];
  h.rdata.torsoPF=[];


  h.ddata=[];
  h.ddata.t=[];
  h.ddata.t_d=[];
  h.ddata.imuP=[];
  h.ddata.imuR=[];
  h.ddata.errP=[];
  h.ddata.errR=[];
  h.ddata.errX=[];
  h.ddata.errY=[];
  h.ddata.torsoP=[];
  h.ddata.torsoPF=[];


  function init(t0)
    MONITOR.hFpsText=uicontrol('Style','text','Units','Normalized', 'Position',[.40 0.97 0.20 0.03]);
    MONITOR.hButton1=uicontrol('Style','pushbutton','String','Clear',...
      'Units','Normalized','Position',[.30 .97 .10 .03],'Callback',@button1);
    MONITOR.t_last = t0;
  end

  function update(robot)
    t0=tic;
    r=robot.get_motion_struct();    
    while r.t==MONITOR.t_last 
      pause(0.0025);
      r=robot.get_motion_struct();    
    end
    MONITOR.t_last = r.t/1000;

    if r.support(1)==0 %left support
      MONITOR.ldata.t = [MONITOR.ldata.t MONITOR.t_last];
      MONITOR.ldata.errP = [MONITOR.ldata.errP r.errorLeft(3)];
      MONITOR.ldata.errR = [MONITOR.ldata.errR r.errorLeft(4)];

      MONITOR.ldata.torsoP = [MONITOR.ldata.torsoP r.torsoTarget(1)];
      MONITOR.ldata.torsoPF = [MONITOR.ldata.torsoPF r.torsoTargetFiltered(1)];


    elseif r.support(1)==1 %right support
      MONITOR.rdata.t = [MONITOR.rdata.t MONITOR.t_last];
      MONITOR.rdata.errP = [MONITOR.rdata.errP r.errorRight(3)];
      MONITOR.rdata.errR = [MONITOR.rdata.errR r.errorRight(4)];
      MONITOR.rdata.torsoP = [MONITOR.rdata.torsoP r.torsoTarget(1)];
      MONITOR.rdata.torsoPF = [MONITOR.rdata.torsoPF r.torsoTargetFiltered(1)];


    else
      MONITOR.ddata.t = [MONITOR.ddata.t MONITOR.t_last];
      MONITOR.ddata.errP = [MONITOR.ddata.errP r.error(3)];
      MONITOR.ddata.errR = [MONITOR.ddata.errR r.error(4)];
      MONITOR.ddata.torsoP = [MONITOR.ddata.torsoP r.torsoTarget(1)];
      MONITOR.ddata.torsoPF = [MONITOR.ddata.torsoPF r.torsoTargetFiltered(1)];

    end

    if r.support(2)==0 %left support at delayed time
      MONITOR.ldata.t_d = [MONITOR.ldata.t_d MONITOR.t_last];
      MONITOR.ldata.imuP = [MONITOR.ldata.imuP r.imuAngle(1)];
      MONITOR.ldata.imuR = [MONITOR.ldata.imuR r.imuAngle(2)];

    elseif r.support(2)==1 %right support at delayed time      
      MONITOR.rdata.t_d = [MONITOR.rdata.t_d MONITOR.t_last];
      MONITOR.rdata.imuP = [MONITOR.rdata.imuP r.imuAngle(1)];
      MONITOR.rdata.imuR = [MONITOR.rdata.imuR r.imuAngle(2)];

    else
      MONITOR.ddata.t_d = [MONITOR.ddata.t_d MONITOR.t_last];
      MONITOR.ddata.imuP = [MONITOR.ddata.imuP r.imuAngle(1)];
      MONITOR.ddata.imuR = [MONITOR.ddata.imuR r.imuAngle(2)];

    end


    draw(r,MONITOR.t_last);
    drawnow;
    tElapsed = toc(t0);

    set(MONITOR.hFpsText,'String',sprintf('Plot: %d ms FPS: %.1f', floor(tElapsed*1000),...
         1/tElapsed ));
  end

  function draw(r,t_last)
    subplot(2,1,1);
    plot(MONITOR.ldata.t_d,MONITOR.ldata.imuP,'r.',...
        MONITOR.rdata.t_d,MONITOR.rdata.imuP,'b.',...
        MONITOR.ddata.t_d,MONITOR.ddata.imuP,'k.');




    ylabel('IMU pitch angle')
    axis([t_last-3 t_last -10 10]);
    subplot(2,1,2);

    plot(MONITOR.ldata.t,MONITOR.ldata.errP,'r.',...
        MONITOR.rdata.t,MONITOR.rdata.errP,'b.',...
        MONITOR.ddata.t,MONITOR.ddata.errP,'k.');    
    ylabel('Encoder feedback angle')
    %{
    plot(MONITOR.ldata.t,MONITOR.ldata.torsoPF,'r.',...
        MONITOR.rdata.t,MONITOR.rdata.torsoPF,'b.',...
        MONITOR.ddata.t,MONITOR.ddata.torsoPF,'k.');    
    ylabel('Pitch feedback angle')
    %}    


    axis([t_last-3 t_last -5 5]);
  end

  function button1(varargin)
    MONITOR.ldata.t=[];
    MONITOR.rdata.t=[];
    MONITOR.ddata.t=[];

    MONITOR.ldata.torsoPF=[];
    MONITOR.rdata.torsoPF=[];
    MONITOR.ddata.torsoPF=[];
    
    MONITOR.ldata.errP=[];
    MONITOR.rdata.errP=[];
    MONITOR.ddata.errP=[];
    
    MONITOR.ldata.imuP=[];
    MONITOR.rdata.imuP=[];
    MONITOR.ddata.imuP=[];

    MONITOR.ldata.t_d=[];
    MONITOR.rdata.t_d=[];
    MONITOR.ddata.t_d=[];
    
  end
end
