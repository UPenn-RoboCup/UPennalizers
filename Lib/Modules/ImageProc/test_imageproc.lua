require('ImageProc');
require('carray');

cdt = carray.new('c', 262144);
pcdt = carray.pointer(cdt);

width = 320;
height = 240;

rgb = carray.new('c', 3*width*height);
prgb = carray.pointer(rgb);

pyuyv = ImageProc.rgb_to_yuyv(prgb, width, height);
yuyv = carray.cast(pyuyv, 'i', width*height);

plabel = ImageProc.yuyv_to_label(pyuyv, pcdt, width, height);
label = carray.cast(plabel, 'c', width*height);
