function plot_vision(data,scale,drawtype,invert)
   widthL0=320;heightL0=240;


   hold on;
   if data.ball(1)
	x0=double(data.ball(6));
	y0=double(data.ball(7));
	if invert 	%OP specific flip	
		x0=widthL0-x0;
		y0=heightL0-y0;
	else
	end
	r0=max(0,double(data.ball(8)/2));
	x0=x0*scale;
	y0=y0*scale;
	r0=r0*scale;
	if r0>0 
		rectangle('Position',[x0-r0 y0-r0 2*r0 2*r0],'Curvature',[1 1],...
		'EdgeColor','k','LineWidth',1);
		r1=r0*1.2;
		rectangle('Position',[x0-r1 y0-r1 2*r1 2*r1],'Curvature',[1 1],...
		'EdgeColor','w','LineWidth',1);
	end
   end
   if data.goalYellow(1)
	x0=double(data.goalYellow(7));
	y0=double(data.goalYellow(8));
	if invert
		x0=widthL0-x0;
		y0=heightL0-y0;
	end
	r0=double(data.goalYellow(9)/2);
	a0=double(-data.goalYellow(10));
	w0=double(data.goalYellow(15)/2);
	x0=x0*scale;y0=y0*scale;
	r0=r0*scale;w0=w0*scale;
	r=[cos(a0) -sin(a0);sin(a0) cos(a0)];
	x11=[x0 y0]+(r*[r0 w0]')';
	x12=[x0 y0]+(r*[-r0 w0]')';
	x21=[x0 y0]+(r*[r0 -w0]')';
	x22=[x0 y0]+(r*[-r0 -w0]')';
	plot([x11(1) x12(1)],[x11(2) x12(2)],'r','LineWidth',2);
	plot([x21(1) x22(1)],[x21(2) x22(2)],'r','LineWidth',2);
	plot([x12(1) x22(1)],[x12(2) x22(2)],'r','LineWidth',2);
	plot([x11(1) x21(1)],[x11(2) x21(2)],'r','LineWidth',2);

	if data.goalYellow(2)==3 %Two goalpost
		x0=double(data.goalYellow(11));
		y0=double(data.goalYellow(12));
		if invert
			x0=widthL0-x0;
			y0=heightL0-y0;
		end
		r0=double(data.goalYellow(13)/2);
		a0=double(-data.goalYellow(14));
		w0=double(data.goalYellow(16)/2);
		x0=x0*scale;y0=y0*scale;
		r0=r0*scale;w0=w0*scale;
		r=[cos(a0) -sin(a0);sin(a0) cos(a0)];
		x11=[x0 y0]+(r*[r0 w0]')';
		x12=[x0 y0]+(r*[-r0 w0]')';
		x21=[x0 y0]+(r*[r0 -w0]')';
		x22=[x0 y0]+(r*[-r0 -w0]')';
		plot([x11(1) x12(1)],[x11(2) x12(2)],'r','LineWidth',2);
		plot([x21(1) x22(1)],[x21(2) x22(2)],'r','LineWidth',2);
		plot([x12(1) x22(1)],[x12(2) x22(2)],'r','LineWidth',2);
		plot([x11(1) x21(1)],[x11(2) x21(2)],'r','LineWidth',2);
	end
   end

   if data.goalCyan(1)

	x0=double(data.goalCyan(7));
	y0=double(data.goalCyan(8));
	if invert
		x0=widthL0-x0;
		y0=heightL0-y0;
	end
	r0=double(data.goalCyan(9)/2);
	a0=double(-data.goalCyan(10));
	w0=double(data.goalCyan(15)/2);
	x0=x0*scale;y0=y0*scale;
	r0=r0*scale;w0=w0*scale;
	r=[cos(a0) -sin(a0);sin(a0) cos(a0)];
	x11=[x0 y0]+(r*[r0 w0]')';
	x12=[x0 y0]+(r*[-r0 w0]')';
	x21=[x0 y0]+(r*[r0 -w0]')';
	x22=[x0 y0]+(r*[-r0 -w0]')';
	plot([x11(1) x12(1)],[x11(2) x12(2)],'y','LineWidth',2);
	plot([x21(1) x22(1)],[x21(2) x22(2)],'y','LineWidth',2);
	plot([x11(1) x21(1)],[x11(2) x21(2)],'y','LineWidth',2);
	plot([x12(1) x22(1)],[x12(2) x22(2)],'y','LineWidth',2);

	if data.goalCyan(2)==3 %Two goalpost
		x0=double(data.goalCyan(11));
		y0=double(data.goalCyan(12));
		if invert
			x0=widthL0-x0;
			y0=heightL0-y0;
		end
		r0=double(data.goalCyan(13)/2);
		a0=double(-data.goalCyan(14));
		w0=double(data.goalCyan(16)/2);
		x0=x0*scale;y0=y0*scale;
		r0=r0*scale;w0=w0*scale;
		r=[cos(a0) -sin(a0);sin(a0) cos(a0)];
		x11=[x0 y0]+(r*[r0 w0]')';
		x12=[x0 y0]+(r*[-r0 w0]')';
		x21=[x0 y0]+(r*[r0 -w0]')';
		x22=[x0 y0]+(r*[-r0 -w0]')';
		plot([x11(1) x12(1)],[x11(2) x12(2)],'y','LineWidth',2);
		plot([x21(1) x22(1)],[x21(2) x22(2)],'y','LineWidth',2);
		plot([x11(1) x21(1)],[x11(2) x21(2)],'y','LineWidth',2);
		plot([x12(1) x22(1)],[x12(2) x22(2)],'y','LineWidth',2);
	end
   end

   if data.line(1)
	x0=double(data.line(6));
	y0=double(data.line(7));
	x1=double(data.line(8));
	y1=double(data.line(9));

	if invert	%they are in labelB, or 80*60 space
		x0=80-x0;
		y0=60-y0;
		x1=80-x1;
		y1=60-y1;
	end

	plot([x0 x1]*scale*4,[y0 y1]*scale*4, 'k','LineWidth',3);

   end

   if data.landmarkCyan(1)
	x0=double(data.landmarkCyan(4));
	y0=double(data.landmarkCyan(5));
	x1=double(data.landmarkCyan(6));
	y1=double(data.landmarkCyan(7));
	x2=double(data.landmarkCyan(8));
	y2=double(data.landmarkCyan(9));
	if invert	
		x0=widthL0-x0;
		y0=heightL0-y0;
		x1=widthL0-x1;
		y1=heightL0-y1;
		x2=widthL0-x2;
		y2=heightL0-y2;
	end
	x01=0.5*(x0+x1);y01=0.5*(y0+y1);
	x12=0.5*(x1+x2);y12=0.5*(y1+y2);
	x00=x0-(x01-x0);	y00=y0-(y01-y0);
	x22=x2+(x2-x12);	y22=y2+(y2-y12);

	plot([x00 x22]*scale,[y00 y22]*scale, 'k','LineWidth',10);
	plot([x00 x01]*scale,[y00 y01]*scale, 'b','LineWidth',5);
	plot([x01 x12]*scale,[y01 y12]*scale, 'y','LineWidth',5);
	plot([x12 x22]*scale,[y12 y22]*scale, 'b','LineWidth',5);
   end

   if data.landmarkYellow(1)
	x0=double(data.landmarkYellow(4));
	y0=double(data.landmarkYellow(5));
	x1=double(data.landmarkYellow(6));
	y1=double(data.landmarkYellow(7));
	x2=double(data.landmarkYellow(8));
	y2=double(data.landmarkYellow(9));
	if invert	
		x0=widthL0-x0;
		y0=heightL0-y0;
		x1=widthL0-x1;
		y1=heightL0-y1;
		x2=widthL0-x2;
		y2=heightL0-y2;
	end
	x01=0.5*(x0+x1);y01=0.5*(y0+y1);
	x12=0.5*(x1+x2);y12=0.5*(y1+y2);
	x00=x0-(x01-x0);	y00=y0-(y01-y0);
	x22=x2+(x2-x12);	y22=y2+(y2-y12);

	plot([x00 x22]*scale,[y00 y22]*scale, 'k','LineWidth',10);
	plot([x00 x01]*scale,[y00 y01]*scale, 'y','LineWidth',5);
	plot([x01 x12]*scale,[y01 y12]*scale, 'b','LineWidth',5);
	plot([x12 x22]*scale,[y12 y22]*scale, 'y','LineWidth',5);

   end

   if data.freespace(1)

	for j=1:data.freespace(2)
		x0=data.freespace((j-1)*8+5);
		ty0=data.freespace((j-1)*8+6);
                by0=data.freespace((j-1)*8+10);
%		r0=20*scale;
	%%	if invert	
	%%		x0=widthL0*scale-x0;
	%%		y0=heightL0*scale-y0;
	%%		l=plot([x0 x0],[y0 heightL0*scale],'w--');
	%%		set(l,'LineWidth',3);
	%%	else
			l=plot([x0 x0],[ty0 by0],'w--');
                        set(l,'LineWidth',2);


	%%	end

%		rectangle('Position',[x0-r0 y0-r0 2*r0 2*r0],'Curvature',[0 0],...
%		'EdgeColor','w','LineWidth',3);
   end

   hold off;
end
