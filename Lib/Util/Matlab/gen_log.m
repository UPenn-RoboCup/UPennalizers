global CAMERADATA

width = 640;
height = 480;

%Corret colormap for labeled image
cbk=[0 0 0];
cr=[1 0 0];
cg=[0 1 0];
cb=[0 0 1];
cy=[1 1 0];
cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];

count=1;

vcmImage = shm('vcmImage');

while count<300
  CAMERADATA.yuyv = dcmVision32('big_img');

  CAMERADATA.headAngles = vcm.get('headAngles');
  CAMERADATA.imuAngles = [];
  CAMERADATA.select = vcm.get('select');;

  Logger;
  pause(.1);
end
