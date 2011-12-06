function [ ] = plot_ball( ballStats, scale )
% TODO: use the scale when displaying labelB data
radius = ballStats.axisMajor / 2;
ballBox = [ballStats.centroid(1)-radius ballStats.centroid(2)-radius 2*radius 2*radius];
plot(ballStats.centroid(1), ballStats.centroid(2),'k+')
rectangle('Position', ballBox, 'Curvature',[1,1])

end

