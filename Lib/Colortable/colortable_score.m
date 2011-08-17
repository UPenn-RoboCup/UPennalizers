function score = colortable_score(yuv, icolor)

global COLORTABLE

if nargin < 2,
  icolor = 1;
end

if ndims(yuv) == 3,
  cindex = yuv2index(yuv, COLORTABLE.size);
else
  cindex = yuv;
end

score_color = COLORTABLE.score(:,icolor);
score = score_color(cindex);
