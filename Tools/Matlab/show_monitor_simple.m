function h = show_monitor_simple(ncamera)
  h.init = @init;
  h.update = @update;

  % subplot axex handles
  h.rgb_handle = zeros(1, ncamera);
  h.label_handle = zeros(1, ncamera);


  % monitor-wise params
  h.ncamera = ncamera;
  h.label_select = 'A'; % 'B'

  % layout
  h.grid_height = 4;
  h.grid_width = ncamera + 1;

  function ret = init()
    h.fig = gcf;
    clf;
    set(h.fig, 'name', 'monitor','menubar', 'none',...
                'toolbar', 'figure');
    figpos = get(h.fig, 'position');
    
    % set Monitor window size
    if h.ncamera == 1
      win_width = 530;
      win_height = 400;
    elseif h.ncamera == 2
      win_width = 1072;
      win_height = 472;
    elseif h.ncamera == 3
      win_width = 900;
      win_height = 400;
    end
    figpos(3:4) = [win_width, win_height];
    set(h.fig, 'Position', figpos);

    h.rgb_axes(1) = axes('Parent', h.fig,...
                      'YDir', 'reverse', ...
                      'XLim', [0, 640],...
                      'YLim', [0, 480],...
                      'Position', [0.05, 0.25, 0.425, 0.7]);
    h.rgb_axes(2) = axes('Parent', h.fig,...
                      'YDir', 'reverse', ...
                      'XLim', [0, 640],...
                      'YLim', [0, 480],...
                      'Position', [0.525, 0.25, 0.425, 0.7]);
    h.rgb(1) = image('Parent', h.rgb_axes(1),...
                      'XData', [1 640],...
                      'YData', [1 480],...
                      'CData', []);
    h.rgb(2) = image('Parent', h.rgb_axes(2),...
                      'XData', [1 640],...
                      'YData', [1 480],...
                      'CData', []);                 
  end

  function update(zmq_ret)

%    subplot(1,2,1); 
    if numel(zmq_ret.rgb_data{1}) > 0
      set(h.rgb(1), 'CData', zmq_ret.rgb_data{1});
    end
%
%    subplot(1,2,2);
    if numel(zmq_ret.rgb_data{2}) > 0
      set(h.rgb(2), 'CData', zmq_ret.rgb_data{2});
    end

    drawnow;

  end

end
