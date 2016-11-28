costs = gen_costs(100, 100, .05);

goal = [60 60];
tic;
ctg = dijkstra_matrix(costs,goal(1),goal(2));
toc

[ip1, jp1] = dijkstra_path(ctg, costs, 1, 1);
[ip2, jp2] = dijkstra_path2(ctg, costs, 1, 1);

subplot(1,2,1);
imagesc(costs,[1 10]);
colormap(1-gray);
hold on;
plot(jp1, ip1, 'b-', jp2, ip2, 'r-');
hold off;

subplot(1,2,2);
imagesc(ctg);
colormap(1-gray);
hold on;
plot(jp1, ip1, 'b-', jp2, ip2, 'r-');
hold off;
