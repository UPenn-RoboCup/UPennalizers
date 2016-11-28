costs = gen_costs(100, 100, .03);

goal = [60 60 1.25*pi];
start = [1 1 .25*pi];
tic;
nav = dijkstra_nonholonomic16(costs, goal, start);
toc

[ip, jp, ap, cp] = dijkstra_nonholonomic_path(nav, ...
                                              start(1), start(2), ...
                                              start(3), 1.0);

imagesc(costs,[1 10]);
colormap(1-gray);
hold on;
plot(jp, ip, 'b-');
hold off;
