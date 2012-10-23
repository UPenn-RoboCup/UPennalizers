function raw = yuyv2raw(yuyv)
  % converts the yuyv format to raw matrix data
  siz=size(yuyv);
  width=siz(1);height=siz(2);
  raw = typecast(reshape(yuyv, [1 width*height]),'double');
end
