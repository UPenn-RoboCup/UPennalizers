function plot_label(label)
  cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
  cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];
  if( ~isempty(label) )
      colormap(cmap);
      image(label);
      xlim([1 size(label,2)]);
      ylim([1 size(label,1)]);
  end
end
