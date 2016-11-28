function [] = plot_occmap( handle, occ )
% plots the occupancy map on robot coordinate
    cla(handle);
    
	maxr = 1.0;
	for Order = 1 : occ.div 
		Idx = (Order-1) * 4 + 1;
		midTheta = (Order-1)*occ.interval;
		occ.theta(Idx) = midTheta - occ.halfInter;
		occ.theta(Idx+1) = midTheta - occ.halfInter;
		occ.theta(Idx+2) = midTheta + occ.halfInter;
	 	occ.theta(Idx+3) = midTheta + occ.halfInter;
		occ.rho(Idx) = 0;
		occ.rho(Idx+1) = min(occ.r(occ.div-Order+1),maxr);
		occ.rho(Idx+2) = min(occ.r(occ.div-Order+1),maxr);
		occ.rho(Idx+3) = 0;
	end
	idx = find(occ.theta<0);
	occ.theta(idx) = occ.theta(idx) + 2*pi;
	polar(occ.theta,occ.rho);
	[occ.x,occ.y] = pol2cart(occ.theta,occ.rho,'b');
	patch(occ.x,occ.y,[0 0 1]);
	view(-90,90);
