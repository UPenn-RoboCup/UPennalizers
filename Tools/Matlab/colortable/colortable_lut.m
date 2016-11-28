function lut = colortable_lut(score_min)
% create the LUT (look-up table)
%   The LUT is just a mapping from the 
%   YUV index to color label

global COLORTABLE

% score threshold
if (nargin < 1)
  score_min = 0.1;
end


%For real-time label view, we store smeared score to another matrix
%And generate lut from that matrix

% initialize LUT array
%nlut = size(COLORTABLE.score, 1);
nlut = size(COLORTABLE.score_smeared, 1);
lut = zeros(nlut, 1, 'uint8');

% find maximum score across colors
%[ymax, imax] = max(COLORTABLE.score, [], 2);
[ymax, imax] = max(COLORTABLE.score_smeared, [], 2);

% YUV color indices that have a score above the min threshold
ivalid = (ymax > score_min);

% set the LUT value to the color label with the max score
lut(ivalid) = 2.^(imax(ivalid) - 1);

