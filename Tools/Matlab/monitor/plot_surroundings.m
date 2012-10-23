function [ ] = plot_surroundings( handle, mon_struct )
    % NOTE: x and y are reversed because for the robot,
    % x is forward backward, but for plotting, y is up and down
    % Also, there is a negative one, since for the robot left is positive
    % TODO: check that this is right...
    
    cla( handle );
    % Assume that we can only see 3 meters left and right
    % Assume that we do not see objects very far behind us

    x_lim=[-2 2];
    y_lim=[0 4];
    xlim(x_lim);
    ylim(y_lim);


    hold on;
    plot_fov(mon_struct.fov);
    plot_ball(mon_struct.ball);
    plot_goal(mon_struct.goal);
    plot_landmark(mon_struct.landmark);
    plot_line(mon_struct.line);
    plot_corner(mon_struct.corner);
		plot_freespace(mon_struct.free);
    hold off;

    %subfunctions
    function plot_fov(fov)    %draw vision boundary
      plot(-[fov.TL(2) fov.TR(2)],[fov.TL(1) fov.TR(1)],'k--');
      plot(-[fov.BL(2) fov.BR(2)],[fov.BL(1) fov.BR(1)],'k--');
      plot(-[fov.TL(2) fov.BL(2)],[fov.TL(1) fov.BL(1)],'k--');
      plot(-[fov.TR(2) fov.BR(2)],[fov.TR(1) fov.BR(1)],'k--');
    end

    function plot_ball(ball)
      if( ball.detect )
        posx=-1*ball.y;posy=ball.x;
        posx=min(max(posx,x_lim(1)),x_lim(2));
        posy=min(max(posy,y_lim(1)),y_lim(2));

        plot(posx, posy,'ro');

        posx2 = -1* (ball.y+ball.vy);
        posy2 = (ball.x+ball.vx);

        posx2=min(max(posx2,x_lim(1)),x_lim(2));
        posy2=min(max(posy2,y_lim(1)),y_lim(2));

        plot([posx posx2],[posy posy2],'r--','LineWidth',2);

        strballpos = sprintf('Ball: %.2f %.2f\n Vel: %.2f %.2f',...
		ball.x,ball.y,ball.vx,ball.vy);
        b_name=text(posx-0.3, posy-0.3, strballpos);
        set(b_name,'FontSize',10);
      end
    end

    function plot_goal(goal)
      if( goal.detect==1 )
        if(goal.color==2) marker = 'm'; % yellow
        else marker = 'b';   end
	
        if( goal.v1.scale ~= 0 )
            if goal.type==0 
              marker1 = strcat(marker,'+');%Unknown post
	    elseif goal.type==2
              marker1 = strcat(marker,'>');%Right post
	    else
              marker1 = strcat(marker,'<');%Left post
	    end
            posx=-1*goal.v1.y;posy=goal.v1.x;
            posx=min(max(posx,x_lim(1)),x_lim(2));
            posy=min(max(posy,y_lim(1)),y_lim(2));
            plot(posx,posy, marker1,'MarkerSize',12);
	    g_name1=text(posx-0.30,posy-0.3,sprintf('%.2f,%.2f',goal.v1.x,goal.v1.y));
	    set(g_name1,'FontSize',10);
        end
        if( goal.v2.scale ~= 0 )
            marker1 = strcat(marker,'>'); %right post 
            posx=-1*goal.v2.y;posy=goal.v2.x;
            posx=min(max(posx,x_lim(1)),x_lim(2));
            posy=min(max(posy,y_lim(1)),y_lim(2));
            plot(posx,posy, marker1,'MarkerSize',12);
	    g_name2=text(posx-0.30,posy-0.3,sprintf('%.2f,%.2f',goal.v2.x,goal.v2.y));
	    set(g_name2,'FontSize',10);
        end
      end
    end 

    function plot_landmark(landmark)    
      if (landmark.detect==1)
	if (landmark.color==2) marker1='m';marker2='b';% yellow
        else  marker1='b';marker2='m';	end
        marker1 = strcat(marker1,'x');
        posx=-1*landmark.v(2);posy=landmark.v(1);
        posx=min(max(posx,x_lim(1)),x_lim(2));
        posy=min(max(posy,y_lim(1)),y_lim(2));

        plot(posx,posy, marker1,'MarkerSize',12);
        g_name2=text(posx-0.30,posy-0.3,sprintf('%.2f,%.2f',landmark.v(1),landmark.v(2)));
        set(g_name2,'FontSize',10);
      end
     end

    function plot_line(line,scale)
      if( line.detect==1 )
        nLines=line.nLines;
        for i=1:nLines
          v1=line.v1{i};
          v2=line.v2{i};
          plot(-[v1(2) v2(2)],[v1(1) v2(1)],'k','LineWidth',2);
        end
      end
    end


    function plot_corner(corner,scale)
      if corner.detect==1
        if corner.type==1
          marker='r';
        else
          marker='b';
        end     
        v=corner.v;
        v1=corner.v1;
        v2=corner.v2;
        plot(-[v(2) v2(2)],[v(1) v2(1)],marker,'LineWidth',4);
        plot(-[v1(2) v(2)],[v1(1) v(1)],marker,'LineWidth',4);
      end
    end

		function plot_freespace(free)
		  if free.detect == 1
        plot(-free.x, free.y, '--');
			end
		end

%{
    bd = mon_struct.bd;
    if( bd.detect == 1 )
        % show top boundary
		plot(bd.topx,bd.topy);
		% show bottom boundary
		plot(bd.btmx,bd.btmy);
		% close boundary
		plot([bd.topx(1),bd.btmx(1)],[bd.topy(1),bd.btmy(1)]);
		plot([bd.topx(bd.nCol),bd.btmx(bd.nCol)],[bd.topy(bd.nCol),bd.btmy(bd.nCol)]);    
    end
%}
end

