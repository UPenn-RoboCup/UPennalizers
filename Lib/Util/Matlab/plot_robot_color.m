function h = plot_robot(pose, ball, id, color, attackBearing)

  if nargin < 3,
    color = 'r';
  end
	if nargin < 2,
		ball = [];
	end
  if nargin < 1,
    pose = [0 0 0];
  else
    pose = [pose.x pose.y pose.a];
  end

  scale = 3;

  hold on;

  x0 = scale*[0 -.25 -.25];
  y0 = scale*[0 -.10 +.10];
  xm = mean(x0);
  ym = mean(y0);

  ca = cos(pose(3));
  sa = sin(pose(3));
  
  xr = x0*ca - y0*sa + pose(1);
  yr = x0*sa + y0*ca + pose(2);
  hr = fill(xr, yr, color);
  % disp id number
  xt = xm*ca - ym*sa + pose(1);
  yt = xm*sa + ym*ca + pose(2);
  text(xt, yt, num2str(id), 'FontSize', 26, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');
  % disp attack bearing
  xab = cos(attackBearing)*ca - sin(attackBearing)*sa;
  yab = cos(attackBearing)*sa + sin(attackBearing)*ca;
  quiver(pose(1), pose(2), xab, yab);

  if ~isempty(ball),
    ball = [ball.x ball.y];
    xb = xr(1) + ball(1)*ca - ball(2)*sa;
    yb = yr(1) + ball(1)*sa + ball(2)*ca;
    hb = plot(xb, yb, [color 'o']);
    set(hb, 'MarkerSize', scale*2);
  end

  hold off;

end
