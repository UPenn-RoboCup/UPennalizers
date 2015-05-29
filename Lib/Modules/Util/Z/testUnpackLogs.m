folder = '../UpennMagicPhase2';
files = dir([folder '/*.mat']);
nFiles = length(files);

nSensors = 5;  %number of sensor robots
mapRobot = 4;    %robot for which to show the map

for ii=1:nSensors
  figure(ii), clf(gcf);
  handles{ii} = plot(0,0,'.k');
end

maps{mapRobot}.sizex = 2000;
maps{mapRobot}.sizey = 2000;
maps{mapRobot}.map  = zeros(maps{mapRobot}.sizex,maps{mapRobot}.sizey);
maps{mapRobot}.xmin = -100;
maps{mapRobot}.ymin = -180;
maps{mapRobot}.res  = 0.1;

figure(6); clf(gcf);
maps{mapRobot}.hMap = imagesc(maps{mapRobot}.map'); hold on;
maps{mapRobot}.hRobot = plot(0,0,'g*');
set(gca,'ydir','normal');


iplot = 1;

for jj=1:nFiles

  load([folder '/' files(jj).name]);
  
  len = length(LOG.UDP);

  for ii=1:len
    packet = deserialize(zlibUncompress(LOG.UDP{ii}.data));
    xs = double(packet.hlidar.xs);
    ys = double(packet.hlidar.ys);
    cs = double(packet.hlidar.cs);

    id = packet.id;
    if (id <= nSensors)
      set(handles{id},'xdata',xs,'ydata',ys);
    end

    if (id==mapRobot)
      xis = round( (xs-maps{id}.xmin)/maps{id}.res );
      yis = round( (ys-maps{id}.ymin)/maps{id}.res );
      iValid = ( (xis > 0) & (yis > 0) & (xis <= maps{id}.sizex) & (yis <= maps{id}.sizey) );

      inds = sub2ind(size(maps{id}.map),xis(iValid),yis(iValid));

      maps{id}.map(inds) = cs(iValid);
      
      iplot = iplot + 1;
      set(maps{id}.hRobot,'xdata',(packet.pose.x-maps{id}.xmin)/maps{id}.res, ...
                          'ydata',(packet.pose.y-maps{id}.ymin)/maps{id}.res);
      if (mod(iplot,20) == 0)
        set(maps{id}.hMap,'cdata',maps{id}.map');
        drawnow;
      end
    end

    
    %pause(0.001);
  end
end
