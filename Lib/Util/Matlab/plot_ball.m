function [ ] = plot_ball( ballStats, scale )
% TODO: use the scale when displaying labelB data
radius = (ballStats.axisMajor / 2) / scale;
% Switch x and y since labelA is transposed
centroid = [ballStats.centroid.y ballStats.centroid.x] / scale;
ballBox = [centroid(1)-radius centroid(2)-radius 2*radius 2*radius];
plot( centroid(1), centroid(2),'k+')
rectangle('Position', ballBox, 'Curvature',[1,1])

end

