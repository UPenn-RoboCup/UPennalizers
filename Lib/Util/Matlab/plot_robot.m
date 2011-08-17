function h = plot_robot(pose, ball,team,scale)


  if nargin < 4,     scale=3;  end
  if nargin < 3,     team=0;  end
  if nargin < 2,    ball = [];  end
  if nargin < 1,    pose = [0 0 0];  end


  hold on;

%  x0 = scale*[0 -.25 -.25];
%  y0 = scale*[0 -.10 +.10];

  x0 = scale*[0.1 -.05 -.05];
  y0 = scale*[0    -.05 +.05];


  ca = cos(pose(3));
  sa = sin(pose(3));
  
  xr = x0*ca - y0*sa + pose(1);
  yr = x0*sa + y0*ca + pose(2);

  if team==1 
	  hr = fill(xr, yr, 'r');
  else
	  hr = fill(xr, yr, 'b');
  end

  if ~isempty(ball),
    xb = pose(1) + ball(1)*ca - ball(2)*sa;
    yb = pose(2) + ball(1)*sa + ball(2)*ca;
    hb = plot(xb, yb, 'mo');
    set(hb, 'MarkerSize', scale*2);


    xvel = ball(3)*ca - ball(4)*sa;
    yvel = ball(3)*sa + ball(4)*ca;

    rscale=4;
    rvel=plot([xb xb+xvel*rscale], [yb yb+yvel*rscale],'r');
    set(rvel,'LineWidth',5);

  end

  hold off;

end
