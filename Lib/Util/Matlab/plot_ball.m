function [ ] = plot_ball( vcmBall )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if(vcmBall.get_detect()==1)
    centroid = vcmBall.get_centroid();
    %centroid.x = centroid.x/scale;
    %centroid.y = centroid.y/scale;
    radius = vcmBall.get_axisMajor() / 2;
    ballB = [centroid(1)-radius centroid(2)-radius 2*radius 2*radius];
    plot(centroid(1), centroid(2),'k+')
    rectangle('Position', ballB, 'Curvature',[1,1])
end

end

