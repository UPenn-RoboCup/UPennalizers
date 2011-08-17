function lut_montage(lut)

global COLORTABLE

lut3D = reshape(lut, [COLORTABLE.nV COLORTABLE.nU 1 ...
                    COLORTABLE.nY]);
montage(lut3D, COLORTABLE.cmap);
