function h = plot_field()

  fieldX = [-3.00  3.00 3.00 -3.00 -3.00];
  fieldY = [-2.00 -2.00 2.00  2.00 -2.00];
  plot(fieldX, fieldY, 'g-');
  hold on

  goalX = [3.00 (3.00+0.40) (3.00+0.40) 3.00];
  goalY = [-0.70 -0.70 0.70 0.70];
  fill(goalX, goalY, 'y');
  plot(goalX, goalY, 'g-');
  fill(-goalX, goalY, 'c');
  plot(-goalX, goalY, 'g-');

  penaltyX = [3.00 (3.00-0.60) (3.00-0.60) 3.00];
  penaltyY = [-1.50 -1.50 1.50 1.50];
  plot(penaltyX, penaltyY, 'g-');
  plot(-penaltyX, penaltyY, 'g-');

  centerX = [0  0];
  centerY = [-2.00 2.00];
  plot(centerX, centerY, 'g-');

  circleT = 2*pi*[0:.01:1];
  circleX = .625*cos(circleT);
  circleY = .625*sin(circleT);
  hcircle = plot(circleX, circleY, 'g-');
  hold off;

  axis equal;
  axis([-3.5 3.5 -2.5 2.5]);

end
