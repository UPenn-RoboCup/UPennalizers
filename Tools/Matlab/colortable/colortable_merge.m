function colortable_merge(imagedata)
% update the overall colortable score from a new set of training data
global COLORTABLE

% flag to indicate if the colortable should be recalculated
%   set to 1 if the pos/neg counts have changed
recalc = 0;

% merge masks in imagedata into colortable counts
if ((nargin >= 1) & isfield(imagedata, 'cindex'))

  % for each color
  for icolor = 1:COLORTABLE.ncolor

    % get the index values of the pos/neg examples
    pos_cindex = imagedata.cindex(imagedata.mask_pos{icolor});
    neg_cindex = imagedata.cindex(imagedata.mask_neg{icolor});

    if (~isempty(pos_cindex))
      % increment pos example count from the new positive examples
      COLORTABLE.pos_count(:, icolor) = COLORTABLE.pos_count(:,icolor) + ...
                                        accumarray(pos_cindex, 1, [COLORTABLE.length 1]);

      % set recalculate flag because the pos count changed
      recalc = 1;
    end
    if (~isempty(neg_cindex))
      % increment neg example count from the new negative examples
      COLORTABLE.neg_count(:, icolor) = COLORTABLE.neg_count(:,icolor) + ...
                                        accumarray(neg_cindex, 1, [COLORTABLE.length 1]);

      % set recalculate flag because the neg count changed
      recalc = 1;
    end
  end
end

if (recalc)
  % recalculate the colortable
  colortable_calc();
end
