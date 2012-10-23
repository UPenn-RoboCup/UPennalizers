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
              'Colormap', gray(256), ...
							'KeyPressFcn',@KeyResponse);

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

    % Toggle between masking mode and label preview mode
    DATA.viewmode = 0;

    DATA.LogFilePath = './logs';
    DATA.LogList = {};

    % standard options for all gui elements
    % do not allow callbacks to be interrupted
    Std.Interruptible = 'off';
    % if a callback is triggered while another is still being executed
    % queue that callback (run it after the current one is finished)
    Std.BusyAction = 'queue';

    % create the axis to display the current image
		DATA.LogFileName = uicontrol('Style','text',...
		 										   'Units','Normalized',...
													 'Position',[.35 0.955 0.40 0.04]);
    DATA.PrevLogFile = uicontrol(Std, ...
                                'Parent', hfig,...
                                'Style', 'pushbutton',...
                                'String', 'Prev Log (Z)',...
                                'Callback', 'colortable(''LoadMontage'',''Backward'')',...
                                'Units', 'Normalized',...
                                'Position', [.21 0.955 0.12 0.04]);
    DATA.NextLogFile = uicontrol(Std, ...
                                'Parent', hfig,...
                                'Style', 'pushbutton',...
                                'String', 'Next Log (X)',...
                                'Callback', 'colortable(''LoadMontage'',''Forward'')',...
                                'Units', 'Normalized',...
                                'Position', [.77 0.955 0.12 0.04]);
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
                                  'String', 'Load Montage (L)', ...
                                  'Callback','colortable(''LoadMontage'')', ...
                                  'Units', 'Normalized', ...
                                  'Position', [.025 .90 .15 .05]);

    % create 'Save Colors' button
    DATA.SaveColor = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Save Colors (Q)', ...
                                  'Callback','colortable(''SaveColor'')', ...
                                  'Units', 'Normalized', ...
                                  'Position', [.025 .12 .15 .05]);

    % create 'Save lut' button
    DATA.SaveLut = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Save LUT (W)', ...
                                  'Callback','colortable(''SaveLUT'')', ...
                                  'Units', 'Normalized', ...
                                  'Position', [.025 .05 .15 .05]);

    % create 'Clear Selection' button
    DATA.ClearControl = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Clear Selection (C)', ...
                                  'Callback','colortable(''ClearSelection'')', ...
                                  'Units', 'Normalized', ...
                                  'Position', [.025 .35 .15 .05]);

    % create 'Toggle View' button
    DATA.ToggleView = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Toggle View (T)', ...
                                  'Callback','colortable(''ToggleView'')', ...
                                  'Units', 'Normalized', ...
                                  'Position', [.025 .50 .15 .05]);

    % create the Forward arrow button
    DATA.ForwardControl = uicontrol(Std, ...
                                    'Parent', hfig, ...
                                    'Style', 'pushbutton', ...
                                    'String', '-> (D)', ...
                                    'Callback','colortable(''UpdateImage'',''forward'')', ...
                                    'Units', 'Normalized', ...
                                    'Position', [.65 .05 .07 .05]);

    % create the Backward arrow button
    DATA.BackwardControl = uicontrol(Std, ...
                                      'Parent', hfig, ...
                                      'Style', 'pushbutton', ...
                                      'String', '<- (S)', ...
                                      'Callback','colortable(''UpdateImage'',''backward'')', ...
                                      'Units', 'Normalized', ...
                                      'Position', [.4 .05 .07 .05]);

    % create the double Forward arrow button
    DATA.FastForwardControl = uicontrol(Std, ...
                                        'Parent', hfig, ...
                                        'Style', 'pushbutton', ...
                                        'String', '>> (F)', ...
                                        'Callback','colortable(''UpdateImage'',''fastforward'')', ...
                                        'Units', 'Normalized', ...
                                        'Position', [.75 .05 .07 .05]);

    % create the double Backward arrow button
    DATA.FastBackwardControl = uicontrol(Std, ...
                                          'Parent', hfig, ...
                                          'Style', 'pushbutton', ...
                                          'String', '<< (A)', ...
                                          'Callback','colortable(''UpdateImage'',''fastbackward'')', ...
                                          'Units', 'Normalized', ...
                                          'Position', [.3 .05 .07 .05]);


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
                                             'String', strcat(COLORTABLE.color_name{icolor},' (',num2str(icolor), ')'), ...
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
                                    'String','(E) Threshold (R)', ...
                                    'Units', 'Normalized', ...
                                    'Position', [.025 .30 .15 .035]);


    % set DATA as the gui userdata (so we can access the data later)
    set(hfig, 'UserData', DATA, 'Visible', 'on');
    drawnow;
    return;
	
	function KeyResponse(h_obj, evt)
    if evt.Key == 'z' | evt.Key == 'Z'
      disp('Select Previous Log File');
      LoadMontage('Backward');
    elseif evt.Key == 'x' | evt.Key == 'X'
      disp('Select Next Log File');
      LoadMontage('Forward'); 
    elseif evt.Key == 'a' | evt.Key == 'A'
			disp('Fast Backwards');
			UpdateImage('fastbackward');
		elseif evt.Key == 's' | evt.Key == 'S'
			disp('Backward');
			UpdateImage('backward');
		elseif evt.Key == 'd' | evt.Key == 'D'
			disp('Forward');
			UpdateImage('forward');
		elseif evt.Key == 'f' | evt.Key == 'F'
			disp('Fast Forward');
			UpdateImage('fastforward');
		elseif evt.Key == 't' | evt.Key == 'T'
			disp('ToggleView?');
			ToggleView();
		elseif evt.Key == 'l' | evt.Key == 'L'
			disp('LoadMontage');
			LoadMontage();
		elseif evt.Key == 'c' | evt.Key == 'C'
			disp('ClearSelection');
			ClearSelection();
		elseif evt.Key == 'q' | evt.Key == 'Q'
			disp('SaveColor');
			SaveColor();
		elseif evt.Key == 'w' | evt.Key == 'W'
			disp('SaveLut');
			SaveLUT();
		elseif evt.Key == 'e' | evt.Key == 'E'
			disp('Lower Threshold');
			data = get(h_obj, 'UserData');
			value = get(data.ThresholdControl, 'Value');
			value = value - 1;
			UpdateThreshold(value);
		elseif evt.Key == 'r' | evt.Key == 'R'
			disp('Higher Threshold');
			data = get(h_obj, 'UserData');
			value = get(data.ThresholdControl, 'Value');
			value = value + 1;
			UpdateThreshold(value);
		elseif evt.Key >= '1' & evt.Key <= '7'
			Color(str2num(evt.Key));
		end
				 

  function UpdateImage(index)
  % updates the image displayed in the gui
    global COLORTABLE LUT

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


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Live label view
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if DATA.viewmode 
      class=LUT(DATA.cindex);
      cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
      cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];
      r_cast=cmap(:,1)*255;
      g_cast=cmap(:,2)*255;
      b_cast=cmap(:,3)*255;

      %class starts with 0, index starts with 1 
      im_display(:,:,1)=r_cast(class+1);
      im_display(:,:,2)=g_cast(class+1);
      im_display(:,:,3)=b_cast(class+1);
    end


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


  function LoadMontage(index)
  % callback for the 'Load Montage' button
    global COLORTABLE

    % get the gui userdata
    hfig = gcbf;
    DATA = get(hfig, 'UserData');
    
    if (nargin) 
      index
      pathname = DATA.LogFilePath;
      filename = get(DATA.LogFileName, 'String');
      fileorder = strmatch(filename, strvcat(DATA.LogList.name));
      if strcmp(index,'Forward')
        if (fileorder < size(DATA.LogList,1))
          fileorder = fileorder + 1;
        end
      elseif strcmp(index,'Backward')
        if (fileorder > 1)
          fileorder = fileorder - 1;
        end
      else
      end
      filename = DATA.LogList(fileorder).name;
    else
      % open file select gui
      [filename, pathname] = uigetfile('*.mat', 'Select montage file');
    end

    if (filename ~= 0)
      % if a file was selected
      s = load([pathname filename]);
			set(DATA.LogFileName,'String', filename);
      DATA.LogFilePath = pathname;
      DATA.LogList = dir(strcat(pathname,'/*.mat'));

      % make sure it has a yuyvMontage
      if (isfield(s, 'yuyvMontage'))
        % convert the yuyv montage to yuv data
        yuvMontage = yuyv2yuv(s.yuyvMontage);
        
        % check the image size
        sz = size(yuvMontage);
        if (any(sz(1:2) ~= DATA.size))
          % image size does not match current data size
          %warndlg('YUYV montage image size changed.\nMake sure these images are from the same camera as the previous montage.');
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

  function SaveLUT()
    % callback for the 'Save LUT' button
    global COLORTABLE LUT

    % open file select gui
    [filename, pathname] = uiputfile('*.raw', 'Select lut file to save');

    if (filename ~= 0)
      colortable_smear;
      LUT = colortable_lut();
%      lut_montage(LUT);
      write_lut_file( LUT, [pathname filename] );
      disp(['Saved file ' filename])
    end

    return;

  function ToggleView()
  % callback for the 'Toggle View' button
    global COLORTABLE LUT

    % get the gui userdata
    hfig = gcbf;
    DATA = get(hfig, 'UserData');

    DATA.viewmode = 1-DATA.viewmode;
    %Whenever entering label view, recalculate LUT
    if DATA.viewmode
      colortable_smear;
      LUT = colortable_lut();
    end
    set(hfig, 'UserData', DATA);

    UpdateImage();
    return;


