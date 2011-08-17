function colortable_smear

global COLORTABLE

nYkern = 3;
nUkern = 3;
nVkern = 3;

iYkern0 = .5*(nYkern+1);
iUkern0 = .5*(nUkern+1);
iVkern0 = .5*(nVkern+1);

kern = ones(nYkern,nUkern,nVkern);
kern(iYkern0,:,:) = 1;
kern(iYkern0,iUkern0,iVkern0) = 50;

% Normalize kernel:
%kern = kern./sum(kern(:));
kern = kern./kern(iYkern0,iUkern0,iVkern0);

for icolor = 1:COLORTABLE.ncolor,

  score = COLORTABLE.score(:,icolor);

  x = reshape(score,COLORTABLE.size);
  x_smear = convn(x,kern,'same');
  x_smear = min(x_smear,1);
  
  COLORTABLE.score(:,icolor) = x_smear(:);
end
