function y = rgbmask(x, maskpos, maskneg, icolor);
% Function to display masked regions in RGB image x

r = x(:,:,1);
g = x(:,:,2);
b = x(:,:,3);

if nargin >= 2,
  g(maskpos) = 255;
end
if nargin >= 3,
  r(maskneg) = 255;
end
if nargin >= 4,
	if (icolor == 5),
		r(maskpos) = 255;
		g(maskpos) = 0;
		b(maskpos) = 0;
		g(maskneg) = 255;
	end
end

y = cat(3,r,g,b);
