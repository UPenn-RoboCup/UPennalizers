function h = plot_robot(scale)

  if (nargin < 1)
    scale = 3;
  end

  h.teamColors = ['b', 'r'];
  h.idColors = ['k', 'r', 'g', 'b'];
  h.roleColors = ['g', 'k', 'y'];

  h.x0 = scale*[0 -.25 -.25];
  h.y0 = scale*[0 -.10 +.10];
  h.xm = mean(h.x0);
  h.ym = mean(h.y0);

  % initialize robot plot
  ca = cos(0);
  sa = sin(0);
  xr = h.x0*ca - h.y0*sa;
  yr = h.x0*sa - h.y0*ca;
  h.plotHandle = fill(xr, yr, 'k', 'LineWidth', 2);

  % initialize ID display
  xt = h.xm*ca - h.ym*sa;
  yt = h.xm*sa + h.ym*ca;
  h.textHandle = text(xt, yt, '0', 'FontSize', 24, ...
                                   'Color', 'k', ...
                                   'VerticalAlignment', 'middle', ...
                                   'HorizontalAlignment', 'center');

  % initialize ball plot
  h.ballHandle = plot(0, 0, 'o', 'MarkerSize', 2*scale);

  % intialize the plots to inivisible
  set(h.textHandle, 'Visible', 'off');
  set(h.plotHandle, 'Visible', 'off');
  set(h.ballHandle, 'Visible', 'off');

  h.update = @update;

  function update(robot)
  % updates the robot plot from the robot data struct

    if (isempty(robot))
      % set invisible
      set(h.textHandle, 'Visible', 'off');
      set(h.plotHandle, 'Visible', 'off');
      set(h.ballHandle, 'Visible', 'off');

    else
      % set visible
      set(h.textHandle, 'Visible', 'on');
      set(h.plotHandle, 'Visible', 'on');
      set(h.ballHandle, 'Visible', 'on');

      % update robot plot
      ca = cos(robot.pose.a);
      sa = sin(robot.pose.a);
      xr = h.x0*ca - h.y0*sa + robot.pose.x;
      yr = h.x0*sa + h.y0*ca + robot.pose.y;
      if (robot.id > 1)
        set(h.plotHandle, 'XData', xr, 'YData', yr, ...
                          'EdgeColor', h.roleColors(robot.role),  ...
                          'FaceColor', h.teamColors(robot.teamColor+1));
      else
        set(h.plotHandle, 'XData', xr, 'YData', yr, ...
                          'EdgeColor', h.teamColors(robot.teamColor+1), ...
                          'FaceColor', h.teamColors(robot.teamColor+1));
      end

      % update ID string
      xt = h.xm*ca - h.ym*sa + robot.pose.x;
      yt = h.xm*sa + h.ym*ca + robot.pose.y;
      set(h.textHandle, 'Position', [xt yt], ...
                        'String', num2str(robot.id));

      % update ball plot 
      if (~isempty(robot.ball))
        ball = [robot.ball.x robot.ball.y];
        xb = xr(1) + robot.ball.x*ca - robot.ball.y*sa;
        yb = yr(1) + robot.ball.x*sa + robot.ball.y*ca;
        set(h.ballHandle, 'XData', xb, 'YData', yb, ...
                          'Color', h.idColors(robot.id));
      end
    end

  end
end
