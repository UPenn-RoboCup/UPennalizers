function b = subs_interp3(a,x,y,z);

% Trilinear interpolation of 3D matrix a,
% with circular boundary conditions on z

[nx,ny,nz] = size(a);

ix = min(max(floor(x),1),nx-1);
iy = min(max(floor(y),1),ny-1);
iz = min(max(floor(z),1),nz);

dx = x-ix;
dy = y-iy;
dz = z-iz;

ind000 = ix + nx*(iy-1) + nx*ny*(iz-1);
ind100 = ind000+1;
ind010 = ind000+nx;
ind110 = ind010+1;
if (iz < nz),
  ind001 = ind000+nx*ny;
else
  ind001 = ix + nx*(iy-1);
end
ind101 = ind001+1;
ind011 = ind001+nx;
ind111 = ind011+1;

b = (1-dx).*(1-dy).*(1-dz).*a(ind000) + ...
    dx.*(1-dy).*(1-dz).*a(ind100) + ...
    (1-dx).*dy.*(1-dz).*a(ind010) + ...
    dx.*dy.*(1-dz).*a(ind110) + ...
    (1-dx).*(1-dy).*dz.*a(ind001) + ...
    dx.*(1-dy).*dz.*a(ind101) + ...
    (1-dx).*dy.*dz.*a(ind011) + ...
    dx.*dy.*dz.*a(ind111);
