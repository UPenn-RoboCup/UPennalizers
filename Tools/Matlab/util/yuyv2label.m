function label=yuyv2label(yuyv,lut)
  yuv=yuyv2yuv(yuyv);
  index = yuv2index(yuv, [64 64 64]);
  label=lut(index)+1;
end
