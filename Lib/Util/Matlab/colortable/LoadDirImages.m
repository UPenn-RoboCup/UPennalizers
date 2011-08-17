function [xMontage,sensorData] = LoadDirImages(dirname);

dir_info = dir([dirname '/YUVC*.PIC']);
nfiles = length(dir_info);

sens_info = dir([dirname '/SENS*.DAT']);

colors = [ 255 170   0;
	   255 255  85;
	   0   170 255;
	   255 170 170;
	   200   0   0;
	   0     0 128;
	   0   170   0;
	   220 220 220;
	   128 128 128;
	   rand(255-9,3)
	 ]/255;

for ifile = 1:nfiles,
  try
    yuvc = LoadMatrix([dirname '/' dir_info(ifile).name]);
    [rgb, c] = yuvctorgb(yuvc);
    subplot(1,2,1);
    image(rgb);
    title(sprintf('File: %s',dir_info(ifile).name));
    subplot(1,2,2);
    image(label2rgb(c,colors,[0 0 0]))
%    imagesc(c)
%    drawnow
    disp(sprintf('Color index range: %d %d',min(c(:)),max(c(:))));
    
    if (ifile == 1),
      xMontage = uint8(zeros([size(rgb) nfiles]));
    end
    xMontage(:,:,:,ifile) = rgb;

    if nargout > 1,
      sens = LoadMatrix([dirname '/' sens_info(ifile).name]);
      sensorData{ifile} = sens;
    end
    
    pause
    
  catch
    error('Unable to read image');
  end
  
end
