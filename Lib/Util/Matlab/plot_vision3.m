function plot_vision3(data,showboundary,pose)

   ca=cos(data.pose(3));
   sa=sin(data.pose(3));
   boundaryX_g=data.pose(1)+ data.boundaryX*ca- data.boundaryY*sa;
   boundaryY_g=data.pose(2)+ data.boundaryX*sa+ data.boundaryY*ca;
   if showboundary
	   plot([boundaryX_g(3) boundaryX_g(4)],[boundaryY_g(3) boundaryY_g(4)] ,'k--');
  	   plot([boundaryX_g(1) boundaryX_g(3)],[boundaryY_g(1) boundaryY_g(3)] ,'k--');
	   plot([boundaryX_g(2) boundaryX_g(4)],[boundaryY_g(2) boundaryY_g(4)] ,'k--');
	   plot([boundaryX_g(1) boundaryX_g(2)],[boundaryY_g(1) boundaryY_g(2)] ,'k--');
   end
   centercross=plot(boundaryX_g(5), boundaryY_g(5),'+');
   set(centercross,'MarkerSize',5);

   hold on;

   if data.ball(1)
	[x0,y0]=pose_global([data.ball(2),data.ball(3)],data.pose);
	plot([x0 data.pose(1)],[y0 data.pose(2)],'r')
   end


   if data.ballYellow(1)
	[x, y]=pose_global([data.ballYellow(2),data.ballYellow(3)],data.pose);
	yball=plot(x,y,'r+');
	set(yball,'MarkerSize',15);
   end

   if data.goalYellow(1)
	if data.goalYellow(2)==3 %Two goalpost

		x0=data.goalYellow(3);
		y0=data.goalYellow(4);
		[x0, y0]=pose_global([x0 y0],data.pose);

		x1=data.goalYellow(5);
		y1=data.goalYellow(6);
		[x1, y1]=pose_global([x1 y1],data.pose);

		plot([x0 x1],[y0 y1],'r+');
		plot([x0 data.pose(1)],[y0 data.pose(2)],'r')
		plot([x1 data.pose(1)],[y1 data.pose(2)],'r')
	else
		x0=data.goalYellow(3);
		y0=data.goalYellow(4);
		[x0, y0]=pose_global([x0 y0],data.pose);

		plot(x0, y0,'r+');
		plot([x0 data.pose(1)],[y0 data.pose(2)],'r')
	end
   end


   if data.goalCyan(1)
	if data.goalCyan(2)==3 %Two goalpost
		x0=data.goalCyan(3);
		y0=data.goalCyan(4);
		[x0, y0]=pose_global([x0 y0],data.pose);

		x1=data.goalCyan(5);
		y1=data.goalCyan(6);
		[x1, y1]=pose_global([x1 y1],data.pose);

		plot([x0 x1],[y0 y1],'b+');
		plot([x0 data.pose(1)],[y0 data.pose(2)],'b')
		plot([x1 data.pose(1)],[y1 data.pose(2)],'b')
	else
		x0=data.goalCyan(3);
		y0=data.goalCyan(4);
		[x0, y0]=pose_global([x0 y0],data.pose);

		plot(x0, y0,'b+');
		plot([x0 data.pose(1)],[y0 data.pose(2)],'b')
	end
  end

   if data.line(1)
	x0=double(data.line(2));
	y0=double(data.line(3));
	x1=double(data.line(4));
	y1=double(data.line(5));

	[x0, y0]=pose_global([x0 y0],data.pose);
	[x1, y1]=pose_global([x1 y1],data.pose);
	plot([x0 x1],[y0 y1],'k');
	plot([(x0+x1)/2 data.pose(1)],[(y0+y1)/2 data.pose(2)],'k')

   end

   if data.landmarkYellow(1)
	x0=double(data.landmarkYellow(2));
	y0=double(data.landmarkYellow(3));
	[x0, y0]=pose_global([x0 y0],data.pose);

	plot(x0,y0,'go');
	plot([x0 data.pose(1)],[y0 data.pose(2)],'g')
   end

   if data.landmarkCyan(1)
	x0=double(data.landmarkCyan(2));
	y0=double(data.landmarkCyan(3));
	[x0, y0]=pose_global([x0 y0],data.pose);

	plot(x0,y0,'bo');
	plot([x0 data.pose(1)],[y0 data.pose(2)],'b')
   end


   hold off;
end

function [px,py]=pose_global(pRel,pOrg)
    ca=cos(pOrg(3));
    sa=sin(pOrg(3));

    px=pOrg(1)+ca*pRel(1)-sa*pRel(2);
    py=pOrg(2)+sa*pRel(1)+ca*pRel(2); 
end
