function [ ] = plot_surroundings( mon_struct )
    % NOTE: x and y are reversed because for the robot,
    % x is forward backward, but for plotting, y is up and down
    % Also, there is a negative one, since for the robot left is positive
    % TODO: check that this is right...
    
    ball = mon_struct.ball;
    if( ball.detect )
        plot(-1*ball.y, ball.x,'ro');
        strballpos = strcat('Ball: ',num2str(-1*ball.y,'%1.2f'),',',...
                            num2str(ball.x,'%1.2f'));
        text(-1*ball.y, ball.x+0.3, strballpos);
    end
    % TODO: Plot the right color
    goal = mon_struct.goal;
    if( goal.detect==1 )
        if(goal.color==2) % yellow
            marker = 'm';
        else
            marker = 'b';
        end
        marker = strcat(marker,'x');
        if( goal.v1.scale ~= 0 )
            plot(-1*goal.v1.y, goal.v1.x, marker,'MarkerSize',12);
        end
        if( goal.v2.scale ~= 0 )
            plot(-1*goal.v2.y, goal.v2.x, marker,'MarkerSize',12);
        end
    end

end

