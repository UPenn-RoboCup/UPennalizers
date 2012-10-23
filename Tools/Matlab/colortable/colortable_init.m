% initialize global colortable struct
% the struct stores the data for the colortable/lut training

global COLORTABLE

fprintf('initializing global COLORTABLE struct...');

% number of possible Y,U,V values respectively
%   we consider the most significant 6 bits of the 
%   actual YUV data so there are 2^6 = 64 possible 
%   values each color channel can take 
COLORTABLE.nY = 64;
COLORTABLE.nU = 64;
COLORTABLE.nV = 64;

% string names of the different colors of interest
COLORTABLE.color_name = { 'orange', ...
                          'yellow', ...
                          'cyan', ...
                          'field', ...
                          'white', ...
                          'robot blue', ...
                          'robot pink'};

% total number of unique colors
COLORTABLE.ncolor = length(COLORTABLE.color_name);

% RGB color map for the displays
COLORTABLE.cmap = [0.0 0.0 0.0; ... % Black for background
                   1.0 0.5 0.0; ... % Orange
                   1.0 1.0 0.0; ... % Yellow
                   0.0 0.5 1.0; ... % Cyan
                   0.0 0.5 0.0; ... % Field
                   0.8 0.8 0.8; ... % White
                   0.2 0.6 1.0; ... % robotBlue 
                   1.0 0.0 0.5];    % robotPink 

% store the size of the colortable for easy access later
COLORTABLE.size = [COLORTABLE.nY COLORTABLE.nU COLORTABLE.nV];
COLORTABLE.length = prod(COLORTABLE.size);

% initialize the positive and negative example count arrays
COLORTABLE.pos_count = zeros(COLORTABLE.length, COLORTABLE.ncolor);
COLORTABLE.neg_count = zeros(COLORTABLE.length, COLORTABLE.ncolor);

COLORTABLE.score = zeros(COLORTABLE.length, COLORTABLE.ncolor);

fprintf('done\n');

