function maxr=plot_vision2(data,showboundary,invert)

   maxx=0.5;
   maxy=0.5;
   maxr=0.5;

   boundaryX=data.boundaryX;
   boundaryY=data.boundaryY;

   cla;   
   hold on;

   if showboundary
	   plot(-[boundaryY(3) boundaryY(4)],[boundaryX(3) boundaryX(4)] ,'k--');
	   plot(-[boundaryY(1) boundaryY(3)],[boundaryX(1) boundaryX(3)] ,'k--');
	   plot(-[boundaryY(2) boundaryY(4)],[boundaryX(2) boundaryX(4)] ,'k--');
	   plot(-[boundaryY(1) boundaryY(2)],[boundaryX(1) boundaryX(2)] ,'k--');
	   plot(-[0 boundaryY(4)],[0 boundaryX(4)] ,'k--');
	   plot(-[0 boundaryY(3)],[0 boundaryX(3)] ,'k--');
   end
   centercross=plot(-boundaryY(5), boundaryX(5),'+');
   set(centercross,'MarkerSize',15);

   if data.ball(1)
	x0=-data.ball(3);
	y0=data.ball(2);

 	maxx=max(abs(x0),maxx);
	maxy=max(abs(y0),maxy);

	r0=0.034; %ball size
	rectangle('Position',[x0-r0 y0-r0 2*r0 2*r0],'Curvature',[1 1],...
		'EdgeColor','r','LineWidth',1);

        r_name=text(x0,y0+0.15,sprintf('%.2f,%.2f',data.ball(2),data.ball(3)));
	set(r_name,'FontSize',12,'Color','k');

	rscale=1;
	rvel=plot(-[data.ball(3) data.ball(3)+ data.ball(5) * rscale], ...
		[data.ball(2), data.ball(2)+data.ball(4)* rscale ] , 'r');
	set(rvel,'LineWidth',5);

   end
   if data.ballYellow(1)
	yball=plot(-data.ballYellow(3),data.ballYellow(2),'r+');
	set(yball,'MarkerSize',15);
   end

   if data.goalYellow(1)
	if data.goalYellow(2)==3 %Two goalpost
		plot(-data.goalYellow([4 6]),data.goalYellow([3 5]),'r+');
		x0=data.goalYellow(3);
		y0=data.goalYellow(4);
 		maxx=max(abs(x0),maxx);
		maxy=max(abs(y0),maxy);

		if invert 
		        r_name=text(-y0,x0+0.15,sprintf('R: %.2f,%.2f',x0,y0));
		else
		        r_name=text(-y0,x0+0.15,sprintf('L: %.2f,%.2f',x0,y0));
		end
		set(r_name,'FontSize',12,'Color','r');

		x0=data.goalYellow(5);
		y0=data.goalYellow(6);
 		maxx=max(abs(x0),maxx);
		maxy=max(abs(y0),maxy);


		if invert
		        r_name=text(-y0,x0+0.15,sprintf('L: %.2f,%.2f',x0,y0));
		else
		        r_name=text(-y0,x0+0.15,sprintf('R: %.2f,%.2f',x0,y0));
		end
		set(r_name,'FontSize',12,'Color','r');

	else
		x0=data.goalYellow(3);
		y0=data.goalYellow(4);

 		maxx=max(abs(x0),maxx);
		maxy=max(abs(y0),maxy);


		plot(-y0,x0,'r+')
		if data.goalYellow(2)==1 %left
		        r_name=text(-y0,x0+0.15,sprintf('L: %.2f,%.2f',x0,y0));
			set(r_name,'FontSize',12,'Color','r');
		elseif data.goalYellow(2)==2 %right
		        r_name=text(-y0,x0+0.15,sprintf('R: %.2f,%.2f',x0,y0));
			set(r_name,'FontSize',12,'Color','r');
		elseif data.goalYellow(2)==0 %unknown
		        r_name=text(-y0,x0+0.15,sprintf('U: %.2f,%.2f',x0,y0));
			set(r_name,'FontSize',12,'Color','r');
		end
	end
   end
   if data.goalCyan(1)
	if data.goalCyan(2)==3 %Two goalpost
		plot(-data.goalCyan([4 6]),data.goalCyan([3 5]),'b+');
		x0=data.goalCyan(3);
		y0=data.goalCyan(4);

 		maxx=max(abs(x0),maxx);
		maxy=max(abs(y0),maxy);

		if invert 
		        r_name=text(-y0,x0+0.15,sprintf('R: %.2f,%.2f',x0,y0));
		else
		        r_name=text(-y0,x0+0.15,sprintf('L: %.2f,%.2f',x0,y0));
		end
		set(r_name,'FontSize',12);
		x0=data.goalCyan(5);
		y0=data.goalCyan(6);

 		maxx=max(abs(x0),maxx);
		maxy=max(abs(y0),maxy);

		if invert 
		        r_name=text(-y0,x0+0.15,sprintf('L: %.2f,%.2f',x0,y0));
		else
		        r_name=text(-y0,x0+0.15,sprintf('R: %.2f,%.2f',x0,y0));
		end
		set(r_name,'FontSize',12);
	else
		x0=data.goalCyan(3);
		y0=data.goalCyan(4);

 		maxx=max(abs(x0),maxx);
		maxy=max(abs(y0),maxy);

		plot(-y0,x0,'b+');

		if data.goalCyan(2)==1 %Left
		        r_name=text(-y0,x0+0.15,sprintf('L: %.2f,%.2f',x0,y0));
			set(r_name,'FontSize',12);
		elseif data.goalCyan(2)==2 %Right
		        r_name=text(-y0,x0+0.15,sprintf('R: %.2f,%.2f',x0,y0));
			set(r_name,'FontSize',12);
		else
		        r_name=text(-y0,x0+0.15,sprintf('U: %.2f,%.2f',x0,y0));
			set(r_name,'FontSize',12);
		end

	end
  end

   if data.line(1)
	x0=double(data.line(2));
	y0=double(data.line(3));
	x1=double(data.line(4));
	y1=double(data.line(5));

	maxx=max(abs(x0),maxx);
	maxy=max(abs(y0),maxy);

	maxx=max(abs(x1),maxx);
	maxy=max(abs(y1),maxy);

	plot(-[y0 y1], [x0 x1],'k');

        aLine=atan2(y1-y0,x1-x0)*180/pi + 90;
	if aLine>180 aLine=aLine-360; end
	if aLine<-180 aLine=aLine+360; end

        r_name=text(-(y0+y1)/2,(x0+x1)/2+0.15,...
		sprintf('Line: %.2f deg',aLine));
	set(r_name,'FontSize',12);


   end


   if data.landmarkYellow(1)
	x0=double(data.landmarkYellow(2));
	y0=double(data.landmarkYellow(3));

	maxx=max(abs(x0),maxx);
	maxy=max(abs(y0),maxy);

	plot(-y0,x0,'rx');
        r_name=text(-y0,x0+0.15,sprintf('YL: %.2f,%.2f',x0,y0));
	set(r_name,'FontSize',12);
   end

   if data.landmarkCyan(1)
	x0=double(data.landmarkCyan(2));
	y0=double(data.landmarkCyan(3));

	maxx=max(abs(x0),maxx);
	maxy=max(abs(y0),maxy);

	plot(-y0,x0,'bx');
        r_name=text(-y0,x0+0.15,sprintf('BL: %.2f,%.2f',x0,y0));
	set(r_name,'FontSize',12);
   end

%{
   if data.obstacle(1)
	for j=1:data.obstacle(2)
		x0=double(data.obstacle(j*4-1));
		y0=double(data.obstacle(j*4));
		r0=0.05;
		rectangle('Position',[-y0-r0 x0-r0 2*r0 2*r0],'Curvature',[1 1],...
		'EdgeColor','k','LineWidth',3);
   end
%}

   if data.freespace(1)
	xx=[];yy=[];
	for j=1:data.freespace(2)
		x0=double(data.freespace(j*4-1));
		y0=double(data.freespace(j*4));
		xx=[xx -y0]; 
		yy=[yy x0];
		r0=0.05;
%		rectangle('Position',[-y0-r0 x0-r0 2*r0 2*r0],'Curvature',[1 1],...
%		'EdgeColor','k','LineWidth',3);
        end
	plot(xx,yy)
   end

   hold off;

   maxr=max(maxy,maxx/2)*2;
end
