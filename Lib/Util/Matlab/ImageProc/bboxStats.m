function stats = bboxStats(labelA, color, bboxB)
  scaleB = 4;
  bboxA = [
  scaleB*bboxB.x1;
  scaleB*bboxB.x2 + scaleB - 1;
  scaleB*bboxB.y1;
  scaleB*bboxB.y2 + scaleB - 1];
  stats = color_stats(labelA, color, bboxA);
end
