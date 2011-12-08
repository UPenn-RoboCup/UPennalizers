function [ ] = plot_goalposts( postStats, scale )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if( postStats.area == 0 ) return; end
r0=postStats.axisMajor/2;
w0=postStats.axisMinor/2;
a0 = -1*postStats.orientation;
rot=[cos(a0) -sin(a0);sin(a0) cos(a0)];
x11=postStats.centroid+(rot*[r0 w0]')';
x12=postStats.centroid+(rot*[-r0 w0]')';
x21=postStats.centroid+(rot*[r0 -w0]')';
x22=postStats.centroid+(rot*[-r0 -w0]')';
plot([x11(1) x12(1)],[x11(2) x12(2)],'r','LineWidth',2);
plot([x21(1) x22(1)],[x21(2) x22(2)],'r','LineWidth',2);
plot([x12(1) x22(1)],[x12(2) x22(2)],'r','LineWidth',2);
plot([x11(1) x21(1)],[x11(2) x21(2)],'r','LineWidth',2);

end

