function h = plot_field(handle,type)
  % plots the robocup field on the current axis
%  cla( handle );

  if type==0 % Kidsize
    fieldX = [-3.00  3.00 3.00 -3.00 -3.00];
    fieldY = [-2.00 -2.00 2.00  2.00 -2.00];
    goalX = [3.00 (3.00+0.40) (3.00+0.40) 3.00];
    goalY = [-0.70 -0.70 0.70 0.70];
    penaltyX = [3.00 (3.00-0.60) (3.00-0.60) 3.00];
    penaltyY = [-1.50 -1.50 1.50 1.50];
    spotX=1.2;
    circleR = .625;
    fieldB=[-3.5 3.5 -2.5 2.5];

%{  

%TEMPORARY VALUES FOR EXPO
    fieldX = [-2.7  2.7 2.7 -2.7 -2.7];
    fieldY = [-1.75 -1.75 1.75  1.75 -1.75];
    goalX = [2.7 (2.7+0.40) (2.7+0.40) 2.7];
    goalY = [-0.80 -0.80 0.80 0.80];
    penaltyX = [2.7 (2.7-0.65) (2.7-0.65) 2.7];
    penaltyY = [-1.22 -1.22 1.22 1.22];
    spotX=1.35;
    circleR = .1;
    fieldB=[-3.1 3.1 -2.4 2.4];
%}  


  elseif type==1 %SPL
    fieldX = [-3.00  3.00 3.00 -3.00 -3.00];
    fieldY = [-2.00 -2.00 2.00  2.00 -2.00];
    goalX = [3.00 (3.00+0.50) (3.00+0.50) 3.00];
    goalY = [-0.80 -0.80 0.80 0.80];
    penaltyX = [3.00 (3.00-0.60) (3.00-0.60) 3.00];
    penaltyY = [-1.10 -1.10 1.10 1.10];
    spotX=1.2;
    circleR = .6;
    fieldB=[-3.5 3.5 -2.5 2.5];
  elseif type==2 % Teensize
    fieldX = [-4.50  4.50 4.50 -4.50 -4.50];
    fieldY = [-3.00 -3.00 3.00  3.00 -3.00];
    goalX = [4.50 (4.50+0.40) (4.50+0.40) 4.50];
    goalY = [-1.35 -1.35 1.35 1.35];
    penaltyX = [4.50 (4.50-1.00) (4.50-1.00) 4.50];
    penaltyY = [-2.25 -2.25 2.25 2.25];
    spotX=2.4;
    circleR = .75;
    fieldB=[-5 5 -3.5 3.5];

  end
%  set(handle,'YDir','reverse');
  hold on;
  plot(fieldX, fieldY, 'g-');
  fill(goalX, goalY, 'y');
  plot(goalX, goalY, 'g-');
  fill(-goalX, goalY, 'c');
  plot(-goalX, goalY, 'g-');

  plot(penaltyX, penaltyY, 'g-');
  plot(-penaltyX, penaltyY, 'g-');

  plot(spotX,0,'go');
  plot(-spotX,0,'go');

  centerX = [0  0];
  centerY = [fieldY(1) fieldY(3)];
  plot(centerX, centerY, 'g-');

  circleT = 2*pi*[0:.01:1];
  circleX = circleR*cos(circleT);
  circleY = circleR*sin(circleT);
  hcircle = plot(circleX, circleY, 'g-');
  hold off;

  axis equal;
  axis(fieldB);

end
