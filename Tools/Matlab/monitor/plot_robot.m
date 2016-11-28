function h = plot_robot_monitor_struct(robot_struct,r_mon,scale,drawlevel,name)
% This function shows the robot over the field map
% Level 1: show position only
% Level 2: show position and vision info
% Level 3: show position, vision info and fov info
% Level 4: show position, vision info and particles

% Level 5: wireless (level 2 + robot name)

  x0 = robot_struct.pose.x;
  y0 = robot_struct.pose.y;
  ca = cos(robot_struct.pose.a);
  sa = sin(robot_struct.pose.a);
      
  hold on;
  if robot_struct.fall
    ca=1;sa=0;
    plot_fallen_robot(robot_struct,scale)
    if drawlevel==5
      plot_info(robot_struct,scale,2,name);
    else
      plot_info(robot_struct,scale,2,'');
    end
  else
    if drawlevel==1 
      %simple position and pose
      plot_robot(robot_struct,scale);
      plot_info(robot_struct,scale,1);
      plot_ball(robot_struct,scale);
      plot_sound(robot_struct,scale);
      plot_obstacle(robot_struct,scale);
      %plot_gps_robot(robot_struct,scale);

    elseif drawlevel==2 
      %additional simple vision info for team monitor

      plot_robot(robot_struct,scale);
      plot_info(robot_struct,scale,1);
      plot_ball(robot_struct,scale);
      plot_goal_team(robot_struct,scale);
      %plot_corner_team(robot_struct,scale);
      plot_gps_robot(robot_struct,scale);
      plot_obstacle(robot_struct,scale);
    elseif drawlevel==5 
      %additional simple vision info for team monitor

      plot_robot(robot_struct,scale);
      plot_info(robot_struct,scale,2,name);
      plot_ball(robot_struct,scale);
      plot_goal_team(robot_struct,scale);
      plot_corner_team(robot_struct,scale);
      plot_gps_robot(robot_struct,scale);
      plot_obstacle(robot_struct,scale);

    elseif drawlevel==3 
      %Full vision info
      plot_robot(robot_struct,scale);
      plot_info(robot_struct,scale,1);
      plot_ball(robot_struct,scale);

      plot_line(r_mon.line,scale);
      plot_corner(r_mon.corner,scale);
      plot_goal(r_mon.goal,scale);
      plot_fov(r_mon.fov);

      plot_gps_robot(robot_struct,scale);
      plot_obstacle(robot_struct,scale);
    elseif drawlevel==4
%      plot_robot(robot_struct,scale);
      plot_particle(r_mon.particle);
      plot_gps_robot(robot_struct,scale);
      plot_goal(r_mon.goal,scale);
      plot_corner(r_mon.corner,scale);



      %plot_info(robot_struct,scale,1);
      %plot_ball(robot_struct,scale);
      %plot_sound(robot_struct,scale);



      %plot_landmark(r_mon.landmark,scale);
      %plot_line(r_mon.line,scale);
      %plot_fov(r_mon.fov);

      plot_obstacle(robot_struct,scale);
    end
  end

  hold off;

