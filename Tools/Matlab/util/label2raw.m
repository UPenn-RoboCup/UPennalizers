function raw = label2raw(label)
  % converts the labeled image into the raw data matrix
  siz=size(label);
  label=reshape(label,[1 siz(1)*siz(2)]);
  raw = typecast(label,'double');
end
