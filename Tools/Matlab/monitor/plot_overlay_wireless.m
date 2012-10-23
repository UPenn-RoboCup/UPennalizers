function plot_overlay_wireless(r_wireless)
  if( r_wireless.goal > 0 )
    hold on;
    if (~isempty(r_wireless.goalpostStat1))
      plot_goalposts(r_wireless.goalpostStat1,4)
      if(r_wireless.goal == 4)
        if (~isempty(r_wireless.goalpostStat2))
          plot_goalposts(r_wireless.goalpostStat2,4);
	end
      end
    end
    hold off;
  end

%Subfunctions

  function plot_ball( ballStats, scale )
    radius = (ballStats.axisMajor / 2) / scale;
    centroid = [ballStats.centroid.x ballStats.centroid.y] / scale;
    ballBox = [centroid(1)-radius centroid(2)-radius 2*radius 2*radius];
    plot( centroid(1), centroid(2),'k+')
    if( ~isnan(ballBox) )
      rectangle('Position', ballBox, 'Curvature',[1,1])
      strballpos = sprintf('%.2f %.2f',ballStats.x,ballStats.y);
      b_name=text(centroid(1),centroid(2)+radius, strballpos);
      set(b_name,'FontSize',8);
    end
  end

  function plot_goalposts( postStats,scale)
    x0=postStats.x;
    y0=postStats.y;
    w0=postStats.a/2;
    h0=postStats.b/2;
    a0=postStats.o;
    x0=x0/scale;y0=y0/scale;
    w0=w0/scale;h0=h0/scale;
    r=[cos(a0) sin(a0);-sin(a0) cos(a0)];
    x11=[x0 y0]+(r*[w0 h0]')';
    x12=[x0 y0]+(r*[-w0 h0]')';
    x21=[x0 y0]+(r*[w0 -h0]')';
    x22=[x0 y0]+(r*[-w0 -h0]')';

    goalcolor='r';goalwidth=2;
    plot([x11(1) x12(1)],[x11(2) x12(2)],goalcolor,'LineWidth',goalwidth);
    plot([x21(1) x22(1)],[x21(2) x22(2)],goalcolor,'LineWidth',goalwidth);
    plot([x12(1) x22(1)],[x12(2) x22(2)],goalcolor,'LineWidth',goalwidth);
    plot([x11(1) x21(1)],[x11(2) x21(2)],goalcolor,'LineWidth',goalwidth);
  end

end

