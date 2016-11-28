function score = colortable_score(yuv, icolor)
% return the current colortable score for the given 
%   image and color

global COLORTABLE

if (nargin < 2)
  icolor = 1;
end

if (ndims(yuv) == 3)
  % if the input is in YUV format convert it to index
  cindex = yuv2index(yuv, COLORTABLE.size);
else
  cindex = yuv;
end

% get the current colortable score for the given color
score_color = COLORTABLE.score(:, icolor);
score = score_color(cindex);

