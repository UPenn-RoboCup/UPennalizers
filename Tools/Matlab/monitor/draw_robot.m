function h = draw_robot(h_axes, robot_struct, team_struct, scale, drawlevel, name)
  x0 = robot_struct.pose{1};
  y0 = robot_struct.pose{2};
  ca = cos(robot_struct.pose{3});
  sa = sin(robot_struct.pose{3});

  hold(h_axes, 'on');

  teamColors = ['b', 'r'];
  idColors = ['k', 'r', 'g', 'b'];
  % Role:  0:Goalie 1:Attack / 2:Defend / 3:Support / 4: R.player 5: R.goalie
  roleColors = {'g','r','k', 'k--','r--','g--'};

  if robot_struct.is_fall_down
    ca=1;sa=0;
    xr = x0+[-0.10  0  .10  0]*2/scale;
    yr = y0+[0    .10   0 -.10]*2/scale;

    hr = fill(xr, yr, teamColors(max(1,team_struct.color+1)),...
              'Parent', h_axes);

    if team_struct.role>1 
      h_role=plot(h_axes, [xr xr(1)],[yr yr(1)],roleColors{team_struct.role});
      set(h_role,'LineWidth',3);
    end
  else
%      xRobot = [0 -.25 -.25]*2/scale;
%      yRobot = [0 -.10 +.10]*2/scale;
    xRobot = [.125 -.125 -.125]*2/scale;
    yRobot = [0 -.10 +.10]*2/scale;

    xr = xRobot*ca - yRobot*sa + x0;
    yr = xRobot*sa + yRobot*ca + y0;
    xm = mean(xRobot);
    ym = mean(yRobot);

    hr = fill(xr, yr, teamColors(max(1,team_struct.color+1)),...
              'Parent', h_axes);

    if team_struct.role>1 
      h_role=plot(h_axes, [xr xr(1)],[yr yr(1)],roleColors{team_struct.role+1});
      set(h_role,'LineWidth',3);
    end

    % disp attack bearing
    %{
    xab = cos(robot.attackBearing)*ca - sin(robot.attackBearing)*sa;
    yab = cos(robot.attackBearing)*sa + sin(robot.attackBearing)*ca;
    ab_scale = 1/scale;
    quiver(h_axes, x0, y0, xab*ab_scale,yab*ab_scale, 'k' );
    %}
  end
  hold(h_axes, 'off');

end
