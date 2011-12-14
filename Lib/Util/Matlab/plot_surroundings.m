function [ ] = plot_surroundings( mon_struct )

    ball = mon_struct.ball;
    plot(ball.x, ball.y,'ro');
    % TODO: Plot the right color
    goal = mon_struct.goal;
    plot(goal.v1.x, goal.v1.y,'bx');
    plot(goal.v2.x, goal.v2.y,'bx');

end

