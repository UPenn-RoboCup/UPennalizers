function [ipath, jpath] = dijkstra_path(A, C, istart, jstart);

[m,n] = size(A);

ipath = istart;
jpath = jstart;

ioffset = [-1 +1  0  0 -1 +1 -1 +1];
joffset = [ 0  0 -1 +1 -1 -1 +1 +1];
doffset = [ 1  1  1  1 sqrt(2)*[1 1 1 1]];

%{
ioffset = ioffset(1:4);
joffset = joffset(1:4);
doffset = doffset(1:4);
%}

while 1,
  i0 = ipath(end);
  j0 = jpath(end);
  
  if (A(i0,j0) < eps),
    break;
  end
  
  % Neighbor indices:
  i1 = i0+ioffset;
  j1 = j0+joffset;
  valid = (i1 >= 1) & (i1 <= m) & (j1 >= 1 ) & (j1 <= n);
  i1 = i1(valid);
  j1 = j1(valid);
  d1 = doffset(valid);
  
  ind1 = sub2ind(size(A), i1, j1);

  a1 = A(ind1)+.5*d1.*(C(ind1)+C(i0,j0));
  
  [dmin, kmin] = min(a1);
  ipath = [ipath; i1(kmin)];
  jpath = [jpath; j1(kmin)];

end


function [amin,i,j] = min2(a)
[amin, imin] = min(a(:));
[i,j] = ind2sub(size(a), imin);
