% wait for packet
ready = false;
msg = char(UDPComm('receive'));
while (~ready)
  msg = char(UDPComm('receive'));
  if (~isempty(msg))
    st = lua2mat(msg);
    if (~isfield(st, 'id'))
      ready = true;
    end
  end
  pause(0.1);
end

% create empty polar plot
p = polar(0);
% x-axis forward
view(-90,90);
% delete lines and labels
delete(findall(ancestor(p,'figure'),'HandleVisibility','off','type','line','-or','type','text'));

colormap(gray);
ngray = size(gray, 1);
ndiv = length(st.soundFilter);
x = 1+zeros([ndiv, 1]);

range = -pi:2*pi/ndiv:pi;
circx = cos(range);
circy = sin(range);
zip = range * 0;
s=surface([ zip; circx ],...
          [ zip; circy ],...
          [ zip; zip ] );

set(s,  'FaceColor', 't', ...
        'CData', x, ...
        'CDataMapping', 'direct',  ... 'direct'/'scaled'
        'EdgeAlpha', 0.2);


while (1)
  msg = char(UDPComm('receive'));
  if (~isempty(msg))
    st = lua2mat(msg);
    if (~isfield(st, 'id'))
      x = st.soundFilter 
      x = fix(st.soundFilter * ngray/ndiv);

      set(s, 'CData', x);
    end
  end

  pause(0.1);
end



