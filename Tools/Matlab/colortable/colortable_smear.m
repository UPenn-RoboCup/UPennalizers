function colortable_smear()
% create a Gaussian Mixture Model from the training data
%   this function uses the Guassian Smear method for creating 
%   the mixture model.
%   
%   The basic idea is that the 
%

global COLORTABLE

%% create the kernel to use for the smearing/blurring
% kernel size in each dimension
nYkern = 3;
nUkern = 3;
nVkern = 3;

% kernel center in each dimension
iYkern0 = .5*(nYkern+1);
iUkern0 = .5*(nUkern+1);
iVkern0 = .5*(nVkern+1);

% base kernel is just a ones matrix
kern = ones(nYkern,nUkern,nVkern);
% Y (luminesence/lightness) weighting
%   the higher this number is the more generalized the color
%   model will be for light/dark versions of the colors
kern(iYkern0,:,:) = 1;

% extra weighting for the center of the kernel
kern(iYkern0,iUkern0,iVkern0) = 50;

% normalize kernel (all values [0-1])
kern = kern./kern(iYkern0,iUkern0,iVkern0);





% iterate over each color and create the mixture model
for icolor = 1:COLORTABLE.ncolor

  % get the colortable score for the
  score = COLORTABLE.score(:,icolor);

  % reshape the score vector into the 3-D cube
  x = reshape(score, COLORTABLE.size);
  % smear the training data using the kernel
  x_smear = convn(x, kern, 'same');
  % cut off the scores at 1 
  x_smear = min(x_smear, 1);
  
  % save the smeared score into the colortable

  %For real-time label view, we store smeared score to another matrix
  %COLORTABLE.score(:,icolor) = x_smear(:);
  COLORTABLE.score_smeared(:,icolor) = x_smear(:);
end

