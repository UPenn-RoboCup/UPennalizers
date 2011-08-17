function colortable_write(filename)

global COLORTABLE

cdt = uint8(255*COLORTABLE.score);
SaveMatrix(filename, cdt);
