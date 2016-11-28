function h=costmap()
	global COSTMAP
	
	h=[];

	h.div = 0.1;
	h.x=[-4.5:h.div:4.5];
	h.y=[-3:h.div:3];
	h.xdim = size(h.x,2);
	h.ydim = size(h.y,2);
	h.dist = ones(h.xdim,h.ydim)*100;
	h.cost2 = zeros(h.xdim,h.ydim);


	h.traj=[];

	h.pose=[1 1];
	h.target=[1 1];

	h.openset=[];
	h.closedset=[];


	h.draw = @draw;
	h.draw2 = @draw2;
	h.draw3 = @draw3;
	h.calculate_trajectory = @calculate_trajectory;
	h.draw_trajectory = @draw_trajectory;
	h.update_cost = @update_cost;
	h.update_cost2 = @update_cost2;
	h.update_value = @update_value;

	[h.x1,h.x2]=meshgrid(h.x,h.y);
  	
	


	function draw(robot_struct,r_mon)
  	pose = [robot_struct.pose.x robot_struct.pose.y];
		pose_target = [robot_struct.pose_target(1) robot_struct.pose_target(2)];
		%contour(COSTMAP.x,COSTMAP.y,COSTMAP.cost_gaussian);
		surf(COSTMAP.x,COSTMAP.y,COSTMAP.cost_gaussian,'EdgeColor','none'); 
  	axis(gca, [-5 5 -3.5 3.5]);
  	hold on;
		px=COSTMAP.pose(1)*COSTMAP.div+COSTMAP.x(1);
  	py=COSTMAP.pose(2)*COSTMAP.div+COSTMAP.y(1);
  	tx=COSTMAP.target(1)*COSTMAP.div+COSTMAP.x(1);
  	ty=COSTMAP.target(2)*COSTMAP.div+COSTMAP.y(1);

  	plot(px,py,'O',tx,ty,'X');
  	hold off;  	
	end

	function draw2(robot_struct,r_mon)
  	%surf(x,y,f,'EdgeColor','none');

  	pose = [robot_struct.pose.x robot_struct.pose.y];
		pose_target = [robot_struct.pose_target(1) robot_struct.pose_target(2)];
		surf(COSTMAP.x,COSTMAP.y,COSTMAP.dist','EdgeColor','none'); %'
  	axis(gca, [-5 5 -3.5 3.5]);
  	hold on;

  	px=COSTMAP.pose(1)*COSTMAP.div+COSTMAP.x(1);
  	py=COSTMAP.pose(2)*COSTMAP.div+COSTMAP.y(1);
  	tx=COSTMAP.target(1)*COSTMAP.div+COSTMAP.x(1);
  	ty=COSTMAP.target(2)*COSTMAP.div+COSTMAP.y(1);

  	plot3(px,py,110*ones(size(px)),'O',tx,ty,110*ones(size(tx)),'X');
  	hold off;  	
	end

	function draw3(robot_struct,r_mon)
		surf(COSTMAP.x,COSTMAP.y,COSTMAP.cost2','EdgeColor','none'); %'
  	axis(gca, [-5 5 -3.5 3.5]);
  end




	function f = gaussian(x0)
		mu=[x0(1) x0(2)];
		sigma = [1 0;0 1]*0.1;
		f=mvnpdf([COSTMAP.x1(:),COSTMAP.x2(:)],mu,sigma);
		f=reshape(f,length(COSTMAP.y),length(COSTMAP.x));
	end

	function update_cost(robot_struct,r_mon)
		pose = [robot_struct.pose.x robot_struct.pose.y];
		pose_target = [robot_struct.pose_target(1) robot_struct.pose_target(2)];

		pose_index_i = round( ( pose(1)-COSTMAP.x(1) )/COSTMAP.div)+1;
		pose_index_j = round( ( pose(2)-COSTMAP.y(1) )/COSTMAP.div)+1;
		target_index_i = round( ( pose_target(1)-COSTMAP.x(1) )/COSTMAP.div)+1;
		target_index_j = round( ( pose_target(2)-COSTMAP.y(1) )/COSTMAP.div)+1;
		pose_index_i = max(1,min(COSTMAP.xdim,pose_index_i));
		pose_index_j = max(1,min(COSTMAP.ydim,pose_index_j));
		target_index_i = max(1,min(COSTMAP.xdim,target_index_i));
		target_index_j = max(1,min(COSTMAP.ydim,target_index_j));
		COSTMAP.pose = [pose_index_i pose_index_j];
		COSTMAP.target = [target_index_i target_index_j];

		f=gaussian([r_mon.obspole.x(1) r_mon.obspole.y(1)]);
		for i=2:r_mon.obspole.num
			f=f+gaussian([r_mon.obspole.x(i) r_mon.obspole.y(i)]);
		end
		COSTMAP.cost_gaussian = f;
	end

	function update_cost2(type)
		if type==0
			COSTMAP.cost2 = zeros(COSTMAP.xdim,COSTMAP.ydim);
		elseif type==1	
			for i=1:COSTMAP.xdim
				for j=1:COSTMAP.ydim
					x = i*COSTMAP.div+COSTMAP.x(1);
					y = j*COSTMAP.div+COSTMAP.y(1);
					goal1 = [4.5,-0.8];
					goal2 = [4.5,0.8];				
					angle = atan2(goal1(1)-x,goal1(2)-y)-atan2(goal2(1)-x,goal2(2)-y);
					anglemax = 45*pi/180;
					anglemin= 10*pi/180;
					cost = max(0,min(anglemax,angle)-anglemin)/(anglemax-anglemin);

					factor = 1;

					COSTMAP.cost2(i,j)=1 + (1-cost)*factor;
				end
			end
		elseif type==2

			for i=1:COSTMAP.xdim
				for j=1:COSTMAP.ydim
					x = i*COSTMAP.div+COSTMAP.x(1);
					y = j*COSTMAP.div+COSTMAP.y(1);

					r=sqrt(x^2+y^2);
					max_r = 2.0;
					cost =    ( max_r - min(r,max_r) ) / max_r;
					factor = 3;
					COSTMAP.cost2(i,j)=1 + cost *factor;
				end
			end





		end
	end




	function update_value(robot_struct,r_mon)
		init_value_dijkstra();
		update_value_dijkstra(robot_struct,r_mon);
	end


	neighbor=[-1 -1;-1 0;-1 1; 0 -1; 0 0; 0 1; 1 -1; 1 0; 1 1];
	dist_cost = [sqrt(2); 1; sqrt(2);1; 0; 1;sqrt(2); 1; sqrt(2)];
	dist_cost2 = [sqrt(2) 1 sqrt(2);1 0 1;sqrt(2) 1 sqrt(2)];

	neighbor_s=[-1 -1;-1 0;-1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];
	dist_cost_s = [sqrt(2); 1; sqrt(2);1; 1;sqrt(2); 1; sqrt(2)];

	function init_value_dijkstra()
		COSTMAP.dist = ones(COSTMAP.xdim,COSTMAP.ydim)*100;
 		COSTMAP.dist(COSTMAP.target(1),COSTMAP.target(2)) = 0;
		COSTMAP.closed = zeros(COSTMAP.xdim,COSTMAP.ydim);
		COSTMAP.openset=[COSTMAP.target(1) COSTMAP.target(2)];
		COSTMAP.count = 0;

	end

	function update_value_dijkstra(robot_struct,r_mon)
		reached = false;
		openset_size = size(COSTMAP.openset,1);
		while openset_size>0 && reached==false
			openset_size = size(COSTMAP.openset,1);
			min_dist =999;			
			min_index = 1;
			for k=1:openset_size
				cur_dist = COSTMAP.dist(COSTMAP.openset(k,1),COSTMAP.openset(k,2));
				cur_dist = cur_dist + sqrt(...
				  (COSTMAP.openset(k,1)-COSTMAP.pose(1))^2+...
				  (COSTMAP.openset(k,2)-COSTMAP.pose(2))^2);
				if cur_dist<min_dist 
					min_dist = cur_dist;
					min_index = k;
				end
			end
			current = COSTMAP.openset(min_index,:);
			COSTMAP.closed(current(1),current(2))=2;
			COSTMAP.openset = COSTMAP.openset([1:min_index-1 min_index+1:openset_size],:);
			if current(1)==COSTMAP.pose(1) && current(2)==COSTMAP.pose(2) reached = true;	end
			COSTMAP.count = COSTMAP.count+1;
			for k=1:size(neighbor_s,1)
				neighbor_index=neighbor_s(k,:)+current;
				if neighbor_index(1)>0 && neighbor_index(1)<=COSTMAP.xdim && ...
   				neighbor_index(2)>0 && neighbor_index(2)<=COSTMAP.ydim && ...
					COSTMAP.closed(neighbor_index(1),neighbor_index(2))<2 

  				neighbor_dist = dist_cost_s(k) *...
  				 (1+...
  				 	10*COSTMAP.cost_gaussian(neighbor_index(2),neighbor_index(1)) +...
  				 	  COSTMAP.cost2(neighbor_index(1),neighbor_index(2))...
  				 	);

					COSTMAP.dist(neighbor_index(1),neighbor_index(2))=min(...
						COSTMAP.dist(neighbor_index(1),neighbor_index(2)),... 
						COSTMAP.dist(current(1),current(2))+neighbor_dist );

					if COSTMAP.closed(neighbor_index(1),neighbor_index(2))==0 					
					  COSTMAP.openset = [COSTMAP.openset;neighbor_index];
						COSTMAP.closed(neighbor_index(1),neighbor_index(2))=1; 					
					end
				end
			end
			openset_size = size(COSTMAP.openset,1);
		end
	end

	function calculate_trajectory(robot_struct,r_mon)
		reached = false;
		traj=[];
		cur_dist = COSTMAP.dist(COSTMAP.pose(1), COSTMAP.pose(2));
		cur_index = [COSTMAP.pose(1) COSTMAP.pose(2)];
		next_index = [COSTMAP.pose(1) COSTMAP.pose(2)];

		count = 1;
		while reached==false
%			[count cur_index]
			min_neighbor_dist = cur_dist;
			reached = true;
			cur_index = next_index;
			traj=[traj;cur_index];
			for k=1:size(neighbor,1)
				neighbor_index=neighbor(k,:) + cur_index;
				neighbor_index(1) = max(1,min(COSTMAP.xdim,neighbor_index(1)));
				neighbor_index(2) = max(1,min(COSTMAP.ydim,neighbor_index(2)));
				neighbor_dist = COSTMAP.dist(neighbor_index(1),neighbor_index(2));
				if neighbor_dist<cur_dist && k~=5
					reached = false;
					next_index = neighbor(k,:)+cur_index;
					cur_dist = neighbor_dist;
				end
			end
		end
		COSTMAP.traj = traj;
	end

	function draw_trajectory(robot_struct,r_mon,marker)
		if size(COSTMAP.traj,1)>0
			hold on;
			vx=COSTMAP.traj(:,1)*COSTMAP.div+COSTMAP.x(1);
			vy=COSTMAP.traj(:,2)*COSTMAP.div+COSTMAP.y(1);
		  plot3(vx,vy,110*ones(size(vx)),marker);
		  hold off;
	  end
	end	

end