clear all;

width = 640;
height = 480;
scaleA = 2;
scaleB = 4;

addpath(genpath('mex'))
fid_yuyv = fopen('image_yuyv', 'r');
fid_mjpeg = fopen('image_mjpeg', 'r');
fid_labelA = fopen('image_labelA', 'r');
fid_labelB = fopen('image_labelB', 'r');
fid_rgb = fopen('image_rgb', 'r');

yuyv_str = fread(fid_yuyv, '*uint8');
mjpeg_str = fread(fid_mjpeg, '*uint8');
labelA_str = fread(fid_labelA, '*uint8');
labelB_str = fread(fid_labelB, '*uint8');
rgb_str = fread(fid_rgb, '*uint8');

jpeg_str = add_jpeg_header(mjpeg_str);
jpeg = djpeg(jpeg_str);

labelA = reshape(labelA_str, width / scaleA, height / scaleA);
labelB = reshape(labelB_str, width / scaleA / scaleB,...
                              height / scaleA / scaleB);

rgb = reshape(rgb_str, [3, width * height]);
r_layer = reshape(rgb(1, :), width, height)';
g_layer = reshape(rgb(2, :), width, height)';
b_layer = reshape(rgb(3, :), width, height)';
rgb = cat(3, r_layer, g_layer, b_laye);
