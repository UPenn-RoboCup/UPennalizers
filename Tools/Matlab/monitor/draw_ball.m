function draw_ball(h_axes, ball, robot, scale)
  x0 = robot.pose{1};
  y0 = robot.pose{2};
  ca = cos(robot.pose{3});
  sa = sin(robot.pose{3});

  ballt= robot.time - ball.t;
  xb = x0 + ball.x * ca - ball.y * sa;   
  yb = y0 + ball.x * sa + ball.y * ca;
  %hb = plot(xb, yb, [idColors(robot_struct.id) 'o']);
  hold(h_axes, 'on');
  hb = plot(h_axes, xb, yb, 'ro');

  if ballt<0.5 
    plot(h_axes, [x0 xb],[y0 yb],'r');
    set(hb, 'MarkerSize', 8/scale);
%{
    ball_vel=[robot.ball.vx robot.ball.vy];
    xbv =  ball_vel(1)*ca - ball_vel(2)*sa;   
    ybv =  ball_vel(1)*sa + ball_vel(2)*ca;
    qvscale = 2;
    quiver(h_axes, xb, yb, qvscale*xbv/scale, qvscale*ybv/scale,...
	         0,'r','LineWidth',2/scale );
%}
  else
    %TODO: add last seen time info
  end

  hold(h_axes, 'off');
end