%subfunctions

  function plot_fallen_robot(robot,scale)
    xr = x0+[-0.10  0  .10  0]*2/scale;
    yr = y0+[0    .10   0 -.10]*2/scale;

    teamColors = ['b', 'r'];
    idColors = ['k', 'r', 'g', 'b'];
    % Role:  0:Goalie 1:Attack / 2:Defend / 3:Support / 4: R.player 5: R.goalie
    roleColors = {'g','r','k', 'k--','r--','g--'};

    teamColors = ['b', 'r'];
    hr = fill(xr, yr, teamColors(max(1,robot.teamColor+1)));

    if robot.role>1 
      h_role=plot([xr xr(1)],[yr yr(1)],roleColors{robot.role});
      set(h_role,'LineWidth',3);
    end
  end

  function plot_gps_robot(robot,scale)
    if (~isfield(robot, 'gpspose'))
      return
    end
    xgps = robot_struct.gpspose.x;
    ygps = robot_struct.gpspose.y;
    rErr = sqrt((x0-xgps)^2+(y0-ygps)^2);
    if rErr>0
      cagps = cos(robot_struct.gpspose.a);
      sagps = sin(robot_struct.gpspose.a);

      pl_len=1/scale;
      dx=cagps*pl_len;
      dy=sagps*pl_len;
      quiver(xgps,ygps,dx,dy,0,'b');
      plot(xgps,ygps,'bo');

      %Draw error circle
      errBox = [xgps-rErr ygps-rErr 2*rErr 2*rErr];
      rectangle('Position', errBox, 'Curvature',[1,1], ...
	'LineStyle','--');

      aErr=abs(robot.attackBearing-robot.gps_attackbearing);
      a1 = robot.gps_attackbearing + aErr + robot_struct.gpspose.a;
      a2 = robot.gps_attackbearing - aErr + robot_struct.gpspose.a;
      rPie = 1/scale;

      plot([xgps xgps+rPie*cos(a1)],[ygps ygps+rPie*sin(a1)]);
      plot([xgps xgps+rPie*cos(a2)],[ygps ygps+rPie*sin(a2)]);

    end

  end


  function plot_robot(robot,scale,name)
    xRobot = [.125 -.125 -.125]*2/scale;
    yRobot = [0 -.10 +.10]*2/scale;

    xr = xRobot*ca - yRobot*sa + x0;
    yr = xRobot*sa + yRobot*ca + y0;
    xm = mean(xRobot);
    ym = mean(yRobot);

    teamColors = ['b', 'r'];
    idColors = ['k', 'r', 'g', 'b'];
    % Role:  0:Goalie 1:Attack / 2:Defend / 3:Support / 4: R.player 5: R.goalie
    roleColors = {'g','r','k', 'k--','r--','g--'};

    teamColors = ['b', 'r'];
    hr = fill(xr, yr, teamColors(max(1,robot.teamColor+1)));

    if robot.role>1 
      h_role=plot([xr xr(1)],[yr yr(1)],roleColors{robot.role+1});
      set(h_role,'LineWidth',3);
    end

%{
    ca2 = cos(robot_struct.pose_target(3));
    sa2 = sin(robot_struct.pose_target(3));
    xRobot2 = [.125 -.125 -.125]*2/scale/2;
    yRobot2 = [0 -.10 +.10]*2/scale/2;
    xr2 = xRobot2*ca2 - yRobot2*sa2 + robot_struct.pose_target(1);
    yr2 = xRobot2*sa2 + yRobot2*ca2 + robot_struct.pose_target(2);
    
    teamColors = ['b', 'r'];
    fill(xr2, yr2, teamColors(max(1,robot.teamColor+1)));
    plot([x0 robot_struct.pose_target(1)],[y0 robot_struct.pose_target(2)],'k--')
%}
  end


  function plot_info(robot,angle,plottype,name)
    if plottype==1
      infostr=robot_info(robot,0,1);
    else
      infostr=robot_info(robot,0,3,name);
    end
    xtext=-1/scale;   xtext2=-0.4/scale;
    xt = xtext*ca + x0+xtext2;
    yt = xtext*sa + y0;

    b_name=text(xt, yt, infostr);
    set(b_name,'FontSize',16/scale);
%    set(b_name,'FontSize',32/scale);
  end

  function plot_ball(robot,scale)
    if (~isempty(robot.ball))
      ball = [robot.ball.x robot.ball.y robot.time-robot.ball.t];
      ballt=ball(3);
      xb = x0 + ball(1)*ca - ball(2)*sa;   
      yb = y0 + ball(1)*sa + ball(2)*ca;
      %hb = plot(xb, yb, [idColors(robot_struct.id) 'o']);
      hb = plot(xb, yb, 'ro');
 

      if ballt<0.5 
        plot([x0 xb],[y0 yb],'r');
        set(hb, 'MarkerSize', 8/scale);
%{
        ball_vel=[robot.ball.vx robot.ball.vy];
        xbv =  ball_vel(1)*ca - ball_vel(2)*sa;   
        ybv =  ball_vel(1)*sa + ball_vel(2)*ca;
        qvscale = 2;
        quiver(xb, yb, qvscale*xbv/scale, qvscale*ybv/scale,...
		 0,'r','LineWidth',2/scale );
%}
      else
        %TODO: add last seen time info
      end
    end
  end

%duplicated.. should be fixed soon

  function plot_goal_team(robot,scale)
    goal=robot.goal;
    if( goal>0) 
      marker='m';
      marker2 = strcat(marker,'--');

