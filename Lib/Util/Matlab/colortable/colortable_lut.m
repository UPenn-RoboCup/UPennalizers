function lut = colortable_lut(score_min)

global COLORTABLE

if nargin < 1,
  score_min = 0.1;
end

nlut = size(COLORTABLE.score, 1);
lut = zeros(nlut, 1, 'uint8');

[ymax, imax] = max(COLORTABLE.score, [], 2);
ivalid = (ymax > score_min);
lut(ivalid) = 2.^(imax(ivalid) - 1);
