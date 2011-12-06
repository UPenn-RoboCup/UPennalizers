function stats = bboxStats(labelA, color, bboxB)
  scaleB = 4;
  bboxA = [
  scaleB*bboxB(1);
  scaleB*bboxB(2) + scaleB - 1;
  scaleB*bboxB(3);
  scaleB*bboxB(4) + scaleB - 1];
  stats = color_stats(labelA, color, bboxA);
end
