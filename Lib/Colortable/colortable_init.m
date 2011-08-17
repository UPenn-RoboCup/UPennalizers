global COLORTABLE

COLORTABLE.nY = 64;
COLORTABLE.nU = 64;
COLORTABLE.nV = 64;

COLORTABLE.color_name = {'orange' 'yellow' 'cyan' 'field' 'white' 'robotBlue' 'robotPink'};
COLORTABLE.ncolor = length(COLORTABLE.color_name);
COLORTABLE.cmap = [0 0 0; ... % Black for background
                   1 .5 0; ... % Orange
                   1 1 0; ... % Yellow
                   0 .5 1; ... % Cyan
                   0 .5 0; ... % Field
                   .8 .8 .8; ... % White
				   .25 .6 1; ... % robotBlue 
				   1 0 .5;]; % robotPink 

COLORTABLE.size = [COLORTABLE.nY COLORTABLE.nU COLORTABLE.nV];
COLORTABLE.length = prod(COLORTABLE.size);

COLORTABLE.pos_count = zeros(COLORTABLE.length, COLORTABLE.ncolor);
COLORTABLE.neg_count = zeros(COLORTABLE.length, COLORTABLE.ncolor);

COLORTABLE.score = zeros(COLORTABLE.length, COLORTABLE.ncolor);
