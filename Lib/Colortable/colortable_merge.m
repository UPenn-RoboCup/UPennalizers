function colortable_merge(imagedata)

global COLORTABLE

recalc = 0;


% Merge masks in imagedata into colortable counts:
if (nargin >= 1) & isfield(imagedata,'cindex'),
  for icolor = 1:COLORTABLE.ncolor,
    pos_cindex = imagedata.cindex(imagedata.mask_pos{icolor});
    neg_cindex = imagedata.cindex(imagedata.mask_neg{icolor});

    if ~isempty(pos_cindex),
      COLORTABLE.pos_count(:,icolor) = COLORTABLE.pos_count(:,icolor) + ...
	  accumarray(pos_cindex, 1, [COLORTABLE.length 1]);
      recalc = 1;
    end
    if ~isempty(neg_cindex),
      COLORTABLE.neg_count(:,icolor) = COLORTABLE.neg_count(:,icolor) + ...
	  accumarray(neg_cindex, 1, [COLORTABLE.length 1]);
      recalc = 1;
    end
  end
end

if recalc,
  colortable_calc();
end
