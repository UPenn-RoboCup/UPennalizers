function h=plot_yuyv(yuyv)
  [ycbcr,rgb]=yuyv2rgb(yuyv);
  imagesc( rgb ); 
end 
