function h = plot_localization(axesHandle, dispDir)
  % store the current axes
  currAxes = gca;

  if (nargin < 1 || isempty(axesHandle))
    axesHandle = gca;
  end

  if (nargin < 2)
    dispDir = 'y';
  end


  h.axesHandle = axesHandle;
  h.dispDir = dispDir;

  % clear the axes
  axes(h.axesHandle);
  cla(h.axesHandle);

  % plot the field
  plot_field();
  hold on;
  if (h.dispDir == 'y')
    set(h.axesHandle, 'CameraUpVector', [1, 0, 0]);
  elseif (h.dispDir == 'b' || h.dispDir == 'c')
    set(h.axesHandle, 'CameraUpVector', [-1, 0, 0]);
  end


  % cell array of the robot plot handles (teamColor x playerID)
  h.robotPlots = cell(0,0);

  h.update = @update;

  % reset curret axes
  axes(currAxes);

  function update(robots)
    % initialize new plots if needed
    for i = 1:prod(size(robots))
      robot = robots{i};

      if (~isempty(robot))
        % create new plot handle if needed
        if (i > prod(size(h.robotPlots)))
          h.robotPlots{i} = plot_robot();
        end

        % update plot
        h.robotPlots{i}.update(robot);
      end
    end
  end

end
