function colortable(action, varargin)
%
% main function for the colortable/lut training gui
%

global COLORTABLE
if isempty(COLORTABLE)
  colortable_init;
end

if (nargin < 1)
  action = 'Initialize';
end

% colortable is the main callback, all interactions call colortable with
%   the desired sub-function
feval(action, varargin{:});
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Sub-Function Definitions %%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  function Initialize()
  % initialize the colortable gui
  % creates the gui and ui elements for the colortable trainer

    global COLORTABLE

    % create the gui
    hfig = gcf;
    clf;
    set(hfig, 'Name', 'UPenn Colortable Selection', ...
              'NumberTitle', 'off', ...
              'tag', 'Colortable', ...
              'MenuBar', 'none', ...
              'ToolBar', 'figure', ...
              'Color', [.8 .8 .8], ...
              'Colormap', gray(256));

    % set the figure window size
    figpos = get(hfig, 'Position');
    figpos(3:4) = [600 400];
    set(hfig, 'Position', figpos);

    % default image size 
    DATA.size = [240 160];
    % default color threshold value
    DATA.cthreshold = 14;
    % array containing the training images
    DATA.montage = [];
    % index of the current color
    DATA.icolor = 1;

    % standard options for all gui elements
    % do not allow callbacks to be interrupted
    Std.Interruptible = 'off';
    % if a callback is triggered while another is still being executed
    % queue that callback (run it after the current one is finished)
    Std.BusyAction = 'queue';

    % create the axis to display the current image
    DATA.ImageAxes = axes(Std, ...
                           'Parent', hfig, ...
                           'YDir', 'reverse', ...
                           'XLim', .5+[0 DATA.size(2)], ...
                           'YLim', .5+[0 DATA.size(1)], ...
                           'XTick', [], ...
                           'YTick', [], ...
                           'Units', 'Normalized', ...
                           'Position', [.2 .15 .7 .8]);

    % create the handle for the image data
    DATA.Image = image(Std, ...
                        'Parent', DATA.ImageAxes, ...
                        'XData', [1 DATA.size(2)], ...
                        'YData', [1 DATA.size(1)], ...
                        'ButtonDownFcn', 'colortable(''Button'')', ...
                        'CData', []);

    % create 'Load Montage' button
    DATA.LoadControl = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Load Montage', ...
                                  'Callback','colortable(''LoadMontage'')', ...
                                  'Units', 'Normalized', ...
                                  'Position', [.025 .90 .15 .05]);

    % create 'Save Colors' button
    DATA.SaveControl = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Save Colors', ...
                                  'Callback','colortable(''SaveColor'')', ...
                                  'Units', 'Normalized', ...
                                  'Position', [.025 .10 .15 .05]);

    % create 'Clear Selection' button
    DATA.ClearControl = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Clear Selection', ...
                                  'Callback','colortable(''ClearSelection'')', ...
                                  'Units', 'Normalized', ...
                                  'Position', [.025 .35 .15 .05]);

    % create the Forward arrow button
    DATA.ForwardControl = uicontrol(Std, ...
                                    'Parent', hfig, ...
                                    'Style', 'pushbutton', ...
                                    'String', '->', ...
                                    'Callback','colortable(''UpdateImage'',''forward'')', ...
                                    'Units', 'Normalized', ...
                                    'Position', [.65 .05 .05 .05]);

    % create the Backward arrow button
    DATA.BackwardControl = uicontrol(Std, ...
                                      'Parent', hfig, ...
                                      'Style', 'pushbutton', ...
                                      'String', '<-', ...
                                      'Callback','colortable(''UpdateImage'',''backward'')', ...
                                      'Units', 'Normalized', ...
                                      'Position', [.4 .05 .05 .05]);

    % create the double Forward arrow button
    DATA.FastForwardControl = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'String', '>>', ...
                                        'Callback','colortable(''UpdateImage'',''fastforward'')', ...
                                        'Units', 'Normalized', ...
                                        'Position', [.75 .05 .05 .05]);

    % create the double Backward arrow button
    DATA.FastBackwardControl = uicontrol(Std, ...
                                          'Parent', hfig, ...
                                          'Style', 'pushbutton', ...
                                          'String', '<<', ...
                                          'Callback','colortable(''UpdateImage'',''fastbackward'')', ...
                                          'Units', 'Normalized', ...
                                          'Position', [.3 .05 .05 .05]);


    % create the image index select edit box
    DATA.IndexControl = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'edit', ...
                                  'String', '1', ...
                                  'Callback','colortable(''UpdateImage'',str2num(get(gco,''String'')))', ...
                                  'Units', 'Normalized', ...
                                  'Position', [.5 .05 .1 .06]);

    % create the selection array for the colors of interest
    for icolor = 1:COLORTABLE.ncolor,
      DATA.ColorControl(icolor) = uicontrol(Std, ...
                                             'Parent', hfig, ...
                                             'Style', 'radiobutton', ...
                                             'String', COLORTABLE.color_name{icolor}, ...
                                             'UserData', icolor, ...
                                             'Callback','colortable(''Color'',get(gco,''UserData''))',...
                                             'Value', 0, ...
                                             'Units', 'Normalized', ...
                                             'Position', [.025 .88-.045*icolor .15 .05]);
    end

    % create the color selection threshold slider
    DATA.ThresholdControl = uicontrol(Std, ...
                                       'Parent', hfig, ...
                                       'Style', 'slider', ...
                                       'Min', 0, ...
                                       'Max', 128, ...
                                       'Value', DATA.cthreshold, ...
                                       'Callback','colortable(''UpdateThreshold'',get(gco,''Value''))', ...
                                       'Units', 'Normalized', ...
                                       'Position', [.025 .25 .15 .05]);

    % create the color selection threshold edit box
    DATA.ThresholdEdit = uicontrol(Std, ...
                                    'Parent', hfig, ...
                                    'Style', 'edit', ...
                                    'String', num2str(DATA.cthreshold), ...
                                    'Callback','colortable(''UpdateThreshold'',str2num(get(gco,''String'')))', ...
                                    'Units', 'Normalized', ...
                                    'Position', [.075 .20 .05 .05]);

    % create the color selection title label
    DATA.ThresholdLabel = uicontrol(Std, ...
                                    'Parent', hfig, ...
                                    'Style', 'text', ...
                                    'String','Threshold', ...
                                    'Units', 'Normalized', ...
                                    'Position', [.025 .30 .15 .035]);


    % set DATA as the gui userdata (so we can access the data later)
    set(hfig, 'UserData', DATA, 'Visible', 'on');
    drawnow;
    return;


  function UpdateImage(index)
  % updates the image displayed in the gui
    global COLORTABLE

    % get the gui userdata
    hfig = gcbf;
    DATA = get(hfig, 'UserData');

    if isempty(DATA.montage)
      % if no montage has been loaded, do nothing
      return;
    end

    % get the number of images in the montage
    nMontage = size(DATA.montage, 4);

    % iImage is the index of the current image
    if ~isfield(DATA, 'iImage')
      % if it is not already set (i.e. the montage was just loaded)
      % then initialize it to one
      DATA.iImage = 1;
    end

    % did the index change? (go to next image)
    if (nargin >= 1)
      % update color score data
      colortable_merge(DATA);
      
      % determine new image index
      if strcmp(index,'forward') 
        % forward button was pressed
        DATA.iImage = DATA.iImage + 1;
      elseif strcmp(index,'fastforward')
        % fast forward button was pressed
        DATA.iImage = DATA.iImage + 10;
      elseif strcmp(index,'backward')
        % back button was pressed
        DATA.iImage = DATA.iImage - 1;
      elseif strcmp(index,'fastbackward')
        % fast back button was pressed
        DATA.iImage = DATA.iImage - 10;
      else
        % the index edit box was set
        DATA.iImage = index;
      end

      % max sure iImage is a valid index
      DATA.iImage = min(max(DATA.iImage, 1), nMontage);

      % the yuv color data for the current image
      DATA.yuv = DATA.montage(:, :, :, DATA.iImage);
      % convert the yuyv data into the index values
      % these are the indices of the LUT 
      DATA.cindex = yuv2index(DATA.yuv, COLORTABLE.size);

      % convert the yuv image to rgb so we can display it
      DATA.rgb = ycbcr2rgb(DATA.yuv);

      for icolor = 1:COLORTABLE.ncolor
        % clear out mask with new image
        DATA.mask_pos{icolor} = false(DATA.size);
        DATA.mask_neg{icolor} = false(DATA.size);
      end
    end

    % get the current colortable score
    score = colortable_score(DATA.cindex, DATA.icolor);

    % create the display image (visualizing the current mask)
    im_display = DATA.rgb;

    % visualize the current colortable score 
    if (DATA.icolor == 5) % white
      % special case for if the current color is white
      %   the generic way is not visible (white on white)
      im_display(:,:,2) = DATA.rgb(:,:,2) - uint8((score>0).*double(DATA.rgb(:,:,2)));
      im_display(:,:,3) = DATA.rgb(:,:,3) - uint8((score>0).*double(DATA.rgb(:,:,3)));
    else
      im_display(:,:,2) = DATA.rgb(:,:,2) + uint8(score.*double(255-DATA.rgb(:,:,2)));
    end

    % visualize current pos/neg selection masks
    im_display = rgbmask(im_display, DATA.mask_pos{DATA.icolor}, ...
                           DATA.mask_neg{DATA.icolor}, DATA.icolor);

    % set the display image data in the gui
    set(DATA.Image, 'CData', im_display);

    % update the current image index display
    set(DATA.IndexControl, 'String', num2str(DATA.iImage));

    set(hfig, 'UserData', DATA);
    return;


  function Button()
  % callback for clicking on the image
    global COLORTABLE

    % get the gui userdata
    hfig = gcbf;
    DATA = get(hfig, 'UserData');

    % get the pointer position
    pt = get(gca,'CurrentPoint');
    ptx = round(pt(1,1));
    pty = round(pt(1,2));

    % select similar colored pixels based on the color selection threshold
    % mask is a binary array where selected pixels have a value of 1
    mask = rgbselect(DATA.rgb, ptx, pty, DATA.cthreshold);

    if strcmp(get(hfig,'SelectionType'),'normal')
      % left click
      % add selected pixels to the positive examples mask
      DATA.mask_pos{DATA.icolor} = DATA.mask_pos{DATA.icolor} | mask;
      % remove any selected pixels from the negative examples mask
      DATA.mask_neg{DATA.icolor} = DATA.mask_neg{DATA.icolor} & ~mask;
    elseif strcmp(get(hfig,'SelectionType'),'extend')
      % shift + left click
      % remove any selected pixels from the positive examples mask
      DATA.mask_pos{DATA.icolor} = DATA.mask_pos{DATA.icolor} & ~mask;
      % add selected pixels to the negative examples mask
      DATA.mask_neg{DATA.icolor} = DATA.mask_neg{DATA.icolor} | mask;
    elseif strcmp(get(hfig,'SelectionType'),'alt')
      % ctrl + left click
      % remove any selected pixels from the positive examples mask
      DATA.mask_pos{DATA.icolor} = DATA.mask_pos{DATA.icolor} & ~mask;
      % remove any selected pixels from the negative examples mask
      DATA.mask_neg{DATA.icolor} = DATA.mask_neg{DATA.icolor} & ~mask;
    end

    set(hfig, 'UserData', DATA);
    UpdateImage();
    return;


  function Color(icolor)
  % callback for selecting a color from the radio button array
    global COLORTABLE

    % get the gui userdata
    hfig = gcbf;
    DATA = get(hfig, 'UserData');

    % get the selected color
    DATA.icolor = icolor;
    set(hfig, 'UserData', DATA);

    % update the selected color radio button (highlight)
    for icolor = 1:COLORTABLE.ncolor
      if (icolor == DATA.icolor)
        set(DATA.ColorControl(icolor), 'Value', 1);
      else
        set(DATA.ColorControl(icolor), 'Value', 0);
      end
    end

    UpdateImage();
    return;


  function UpdateThreshold(value)
  % callback for the color selection threshold slider
    global COLORTABLE

    % get the gui userdata
    hfig = gcbf;
    DATA = get(hfig, 'UserData');

    % set the new threshold value
    DATA.cthreshold = round(value);
    % update the threshold value display
    set(DATA.ThresholdControl, 'Value', DATA.cthreshold);
    set(DATA.ThresholdEdit, 'String', num2str(DATA.cthreshold));
    set(hfig, 'UserData', DATA);
    return;


  function LoadMontage()
  % callback for the 'Load Montage' button
    global COLORTABLE

    % get the gui userdata
    hfig = gcbf;
    DATA = get(hfig, 'UserData');

    % open file select gui
    [filename, pathname] = uigetfile('*.mat', 'Select montage file');

    if (filename ~= 0)
      % if a file was selected
      s = load([pathname filename]);

      % make sure it has a yuyvMontage
      if (isfield(s, 'yuyvMontage'))
        % convert the yuyv montage to yuv data
        yuvMontage = yuyv2yuv(s.yuyvMontage);
        
        % check the image size
        sz = size(yuvMontage);
        if (~isempty(DATA.montage) && any(sz(1:2) ~= DATA.size))
          % image size does not match current data size
          warndlg('YUYV montage image size changed.\nMake sure these images are from the same camera as the previous montage.');
          % resize the image display
          DATA.size = sz(1:2);
          set(DATA.ImageAxes, 'XLim', .5+[0 DATA.size(2)], ...
                              'YLim', .5+[0 DATA.size(1)]);
          set(DATA.Image, 'XData', [1 DATA.size(2)], ...
                          'YData', [1 DATA.size(1)], ...
                          'Cdata', []);
        end

        DATA.montage = yuvMontage;
        set(hfig, 'UserData', DATA);

        % display the first image in the montage
        UpdateImage(1);
      end
    end

    return;


  function ClearSelection()
  % callback for the 'Clear Selection' button
    global COLORTABLE

    % get the gui userdata
    hfig = gcbf;
    DATA = get(hfig, 'UserData');

    % re-initialize masks
    DATA.mask_pos{DATA.icolor} = false(DATA.size);
    DATA.mask_neg{DATA.icolor} = false(DATA.size);

    set(hfig, 'UserData', DATA);

    UpdateImage();
    return;


  function SaveColor()
  % callback for the 'Save Colors' button
    global COLORTABLE

    % open the save file gui
    [filename, pathname] = uiputfile('*.mat', 'Select colortable file to save');
    if (filename ~= 0)
      save([pathname filename],'COLORTABLE');
    end

    return;

