function set_image(h_axes, h_image, image)
  cla(h_axes);
  set(h_axes, 'XLim', .5 + [0, size(image, 2)]);
  set(h_axes, 'YLim', .5 + [0, size(image, 1)]);
  set(h_image, 'XData', [1, size(image, 2)]);
  set(h_image, 'YData', [1, size(image, 1)]);
  set(h_image, 'CData', image);
end


