function show_monitor( robots, scale, teamNumber, playerNumber )

% Robot to display
r_mon = robots{playerNumber,teamNumber}.get_monitor_struct();
if( isempty(r_mon) )
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
    if(r_mon.ball.detect==1)
        plot_ball( r_mon.ball, scale );
    end
    if( r_mon.goal.detect == 1 )
        %disp('Goal detected!');
        % Determine which bounding box:
        if(r_mon.goal.v1.scale~=0)
            pBBoxA = r_mon.goal.postBoundingBox1;
            pBBoxB = r_mon.goal.postBoundingBox2;
        else
            pBBoxA = r_mon.goal.postBoundingBox2;
            pBBoxB = r_mon.goal.postBoundingBox1;
        end
        postStats = bboxStats( label, r_mon.goal.color, pBBoxA, scale );
        plot_goalposts( postStats, scale );
        if(r_mon.goal.type==3)
            postStats = bboxStats( label, r_mon.goal.color, pBBoxB, scale );
            plot_goalposts( postStats, scale );
        end
        
    end
end   

colormap(cmap);

subplot(2,2,3);
% Draw the field for localization reasons
plot_field();
hold on;
% plot robots from the team struct
for t = 1:nTeams
    for p = 1:nPlayers
        if (~isempty(robots{p, t}))
            r_team = robots{p,t}.get_team_struct();
            plot_team_struct( r_team );
        end
    end
end

h4 = subplot(2,2,4);
% Assume that we can only see 3 meters left and right
% Assume that we do not see objects very far behind us
cla( h4 );
xlim([-3 3]);
ylim([-1 4]);
hold on;
% What to draw here?
plot_surroundings( r_mon );

end
