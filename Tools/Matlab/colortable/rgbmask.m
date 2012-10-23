function y = rgbmask(x, maskpos, maskneg, icolor);
% function to display masked regions in RGB image x
%   changes the color of the masked pixels so they 
%   are more easily visible
%
%   pos - green
%   neg - red

% extract the rgb colors from the image 
r = x(:,:,1);
g = x(:,:,2);
b = x(:,:,3);

if (nargin >= 2)
  % set positive examples to green
  g(maskpos) = 255;
end
if (nargin >= 3)
  % set negative examples to red
  r(maskneg) = 255;
end
if (nargin >= 4)
	if (icolor == 5)
    % special case for white 
		r(maskpos) = 255;
		g(maskpos) = 0;
		b(maskpos) = 0;
		g(maskneg) = 255;
	end
end

% reconstruct the RGB image
y = cat(3,r,g,b);

