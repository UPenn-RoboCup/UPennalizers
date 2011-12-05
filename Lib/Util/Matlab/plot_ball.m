function [ ] = plot_ball( vcmBall )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if(vcmBall.get_detect()==1)
    scale = 1;
    centroidB = vcmBall.get_centroid();
    %centroidB.x = centroidB.x/scale;
    %centroidB.y = centroidB.y/scale;
    radiusB = (vcmBall.get_axisMajor()/scale)/2;
    ballB = [centroidB(1)-radiusB centroidB(2)-radiusB 2*radiusB 2*radiusB];
    %plot( ballB, 'k*' );
    plot(centroidB(1), centroidB(2),'k+')
    rectangle('Position', ballB, 'Curvature',[1,1])
end

end

