function lut_montage(lut)
% display the LUT in the YUV colorspace
% 
% each image in the array is the U-V data for a set Y value
%

global COLORTABLE

% create the 3-D YUV colorspace cube
lut3D = reshape(lut, [COLORTABLE.nV COLORTABLE.nU 1 ...
                    COLORTABLE.nY]);
% convert binary labels to sequential labels
lut3D = bitshift(uint16(lut3D), 1);
lut3D(lut3D == 0) = 1;
lut3D = uint8(log2(double(lut3D)));

% use matlab's montage function to display slices of the color
%   cube along the Y-axis
montage(lut3D, COLORTABLE.cmap);

