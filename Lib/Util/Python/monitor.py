#!/usr/bin/env python

import matplotlib.pyplot as mpl
import numpy as np
from scipy.misc import pilutil
import time
import shm
import os

vcmImage = shm.ShmWrapper('vcmImage181%s' % str(os.getenv('USER')));

def draw_data(rgb, labelA):
  mpl.subplot(2,2,1);
  mpl.imshow(rgb)
  # disp('Received image.')

  mpl.subplot(2,2,2);
  # labelA = sw.vcmImage.get_labelA();
  # labelA = typecast( labelA, 'uint8' );
  # labelA = reshape(  labelA, [80,60] );
  # labelA = permute(  labelA, [2 1]   );
  mpl.imshow(labelA);
  # TODO: Port the Matlab Colormap
  # cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
  # cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];
  # colormap(cmap);
  # hold on;
  # plot_ball( sw.vcmBall );
  # plot_goalposts( sw.vcmGoal );
  # print 'Received Label A."

  mpl.subplot(2,2,3);
  # Draw the field for localization reasons
  #plot_field();
#  hold on;
  # plot robots
#   for t in range( len(teamNumbers) ):
#    for p in range(nPlayers):
#      if (~isempty(robots{p, t})):
#        plot_robot_struct(robots{p, t});

  mpl.subplot(2,2,4);
  # What to draw here?
  #plot(10,10);
  #hold on;
  #plot_goalposts( sw.vcmGoal );

  mpl.draw();

def on_button_press(event):
  global vcmImage

  # get the yuyv image data
  yuyv = vcmImage.get_yuyv();
  # data is actually int32 (YUYV format) not float64
  yuyv.dtype = 'uint32';
  n = yuyv.shape[0];
  # convert to uint8 to seperate out YUYV
  yuyv.dtype = 'uint8';
  # reshape to Nx4
  yuyv_u8 = yuyv.reshape((120, 80, 4));
  # convert to ycbcr (approx.)
  ycbcr = yuyv_u8[0:-1:2, :, [0,1,3]];
  # convert to rgb
  # there is probably a better way to do this...
  rgb = np.asarray(pilutil.toimage(ycbcr, mode='YCbCr').convert('RGB').getdata());
  rgb = rgb.reshape((60, 80, 3))/255.0;

  # Get the labelA data
  labelA = vcmImage.get_labelA();
  # data is actually uint8 (one bit per label)
  labelA.dtype = 'uint8';
  n = yuyv.shape[0];
  labelA = labelA.reshape(  (60,80) );
#  labelA = permute(  labelA, [2 1]   );


  # display image
  draw_data(rgb, labelA)
  
if __name__=='__main__':
  # create connection to image shm
  print('Click on the image to update...');

  fig = mpl.figure();

  fig.canvas.mpl_connect('button_press_event', on_button_press);

  mpl.show();

  time.sleep(0.1);
