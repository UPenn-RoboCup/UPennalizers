global CAMERADATA

vcmImage = shm('vcmImage');

count = 0;
while(1)

	imgWidth = vcmImage.get_width();
	imgHeight = vcmImage.get_height();

  if count < vcmImage.get_count()
    count = vcmImage.get_count() + 10;
    CAMERADATA.yuyv = raw2yuyv(vcmImage.get_yuyv(), imgWidth, imgHeight);
    CAMERADATA.labelA = raw2label(vcmImage.get_labelA(), imgWidth/2, imgHeight/2);
		CAMERADATA.labelB = raw2label(vcmImage.get_labelB(), imgWidth/8, imgHeight/8);
		CAMERADATA.headAngles = vcmImage.get_headAngles();
%    jp = dcmSensor.get_position();
%    CAMERADATA.imuAngles = dcmSensor.get_imuAngle();
    CAMERADATA.select = vcmImage.get_select();
    Logger;
  else
    pause(0.01);
  end
end

