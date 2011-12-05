function [ ] = plot_goalposts( vcmGoal )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

vcmGoal.get_postBoundingBox1();
vcmGoal.get_postBoundingBox2();
if (vcmGoal.get_detect() ~= 0 )
    disp('Goal detected!');
    scale = 4;
    bbox = scale*vcmGoal.get_postBoundingBox1();
    rectangle('Position',[bbox(1), bbox(3), bbox(2)-bbox(1), bbox(4)-bbox(3)],'LineWidth',2);
end

end

