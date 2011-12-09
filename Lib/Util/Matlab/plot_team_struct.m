function h = plot_robot_struct(robot_struct, scale)

  if( isempty(robot_struct) )
      return;
  end

  if nargin < 2
    scale = 3;
  end

  teamColors = ['b', 'r'];
  idColors = ['k', 'r', 'g', 'b'];
  roleColors = ['g', 'k', 'y'];

  hold on;

  x0 = scale*[0 -.25 -.25];
  y0 = scale*[0 -.10 +.10];
  xm = mean(x0);
  ym = mean(y0);

  ca = cos(robot_struct.pose.a);
  sa = sin(robot_struct.pose.a);
  
  xr = x0*ca - y0*sa + robot_struct.pose.x;
  yr = x0*sa + y0*ca + robot_struct.pose.y;
  if robot_struct.id > 1
    hr = fill(xr, yr, teamColors(robot_struct.teamColor+1), 'EdgeColor', roleColors(robot_struct.role), 'LineWidth', 2);
  else
    hr = fill(xr, yr, teamColors(robot_struct.teamColor+1));
  end

  % disp id number
  xt = xm*ca - ym*sa + robot_struct.pose.x;
  yt = xm*sa + ym*ca + robot_struct.pose.y;
  text(xt, yt, num2str(robot_struct.id), 'FontSize', 24, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');

  
  % disp attack bearing
  xab = cos(robot_struct.attackBearing)*ca - sin(robot_struct.attackBearing)*sa;
  yab = cos(robot_struct.attackBearing)*sa + sin(robot_struct.attackBearing)*ca;
  quiver(robot_struct.pose.x, robot_struct.pose.y, xab, yab);
  

  if ~isempty(robot_struct.ball),
    ball = [robot_struct.ball.x robot_struct.ball.y];
    xb = xr(1) + ball(1)*ca - ball(2)*sa;
    yb = yr(1) + ball(1)*sa + ball(2)*ca;
    hb = plot(xb, yb, [idColors(robot_struct.id) 'o']);
    set(hb, 'MarkerSize', scale*2);
  end

  hold off;

end
