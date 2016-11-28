function plot_label(label)


%{

cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];cbrc=[0.5 0.5 1];cbrp=[1 0.5 0.5];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg];
cmapw = repmat(cw,16,1);
cmap = [cmap;cmapw];
cmaprc = repmat(cbrc,32,1);
cmap = [cmap;cmaprc];
%}

     cbk=[0 0 0];
      cr=[1 0 0];      
      cy=[1 1 0];      
      cbrc=[0.5 0.5 1];
      cg=[0 1 0];      
      cw=[1 1 1];
      cbrp=[1 0.5 0.5];
      
      cmap=[cbk;cr;cy;cy;cbrc;cbrc;cbrc;cbrc;cg;cg;cg;cg;cg;cg;cg;cg];
      cmapw = repmat(cw,16,1);
      cmap = [cmap;cmapw];
      cmaprp = repmat(cbrp,32,1);
      cmap = [cmap;cmaprp];
      cmap(end+1,:) = cbrp;





cmap(end+1,:) = cbrp;
  if( ~isempty(label) )
      colormap(cmap);
      image(label)	
      xlim([1 size(label,2)]);
      ylim([1 size(label,1)]);
  end
end
