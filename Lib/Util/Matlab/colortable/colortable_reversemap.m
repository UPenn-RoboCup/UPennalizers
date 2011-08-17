function colortable_reversemap

global COLORTABLE

vY = [4:8:255];
vU = [2:4:255];
vV = [2:4:255];

nmap = 32*64*64;

[aY,aU,aV] = ndgrid(vY, vU, vV);

map0 = uint8([aY(:) aU(:) aV(:)]);

newindex = rgb2index(ycbcr2rgb(reshape(map0,[nmap 1 3])),[32 64 64]);


for icolor = 1:COLORTABLE.ncolor,
  score = COLORTABLE.score(:,icolor);
  newscore = score(newindex);
  
  COLORTABLE.score(:,icolor) = newscore;
end

return;
