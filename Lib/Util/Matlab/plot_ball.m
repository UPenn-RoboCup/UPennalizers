function [ ] = plot_ball( ballStats, scale )
% TODO: use the scale when displaying labelB data
radius = (ballStats.axisMajor / 2) / scale;
centroid = [ballStats.centroid.x ballStats.centroid.y] / scale;
ballBox = [centroid(1)-radius centroid(2)-radius 2*radius 2*radius];
plot( centroid(1), centroid(2),'k+')
if( ~isnan(ballBox) )
    rectangle('Position', ballBox, 'Curvature',[1,1])
end

end

