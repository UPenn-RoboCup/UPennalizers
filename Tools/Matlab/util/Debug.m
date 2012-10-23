function Debug

global VISIONDATA WORLDDATA POSE
global DEBUG

if isempty(DEBUG),
  DEBUG.cmap = cmapRobocup;
  DEBUG.nupdate = 0;
end

DEBUG.nupdate = DEBUG.nupdate + 1;

fprintf(1, '\n');
if ~isempty(VISIONDATA),

  subplot(2,2,1);
  image(VISIONDATA.labelA');
  colormap(DEBUG.cmap);

  subplot(2,2,2);
  image(VISIONDATA.labelB');
  colormap(DEBUG.cmap);
  stitle = 'B';
  hold on;
  if (VISIONDATA.ball.detect),
    propsB = VISIONDATA.ball.propsB;
    stitle = [stitle sprintf(' ball:%d', propsB.area)];
    h = plot(propsB.centroid(1)+1, propsB.centroid(2)+1, 'ko');
    set(h, 'MarkerSize', 15);
  end
  if (VISIONDATA.goalYellow.detect),
    goal = VISIONDATA.goalYellow;
    propsB = goal.propsB;
    stitle = [stitle sprintf(' ypost:%d %d', propsB.area)];
    sym = 'k^';
    if length(goal.type) == 1,
      if (goal.type == 1)
        sym = 'k<';
      elseif (goal.type == 2)
        sym = 'k>';
      else
        sym = 'kv';
      end
    end
    for i = 1:length(propsB),
      h = plot(propsB(i).centroid(1)+1, propsB(i).centroid(2)+1, sym);
      set(h, 'MarkerSize', 10);
    end
  end
  if (VISIONDATA.goalCyan.detect),
    goal = VISIONDATA.goalCyan;
    propsB = goal.propsB;
    stitle = [stitle sprintf(' cpost:%d %d', propsB.area)];
    sym = 'k^';
    if length(goal.type) == 1,
      if (goal.type == 1)
        sym = 'k<';
      elseif (goal.type == 2)
        sym = 'k>';
      else
        sym = 'kv';
      end
    end
    for i = 1:length(propsB),
      h = plot(propsB(i).centroid(1)+1, propsB(i).centroid(2)+1, sym);
      set(h, 'MarkerSize', 10);
    end
  end
  if (VISIONDATA.line.detect),
    propsB = VISIONDATA.line.propsB;
    stitle = [stitle sprintf(' line:%d', propsB.count)];
    plot(propsB.endpoint(:,1)+1, propsB.endpoint(:,2)+1, 'w-');
    plot(propsB.centroid(1)+1, propsB.centroid(2)+1, 'wx');
  end
  if (VISIONDATA.spot.detect),
    propsB = VISIONDATA.spot.propsB;
    stitle = [stitle sprintf(' spot:%d', propsB.area)];
    h = plot(propsB.centroid(1)+1, propsB.centroid(2)+1, 'ws');
    set(h, 'MarkerSize', 10);
  end
  title(stitle);
  hold off;

  subplot(2,2,3);
  plot(0, 0, 'k.');
  hold on;
  if VISIONDATA.ball.detect,
    plot(-VISIONDATA.ball.v(2), VISIONDATA.ball.v(1), 'go');
  end
  if VISIONDATA.goalYellow.detect,
    sym = 'r^';
    if length(VISIONDATA.goalYellow.type) == 1,
      if (VISIONDATA.goalYellow.type == 1)
        sym = 'r<';
      elseif (VISIONDATA.goalYellow.type == 2)
        sym = 'r>';
      else
        sym = 'rv';
      end
    end
    plot(-VISIONDATA.goalYellow.v(2,:), VISIONDATA.goalYellow.v(1,:), sym);
  end
  if VISIONDATA.goalCyan.detect,
    sym = 'b^';
    if length(VISIONDATA.goalCyan.type) == 1,
      if (VISIONDATA.goalCyan.type == 1)
        sym = 'b<';
      elseif (VISIONDATA.goalCyan.type == 2)
        sym = 'b>';
      else
        sym = 'bv';
      end
    end
    plot(-VISIONDATA.goalCyan.v(2,:), VISIONDATA.goalCyan.v(1,:), sym);
  end
  if (VISIONDATA.spot.detect),
    plot(-VISIONDATA.spot.v(2), VISIONDATA.spot.v(1), 'kd');
  end
  if (VISIONDATA.line.detect),
    plot(-VISIONDATA.line.vendpoint(2,:), VISIONDATA.line.vendpoint(1,:), 'k-');
    plot(-VISIONDATA.line.vcentroid(2), VISIONDATA.line.vcentroid(1), 'kx');
  end
  hold off;
  axis([-4 4 0 7]);
  
  if VISIONDATA.ball.detect,
    fprintf(1,'Ball: %.3f %.3f\n', VISIONDATA.ball.v(1:2));
    %      offset = WALK.getBodyOffset();
    %      DEBUG.data = [DEBUG.data [offset(2) VISIONDATA.ball.v(2)]'];
  end
  if VISIONDATA.goalYellow.detect,
    fprintf(1,'Goal Yellow: %.3f %.3f, %.3f %.3f %d\n', VISIONDATA.goalYellow.v(1:2,:));
  end
  if VISIONDATA.goalCyan.detect,
    fprintf(1,'Goal Cyan: %.3f %.3f, %.3f %.3f %d\n', VISIONDATA.goalCyan.v(1:2,:));
  end
end

if ~isempty(POSE),
  subplot(2,2,4);
  plot_field();
  hold on;
  plot(POSE.x, POSE.y, 'k.');
  hold off;
  plot_robot(WORLDDATA.pose, [WORLDDATA.ball.x WORLDDATA.ball.y]);
  view(180, 90);
end

drawnow;
end


function cmap = cmapRobocup
% Colormap to display lut colors:
  index = [0:255];
  bits = zeros(8,256);
  for i = 1:8,
    b2 = 2.^(i-1);
    bits(i,:) = floor(rem(index,2*b2)/b2);
  end
  
  colors = .7*[1 .5 0; % Orange
               1 1 0; % Yellow
               0 .5 1; % Cyan
               0 .5 0; % Field
               .5 .5 .5; % White
               0 0 0; % Unused
               0 0 0; % Unused
               0 0 0 % Unused
              ];
  cmap = colors'*bits;
  cmap = min(cmap', 1);
end
