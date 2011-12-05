function h = plot_robot(robot, scale)
  
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

  ca = cos(robot.pose.a);
  sa = sin(robot.pose.a);
  
  xr = x0*ca - y0*sa + robot.pose.x;
  yr = x0*sa + y0*ca + robot.pose.y;
  if robot.id > 1
    hr = fill(xr, yr, teamColors(robot.teamColor+1), 'EdgeColor', roleColors(robot.role), 'LineWidth', 2);
  else
    hr = fill(xr, yr, teamColors(robot.teamColor+1));
  end

  % disp id number
  xt = xm*ca - ym*sa + robot.pose.x;
  yt = xm*sa + ym*ca + robot.pose.y;
  text(xt, yt, num2str(robot.id), 'FontSize', 24, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');

  %{
  % disp attack bearing
  xab = cos(attackBearing)*ca - sin(attackBearing)*sa;
  yab = cos(attackBearing)*sa + sin(attackBearing)*ca;
  quiver(pose(1), pose(2), xab, yab);
  %}

  if ~isempty(robot.ball),
    ball = [robot.ball.x robot.ball.y];
    xb = xr(1) + ball(1)*ca - ball(2)*sa;
    yb = yr(1) + ball(1)*sa + ball(2)*ca;
    hb = plot(xb, yb, [idColors(robot.id) 'o']);
    set(hb, 'MarkerSize', scale*2);
  end

  hold off;

end
