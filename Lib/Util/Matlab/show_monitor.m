function show_monitor(yuyv, labelA, robots, ball, posts, teamNumbers, nPlayers)

% Colormap
cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];

subplot(2,2,1);
rgb = yuyv2rgb( typecast(yuyv(:), 'uint32') );
rgb = reshape(rgb,[80,120,3]);
rgb = permute(rgb,[2 1 3]);
imagesc( rgb );

subplot(2,2,2);
% Process LabelA
labelA = typecast( labelA, 'uint8' );
labelA = reshape(  labelA, [80,60] );
imagesc(labelA');
colormap(cmap);
hold on;
if(ball.detect==1)
    plot_ball( ball, 1 );
end
if( posts.detect == 1 )
    postStats = bboxStats( labelA, 2, posts.postBoundingBox1 );
    plot_goalposts( postStats );
    if(posts.type==3)
        postStats = bboxStats( labelA, 2, posts.postBoundingBox2 );
        plot_goalposts( postStats );
    end
end

subplot(2,2,3);
% Draw the field for localization reasons
plot_field();
hold on;
% plot robots
for t = 1:length(teamNumbers)
    for p = 1:nPlayers
        if (~isempty(robots{p, t}))
            plot_robot_struct(robots{p, t});
        end
    end
end

subplot(2,2,4);
% What to draw here?
plot(10,10);
%hold on;

end
