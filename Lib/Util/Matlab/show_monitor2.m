function show_monitor2( robots )

% RObot to display
r = robots{1,1};
labelA = r.get_labelA();
rgb = r.get_rgb();

% Colormap
cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];

subplot(2,2,1);
% Process YUYV
if( ~isempty(rgb) )
    imagesc( rgb );
end

subplot(2,2,2);
% Process LabelA
if( ~isempty(labelA) )
    imagesc(labelA);
    xlim([0 size(labelA,2)]);
    ylim([0 size(labelA,1)]);
    hold on;
    if(ball.detect==1)
        plot_ball( ball, scale );
    end
    
    if( posts.detect == 1 )
        postStats = bboxStats( labelA, posts.color, posts.postBoundingBox1 );
        plot_goalposts( postStats, scale );
        if(posts.type==3)
            postStats = bboxStats( labelA, posts.color, posts.postBoundingBox2 );
            plot_goalposts( postStats, scale );
        end
    end
end   
%else
     % Plot a random image indicating nothing received
%     imagesc( magic(64) );
%end
colormap(cmap);

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
