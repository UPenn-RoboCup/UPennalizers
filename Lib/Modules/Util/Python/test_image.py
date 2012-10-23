#!/usr/bin/env python

import matplotlib.pyplot as mpl
import numpy as np
import scipy as sp
import time
import shm
import os

vcmImage = shm.ShmWrapper('vcmImage12%s' % str(os.getenv('USER')));

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
  rgb = np.asarray(sp.misc.toimage(ycbcr, mode='YCbCr').convert('RGB').getdata());
  rgb = rgb.reshape((60, 80, 3))/255.0;

  # display image
  mpl.imshow(rgb)


if __name__=='__main__':
  # create connection to image shm
  print('Click on the image to update...');

  fig = mpl.figure();

  fig.canvas.mpl_connect('button_press_event', on_button_press);

  mpl.show();

  time.sleep(0.1);

  