%      if(goal.color==2) marker = 'm';% yellow
%      else marker = 'b';end
%      marker2 = strcat(marker,'--');
      if goal ==1 
        marker1 = strcat(marker,'+');%Unknown post
      elseif goal==3
          marker1 = strcat(marker,'>');%Right post
      else
          marker1 = strcat(marker,'<');%Left or two post
      end
      x1 = robot.goalv1(1)*ca - robot.goalv1(2)*sa + robot_struct.pose.x;
      y1 = robot.goalv1(1)*sa + robot.goalv1(2)*ca + robot_struct.pose.y;
      plot(x1,y1,marker1,'MarkerSize',12/scale);
      plot([x0 x1],[y0 y1],marker2);

      if goal==4 
        marker1 = strcat(marker,'>');%Left post
        x2 = robot.goalv2(1)*ca - robot.goalv2(2)*sa + robot_struct.pose.x;
        y2 = robot.goalv2(1)*sa + robot.goalv2(2)*ca + robot_struct.pose.y;
        plot(x2,y2,marker1,'MarkerSize',12/scale);
        plot([x0 x2],[y0 y2],marker2);
      end
    end
  end


  function plot_corner_team(robot,scale)
    marker='b';
    marker1 = strcat(marker,'--');
    if (robot.cornera~=0 && robot.cornerv(1)~=0 && robot.cornerv(2)~=0)
      x = robot.cornerv(1)*ca - robot.cornerv(2)*sa + robot_struct.pose.x;
      y = robot.cornerv(1)*sa + robot.cornerv(2)*ca + robot_struct.pose.y;
      plot([x0,x],[y0,y],marker1);
      a = robot_struct.pose.a + robot.cornera;
      a1 = a + pi/4; a2 = a - pi/4;
      x1 = x + 0.25*cos(a1); x2 = x + 0.25*cos(a2);
      y1 = y + 0.25*sin(a1); y2 = y + 0.25*sin(a2);
      plot([x,x1],[y,y1],'b','LineWidth',3);
      plot([x,x2],[y,y2],'b','LineWidth',3);
    end
    
    if isfield(robot,'corner')
      corner = robot.corner;
      if (corner>0)
        marker='k';
        if corner==1 
          marker2 = strcat(marker,'s');
        else
          marker2 = strcat(marker,'p');
        end
        marker3 = strcat(marker,'--');
        x1 = robot.cornerv(1)*ca - robot.cornerv(2)*sa + robot_struct.pose.x;
        y1 = robot.cornerv(1)*sa + robot.cornerv(2)*ca + robot_struct.pose.y;
        plot(x1,y1,marker2,'MarkerSize',12/scale);
        plot([x0 x1],[y0 y1],marker3);
      end
    end
  end



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Monitor struct based plots (optional)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  function plot_fov(fov)  %draw fov boundary
    x1 = fov.TL(1)*ca - fov.TL(2)*sa + x0;
    y1 = fov.TL(1)*sa + fov.TL(2)*ca + y0;
    x2 = fov.TR(1)*ca - fov.TR(2)*sa + x0;
    y2 = fov.TR(1)*sa + fov.TR(2)*ca + y0;
    plot([x1 x2],[y1 y2], 'k--');
    plot([x0 x1],[y0 y1], 'k--');
    plot([x0 x2],[y0 y2], 'k--');
  end
  
  function plot_goal(goal,scale)
    if( goal.detect==1 )
      if(goal.color==2) marker = 'm';% yellow
      else marker = 'b';end
      marker2 = strcat(marker,'--');
      if( goal.v1.scale ~= 0 )

        if goal.type==0 
          marker1 = strcat(marker,'+');%Unknown post
	elseif goal.type==2
          marker1 = strcat(marker,'>');%Right post
	else
          marker1 = strcat(marker,'<');%Left or two post
	end
        x1 = goal.v1.x*ca - goal.v1.y*sa + robot_struct.pose.x;
        y1 = goal.v1.x*sa + goal.v1.y*ca + robot_struct.pose.y;
        plot(x1,y1,marker1,'MarkerSize',12/scale);
        plot([x0 x1],[y0 y1],marker2);
      end
      if( goal.v2.scale ~= 0 )
        marker1 = strcat(marker,'>');%Left post
        x2 = goal.v2.x*ca - goal.v2.y*sa + robot_struct.pose.x;
        y2 = goal.v2.x*sa + goal.v2.y*ca + robot_struct.pose.y;
        plot(x2,y2,marker1,'MarkerSize',12/scale);
        plot([x0 x2],[y0 y2],marker2);
      end
    end
  end

  function plot_landmark(landmark,scale)
    if (landmark.detect==1)
      if (landmark.color==2) marker='m';% yellow
      else marker='b';	end
      marker2 = strcat(marker,'x');
      marker3 = strcat(marker,'--');
      x1 = landmark.v(1)*ca - landmark.v(2)*sa + robot_struct.pose.x;
      y1 = landmark.v(1)*sa + landmark.v(2)*ca + robot_struct.pose.y;
      plot(x1,y1,marker2,'MarkerSize',12/scale);
      plot([x0 x1],[y0 y1],marker3);
    end
  end

  function plot_line(line,scale)

    if( line.detect==1 )
      nLines=line.nLines;
      for i=1:nLines
        v1=line.v1{i};
        v2=line.v2{i};

        x1 = v1(1)*ca - v1(2)*sa + robot_struct.pose.x;
        y1 = v1(1)*sa + v1(2)*ca + robot_struct.pose.y;
        x2 = v2(1)*ca - v2(2)*sa + robot_struct.pose.x;
        y2 = v2(1)*sa + v2(2)*ca + robot_struct.pose.y;

        plot([x0 (x1+x2)/2],[y0 (y1+y2)/2],'k');
        plot([x1 x2],[y1 y2],'k','LineWidth',2);
      end
    end
  end

  function plot_corner(corner,scale)
    if corner.detect==1
      if corner.type==1
        marker='r';
      else
        marker='b';
      end     

      v=corner.v;
      v1=corner.v1;
      v2=corner.v2;

      x1 = v(1)*ca - v(2)*sa + robot_struct.pose.x;
      y1 = v(1)*sa + v(2)*ca + robot_struct.pose.y;
      plot([x0 x1],[y0 y1],marker);

      x1 = v(1)*ca - v(2)*sa + robot_struct.pose.x;
      y1 = v(1)*sa + v(2)*ca + robot_struct.pose.y;
      x2 = v1(1)*ca - v1(2)*sa + robot_struct.pose.x;
      y2 = v1(1)*sa + v1(2)*ca + robot_struct.pose.y;
      plot([x1 x2],[y1 y2],marker,'LineWidth',3);

      x1 = v(1)*ca - v(2)*sa + robot_struct.pose.x;
      y1 = v(1)*sa + v(2)*ca + robot_struct.pose.y;
      x2 = v2(1)*ca - v2(2)*sa + robot_struct.pose.x;
      y2 = v2(1)*sa + v2(2)*ca + robot_struct.pose.y;
      plot([x1 x2],[y1 y2],marker,'LineWidth',3);
    end
  end

  function plot_particle(robot,scale)
