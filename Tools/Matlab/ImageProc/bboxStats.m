function stats = bboxStats(labelA, color, bboxB, scale)
scaleB = 4 / scale;

bboxA = [
    scaleB*bboxB.x1;
    scaleB*bboxB.x2 + scaleB - 1;
    scaleB*bboxB.y1;
    scaleB*bboxB.y2 + scaleB - 1];

%{
% Label Images from webots are swap x and y (do this or transpose the image
bboxA = [
    scaleB*bboxB.y1;
    scaleB*bboxB.y2 + scaleB - 1;
    scaleB*bboxB.x1;
    scaleB*bboxB.x2 + scaleB - 1];
%}
% Plot our bounding box
%{
figure(3);
imagesc( labelA );
hold on;
plot( [bboxA(1),bboxA(1),bboxA(2),bboxA(2)],[bboxA(3),bboxA(4),bboxA(4),bboxA(3)], 'k' );
%}

% Labeled image is transposed...
stats = color_stats(labelA', color, bboxA);
end
