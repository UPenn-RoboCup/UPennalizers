function [class, score] = colorclass(im)

global COLORTABLE

if ndims(im) == 3,
  cindex = rgb2index(im, COLORTABLE.size);
else
  cindex = im;
end

class = COLORTABLE.maxClass(cindex);
score = COLORTABLE.score(1+(class-1)*COLORTABLE.length+cindex);

class(score == 0) = 0;
