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


h1 = subplot(2,2,1);
    plot_yuyv( h1, rgb );

h2 = subplot(2,2,2);
    plot_label( h2, label, r_mon, scale, cmap);


h3 = subplot(2,2,3);
    plot_team( h3, robots, nTeams, nPlayers);


h4 = subplot(2,2,4);
    plot_surroundings( h4, r_mon );


    function plot_yuyv( handle, rgb )
        % Process YUYV
        cla(handle);
        if( ~isempty(rgb) )
            imagesc( rgb );
        end
    end

    function plot_label( handle, label, r_mon, scale, cmap)
        % Process label
        cla(handle);
        if( ~isempty(label) )
            imagesc(label);
            colormap(cmap);
            xlim([0 size(label,2)]);
            ylim([0 size(label,1)]);
    
            if(r_mon.ball.detect==1)
                hold on;
                plot_ball( r_mon.ball, scale );
                hold off;
            end
            if( r_mon.goal.detect == 1 )
                hold on;
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
                hold off;
            end
        end 
    end

    function plot_team( handle, robots, nTeams, nPlayers)
        % Draw the field for localization reasons
        cla(handle);
        plot_field();
        hold on;
        % plot robots from the team struct
        for t = 1:nTeams
            for p = 1:nPlayers
                if (~isempty(robots{p, t}))
                    r_struct = robots{p,t}.get_team_struct();
                    plot_team_struct( r_struct );
                end
            end
        end
        hold off;
    end

end
