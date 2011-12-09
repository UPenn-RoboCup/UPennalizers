function show_monitor( robots, scale, teamNumber, playerNumber )

% Robot to display
r = robots{playerNumber,teamNumber}.get_monitor_struct();
if( isempty(r) )
    disp('Empty monitor struct!');
    return;
end
if( scale == 1 )
    label = robots{playerNumber,teamNumber}.get_labelA();
else
    label = robots{playerNumber,teamNumber}.get_labelB();
end
rgb = robots{playerNumber,teamNumber}.get_rgb();

nTeams = size(robots,2);
nPlayers = size(robots,1);

% Colormap
cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];

subplot(2,2,1);
% Process YUYV
if( ~isempty(rgb) )
    imagesc( rgb );
end

subplot(2,2,2);
% Process label
if( ~isempty(label) )
    imagesc(label);
    xlim([0 size(label,2)]);
    ylim([0 size(label,1)]);
    hold on;
    if(r.ball.detect==1)
        plot_ball( r.ball, scale );
    end
    if( r.goal.detect == 1 )
        %disp('Goal detected!');
        % Determine which bounding box:
        if(r.goal.v1.scale~=0)
            pBBoxA = r.goal.postBoundingBox1;
            pBBoxB = r.goal.postBoundingBox2;
        else
            pBBoxA = r.goal.postBoundingBox2;
            pBBoxB = r.goal.postBoundingBox1;
        end
        postStats = bboxStats( label, r.goal.color, pBBoxA, scale );
        plot_goalposts( postStats, scale );
        if(r.goal.type==3)
            postStats = bboxStats( label, r.goal.color, pBBoxB, scale );
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
for t = 1:nTeams
    for p = 1:nPlayers
        if (~isempty(robots{p, t}))
            r_struct = robots{p,t}.get_monitor_struct();
            plot_robot_struct( r_struct );
        end
    end
end

subplot(2,2,4);
% What to draw here?
plot(10,10);
%hold on;

end
