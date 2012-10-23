function colortable_calc()
% update overall colortable score from training data

global COLORTABLE

pos_count = log(COLORTABLE.pos_count + 1);
pos_norm = normalize(pos_count);

neg_count = log(COLORTABLE.neg_count + 1);
neg_norm = normalize(neg_count);

count = max(pos_norm-neg_norm, 0);
count_norm = normalize(count);

score_sum = sum(count_norm, 2) + 1/COLORTABLE.length;
COLORTABLE.score = count_norm ./ repmat(score_sum, [1 COLORTABLE.ncolor]);


function y = normalize(x)

  xsum = max(sum(x, 1), eps);
  y = x ./ repmat(xsum, [size(x, 1) 1]);

