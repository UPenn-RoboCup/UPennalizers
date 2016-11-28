function [ipath, jpath] = dijkstra_path2(A, C, istart, jstart);

[m,n] = size(A);

ipath = istart;
jpath = jstart;

r = 0.5;
nth = 64;
th = 2*pi*[0:nth-1]./nth;

xr = r*cos(th);
yr = r*sin(th);

for i = 1:1000,
  x0 = ipath(end);
  y0 = jpath(end);
  d0 = subs_interp(A, x0, y0);
  
  % Neighbors:
  x1 = x0+xr;
  y1 = y0+yr;
  d1 = subs_interp(A, x1, y1);
  
  [dmin, imin] = min(d1);
  if (dmin > d0),
    break;
  end

  ipath = [ipath; x1(imin)];
  jpath = [jpath; y1(imin)];

end


function [amin,i,j] = min2(a)
[amin, imin] = min(a(:));
[i,j] = ind2sub(size(a), imin);