%    plot(particle.x,particle.y,'x')

    index=[1:10:200]';

    px=robot.x(index);
    py=robot.y(index);
    pa=robot.a(index);


    pl_len=1;
    dx=cos(pa)*pl_len;
    dy=sin(pa)*pl_len;

    quiver(px,py,dx,dy,0,'k');
    plot(px,py,'r.');

  end

  function plot_sound(robot, scale)
    if (isfield(robot, 'soundFilter') && isfield(robot, 'soundOdomPose'))
      if (any(robot.soundFilter))
        disp(robot.soundFilter);
      end
      sound = robot.soundFilter/100;
      ndiv = length(robot.soundFilter);
      thdiv = 2*pi/ndiv;

      cr = cos(robot.pose.a);
      sr = sin(robot.pose.a);
      cs = cos(robot.soundOdomPose.a);
      ss = sin(robot.soundOdomPose.a);
      wRr = [cr -sr; sr cr];
      rRs = [cs -ss; ss cs]';
      wRs = wRr * rRs;

      u = sound .* cos(-pi+thdiv/2:thdiv:pi-thdiv/2);
      v = sound .* sin(-pi+thdiv/2:thdiv:pi-thdiv/2);
      U = wRs * [u;v];
      x = robot.pose.x .* ones([1, ndiv]);
      y = robot.pose.y .* ones([1, ndiv]);

      quiver(x, y, U(1,:), U(2,:));
    end
  end
  
  function plot_obstacle(robot, scale)
    if (isfield(robot, 'obstacle'))
%      disp('find obstacle and display')
      for cnt = 1 : robot.obstacle.num
%        xob = x0 + robot.obstacle.centroid_x(cnt)*ca - robot.obstacle.centroid_y(cnt)*sa;
%        yob = y0 + robot.obstacle.centroid_x(cnt)*sa + robot.obstacle.centroid_y(cnt)*ca;
        xobn = x0 + robot.obstacle.nearest_x(cnt)*ca - robot.obstacle.nearest_y(cnt)*sa;
        yobn = y0 + robot.obstacle.nearest_x(cnt)*sa + robot.obstacle.nearest_y(cnt)*ca;
        plot(xobn,yobn,'b*');
      end
    end
  end

end
