function [xpath, ypath, apath, cpath] = dijkstra_nonholonomic_path(D, ...
						  xstart, ystart, astart, ...
						  resolution);

if nargin < 5,
  resolution = 0.5;
end

[nx,ny,na] = size(D);

rTurn = 4.0;
nth = 4;
th = resolution/(rTurn)*[-nth:nth]./nth;

ith = (th ~= 0);
dx = resolution*ones(size(th));
dx(ith) = resolution*sin(th(ith))./th(ith);
dy = zeros(size(th));
dy(ith) = resolution*(1-cos(th(ith)))./th(ith);

xpath = [];
ypath = [];
apath = [];
cpath = [];

x0 = xstart;
y0 = ystart;
a0 = astart;
ia0 = na*mod(astart,2*pi)/(2*pi)+1;

for i = 1:200,

  % Neighbors:
  a1 = a0 + th;
  x1 = x0 + dx*cos(a0) - dy*sin(a0);
  y1 = y0 + dx*sin(a0) + dy*cos(a0);
  ia1 = na*mod(a1,2*pi)/(2*pi)+1;
  c1 = subs_interp3_circular(D, x1, y1, ia1);
  
  [cmin, imin] = min(c1);

  x0 = x1(imin);
  y0 = y1(imin);
  a0 = a1(imin);
  ia0 = ia1(imin);  

  ia0r = round(ia0);
  if (ia0r > na), ia0r = 1; end
  c0 = D(round(x0),round(y0),ia0r);

  xpath = [xpath; x0];
  ypath = [ypath; y0];
  apath = [apath; a0];
  cpath = [cpath; c0];

  if (c0 < 2.5*resolution),
    break;
  end

end
