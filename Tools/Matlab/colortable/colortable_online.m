function h = colortable_online(action, varargin)
  global COLORTABLE LUT DATA ROBOT;
  h.Initialize = @Initialize;
  h.update = @update;
  h.Color = @Color;
%
% main function for the colortable/lut training gui
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Sub-Function Definitions %%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  function Initialize(img_size)
  % initialize the colortable gui
  % creates the gui and ui elements for the colortable trainer

    % create the gui
    hfig = gcf;
    clf;
    set(hfig, 'Name', 'UPenn Colortable Selection', ...
              'NumberTitle', 'off', ...
              'tag', 'Colortable', ...
              'MenuBar', 'none', ...
              'ToolBar', 'none', ...
              'Color', [.8 .8 .8], ...
              'Colormap', gray(256), ...
							'KeyPressFcn',@KeyResponse);

    % set the figure window size
    scrsz = get(0, 'ScreenSize');
    figpos = get(hfig, 'Position');
    figpos(3:4) = [1100 600];
    figpos = [scrsz(3)/2 - figpos(3)/2, scrsz(4) - figpos(4)/2, figpos(3), figpos(4)];
    set(hfig, 'Position', figpos);

    % default image size 
    DATA.size = [img_size(2)/2 img_size(1)];

    % init mask 
    for icolor = 1:COLORTABLE.ncolor
      % clear out mask with new image
      DATA.mask_pos{icolor} = false(DATA.size);
      DATA.mask_neg{icolor} = false(DATA.size);
    end

    % default color threshold value
    DATA.cthreshold = 14;
    % array containing the training images
    DATA.montage = [];
    % index of the current color
    DATA.icolor = 1;

    % Toggle between masking mode and label preview mode
    DATA.viewmode = 0;

    % standard options for all gui elements
    % do not allow callbacks to be interrupted
    Std.Interruptible = 'off';
    % if a callback is triggered while another is still being executed
    % queue that callback (run it after the current one is finished)
    Std.BusyAction = 'queue';

    fontsize = 13;
    %{
    DATA.PennLogo = imread('UPenn_Eng.jpeg');
    DATA.ImgPennLogoAxis = axes(Std, ...
                           'Parent', hfig, ...
                           'YDir', 'reverse', ...
                           'XLim', .5+[0 size(DATA.PennLogo, 1)], ...
                           'YLim', .5+[0 size(DATA.PennLogo, 2)], ...
                           'XTick', [], ...
                           'YTick', [], ...
                           'Units', 'Normalized', ...
                           'Position', [.5 0 .087 .2]);
    DATA.ImgPennLogo = image(Std, ...
                        'Parent', DATA.ImgPennLogoAxis, ...
                        'XData', [1 size(DATA.PennLogo,1)], ...
                        'YData', [1 size(DATA.PennLogo,2)], ...
                        'CData', DATA.PennLogo);   
    DATA.GRASPLogo = imread('GRASP.png');
%}
    % create the axis to display the current image
    DATA.TitleText = uicontrol(Std, ...
                                    'Parent', hfig, ...
                                    'Style', 'text', ...
                                    'String','', ...
                                    'Units', 'Normalized', ...
                                    'FontSize', fontsize + 8, ...
                                    'Position', [.365 .96 .25 .035]);

    DATA.ImagePanel = uipanel('Parent', hfig, ...
                              'Title', 'Images', ...
                              'BackgroundColor', [.8 .8 .8], ...
                              'Position', [.025 .25 .96 .7], ...
                              'FontSize', fontsize);
    DATA.ImageAxes = subplot(2, 3, [1 2 4 5], ...
                           'Parent', DATA.ImagePanel, ...
                           'YDir', 'reverse', ...
                           'XLim', .5+[0 DATA.size(2)], ...
                           'YLim', .5+[0 DATA.size(1)], ...
                           'XTick', [], ...
                           'YTick', [], ...
                           'Position', [0.02 0.045 0.45 0.9], ...
                           'Units', 'Normalized');

    % create the handle for the image data
    DATA.Image = image(Std, ...
                        'Parent', DATA.ImageAxes, ...
                        'XData', [1 DATA.size(2)], ...
                        'YData', [1 DATA.size(1)], ...
                        'ButtonDownFcn', @Button, ...
                        'CData', []);

    DATA.LabelAxes = subplot(2, 3, [3 6 ], ...
                           'Parent', DATA.ImagePanel, ...
                           'YDir', 'reverse', ...
                           'XLim', .5+[0 DATA.size(2)], ...
                           'YLim', .5+[0 DATA.size(1)], ...
                           'XTick', [], ...
                           'YTick', [], ...
                           'Position', [0.5 0.045 0.45 0.9], ...
                           'Units', 'Normalized');

    % create the handle for the image data
    DATA.Label = image(Std, ...
                        'Parent', DATA.LabelAxes, ...
                        'XData', [1 DATA.size(2)], ...
                        'YData', [1 DATA.size(1)], ...
                        'ButtonDownFcn', @Button, ...
                        'CData', []);


    % create 'Save Colors' button
    DATA.SaveColor = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Save Colors', ...
                                  'Callback',@SaveColor, ...
                                  'Units', 'Normalized', ...
                                  'FontSize', fontsize, ...
                                  'Position', [.725 .18 .15 .05]);

    % create 'Save lut' button
    DATA.SaveLut = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Save LUT', ...
                                  'Callback',@SaveLUT, ...
                                  'Units', 'Normalized', ...
                                  'FontSize', fontsize, ...
                                  'Position', [.725 .10 .15 .05]);

    % create 'Clear Selection' button
    DATA.ClearControl = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Clear Selection', ...
                                  'Callback',@ClearSelection, ...
                                  'Units', 'Normalized', ...
                                  'FontSize', fontsize, ...
                                  'Position', [.525 .10 .15 .05]);

    DATA.ClearLUT = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Clear Colortable', ...
                                  'Callback',@ClearLUT, ...
                                  'Units', 'Normalized', ...
                                  'FontSize', fontsize, ...
                                  'Position', [.525 .18 .15 .05]);

                                  %{
    DATA.ReloadLUT = uicontrol(Std, ...
                                  'Parent', hfig, ...
                                  'Style', 'pushbutton', ...
                                  'String', 'Reload Colortable', ...
                                  'Callback',@ReloadLUT, ...
                                  'Units', 'Normalized', ...
                                  'Position', [.025 .49 .15 .05]);
%}

    % create the selection array for the colors of interest
%    for icolor = 1:COLORTABLE.ncolor,
      icolor = 1;
      DATA.ColorControl(icolor) = uicontrol(Std, ...
                                             'Parent', hfig, ...
                                             'Style', 'radiobutton', ...
                                             'String', 'Ball', ...
                                             'UserData', icolor, ...
                                             'Callback',@Color,...
                                             'Value', 0, ...
                                             'Units', 'Normalized', ...
                                             'FontSize', fontsize, ...
                                             'Position', [.215 .23-.045*icolor .15 .05]);
      icolor = 2;
      DATA.ColorControl(icolor) = uicontrol(Std, ...
                                             'Parent', hfig, ...
                                             'Style', 'radiobutton', ...
                                             'String', 'Not Ball', ...
                                             'UserData', icolor, ...
                                             'Callback',@Color,...
                                             'Value', 0, ...
                                             'Units', 'Normalized', ...
                                             'FontSize', fontsize, ...
                                             'Position', [.215 .23-.045*icolor .15 .05]);      
      icolor = 4;
      DATA.ColorControl(icolor) = uicontrol(Std, ...
                                             'Parent', hfig, ...
                                             'Style', 'radiobutton', ...
                                             'String', 'Field', ...
                                             'UserData', icolor, ...
                                             'Callback',@Color,...
                                             'Value', 0, ...
                                             'Units', 'Normalized', ...
                                             'FontSize', fontsize, ...
                                             'Position', [.215 .23-.045*(icolor-1) .15 .05]);

%    end

    % create the color selection threshold slider
    DATA.ThresholdControl = uicontrol(Std, ...
                                       'Parent', hfig, ...
                                       'Style', 'slider', ...
                                       'Min', 0, ...
                                       'Max', 128, ...
                                       'Value', DATA.cthreshold, ...
                                       'Callback',@UpdateThreshold, ...
                                       'Units', 'Normalized', ...
                                       'Position', [.325 .13 .15 .05]);

    % create the color selection threshold edit box
    DATA.ThresholdEdit = uicontrol(Std, ...
                                    'Parent', hfig, ...
                                    'Style', 'edit', ...
                                    'String', num2str(DATA.cthreshold), ...
                                    'Callback',@UpdateThreshold, ...
                                    'Units', 'Normalized', ...
                                    'FontSize', fontsize, ...
                                    'Position', [.375 .10 .05 .05]);

    % create the color selection title label
    DATA.ThresholdLabel = uicontrol(Std, ...
                                    'Parent', hfig, ...
                                    'Style', 'text', ...
                                    'String','Threshold', ...
                                    'HorizontalAlignment', 'center', ...
                                    'Units', 'Normalized', ...
                                    'FontSize', fontsize, ...
                                    'Position', [.325 .18 .15 .035]);

    DATA.CurLUTLabel = uicontrol(Std, ...
                                    'Parent', hfig, ...
                                    'Style', 'text', ...
                                    'String','Currrent LUT', ...
                                    'HorizontalAlignment', 'center', ...
                                    'Units', 'Normalized', ...
                                    'FontSize', fontsize, ...
                                    'Position', [.025 .185 .15 .035]);

    DATA.CurLUTName = uicontrol(Std, ...
                                    'Parent', hfig, ...
                                    'Style', 'text', ...
                                    'String','', ...
                                    'HorizontalAlignment', 'center', ...
                                    'Units', 'Normalized', ...
                                    'FontSize', fontsize, ...
                                    'Position', [.025 .15 .15 .035]);


    % set DATA as the gui userdata (so we can access the data later)
    set(hfig, 'UserData', DATA, 'Visible', 'on');
    drawnow;
    return;
  end
	
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
  end
				 
  function Button(varargin)
  % callback for clicking on the image
tic;
    % get the gui userdata
    hfig = gcbf;

    % get the pointer position
    pt = get(gca,'CurrentPoint');
    ptx = round(pt(1,1));
    pty = round(pt(1,2));

    yuv = DATA.yuv;
    cur_lut = typecast(ROBOT.vcmImage.get_lut(),'uint8');

    if DATA.icolor == 2 
      colortable_init();
      lut_updated = ROBOT.matcmControl.get_lut_updated();
      disp('push shm from matlab');
      ROBOT.matcmControl.set_lut_updated(1 - lut_updated);
      cur_lut(find(cur_lut == 1)) = 0;
      ROBOT.vcmImage.set_lut(typecast(cur_lut,'double'));
      set(DATA.TitleText, 'String', 'Transmitting...');
      pause(1.8);
      set(DATA.TitleText, 'String', '');
    else

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
  
      % update color score data
      colortable_merge(DATA);
  
      % convert yuv data into the index values of LUT
      DATA.cindex = yuv2index(yuv, COLORTABLE.size);
  
      % get the current colortable score
      score = colortable_score(DATA.cindex, DATA.icolor);
  
      colortable_smear;
      LUT = colortable_lut();
  
      lut_updated = ROBOT.matcmControl.get_lut_updated();
      disp('push shm from matlab');
      ROBOT.matcmControl.set_lut_updated(1 - lut_updated);
      max_lut = max(cur_lut, LUT');
      ROBOT.vcmImage.set_lut(typecast(max_lut,'double'));
%    ROBOT.vcmImage.set_lut(typecast(cur_lut,'double'));
      set(DATA.TitleText, 'String', 'Transmitting...');
      pause(1.8)
      set(DATA.TitleText, 'String', '');
    end

    DATA.mask_pos{DATA.icolor} = false(DATA.size);
    DATA.mask_neg{DATA.icolor} = false(DATA.size);
toc;
  end

  function ClearLUT(varargin)
    colortable_init();
    lut = zeros(1, 262144, 'uint8');
    lut = typecast(lut, 'double');
    lut_updated = ROBOT.matcmControl.get_lut_updated();
    disp('push emtpy shm from matlab');
    ROBOT.matcmControl.set_lut_updated(1 - lut_updated);
    ROBOT.vcmImage.set_lut(lut);
  end




  function Color(varargin)
  % callback for selecting a color from the radio button array
    icolor = get(varargin{1}, 'UserData');
    % get the gui userdata
    hfig = gcbf;

    % get the selected color
    DATA.icolor = icolor;

    % update the selected color radio button (highlight)
%    for icolor = 1:COLORTABLE.ncolor
%      if (icolor == DATA.icolor)
%        set(DATA.ColorControl(icolor), 'Value', 1);
%      else
%        set(DATA.ColorControl(icolor), 'Value', 0);
%      end
%    end
    if (icolor == 1)
      set(DATA.ColorControl(1), 'Value', 1);
      set(DATA.ColorControl(2), 'Value', 0);
      set(DATA.ColorControl(4), 'Value', 0);
    elseif (icolor == 4)
      set(DATA.ColorControl(4), 'Value', 1);
      set(DATA.ColorControl(2), 'Value', 0);
      set(DATA.ColorControl(1), 'Value', 0);    
    elseif (icolor == 2)
      set(DATA.ColorControl(4), 'Value', 0);
      set(DATA.ColorControl(2), 'Value', 1);
      set(DATA.ColorControl(1), 'Value', 0);
    end
  end


  function UpdateThreshold(varargin)
  % callback for the color selection threshold slider
    if varargin{1} == DATA.ThresholdControl
      value = get(varargin{1}, 'Value');
    elseif varargin{1} == DATA.ThresholdEdit
      value = str2num(get(varargin{1}, 'String'));
    end

    % get the gui userdata
    hfig = gcbf;

    % set the new threshold value
    DATA.cthreshold = round(value);
    % update the threshold value display
    set(DATA.ThresholdControl, 'Value', DATA.cthreshold);
    set(DATA.ThresholdEdit, 'String', num2str(DATA.cthreshold));
  end


  function ClearSelection(varargin)
  % callback for the 'Clear Selection' button

    % re-initialize masks
    DATA.mask_pos{DATA.icolor} = false(DATA.size);
    DATA.mask_neg{DATA.icolor} = false(DATA.size);

  end


  function SaveColor(varargin)
  % callback for the 'Save Colors' button

    % open the save file gui
    [filename, pathname] = uiputfile('*.mat', 'Select colortable file to save');
    if (filename ~= 0)
      save([pathname filename],'COLORTABLE');
    end
  end

  function SaveLUT(varargin)
    % callback for the 'Save LUT' button

    % open file select gui
    [filename, pathname] = uiputfile('*.raw', 'Select lut file to save');

    if (filename ~= 0)
%      colortable_smear;
%      LUT = colortable_lut();
%      lut_montage(LUT);
      LUT = typecast(ROBOT.vcmImage.get_lut(),'uint8');
      write_lut_file( LUT, [pathname filename] );
      disp(['Saved file ' filename])
    end

    return;
  end

  function update(yuyv_type)
    set(DATA.CurLUTName, 'String', char(ROBOT.vcmCamera.get_lut_filename())); 
    cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];cbrc=[0.5 0.5 1];cbrp=[1 0.5 0.5];
    cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg];
    cmapw = repmat(cw,16,1);
    cmap = [cmap;cmapw];
    cmaprc = repmat(cbrc,32,1);
    cmap = [cmap;cmaprc];
    cmap(end+1,:) = cbrp;

    % Show yuyv Image
    if yuyv_type == 1
      yuyv = ROBOT.get_yuyv(); 
    elseif yuyv_type == 2
      yuyv = ROBOT.get_yuyv2();
    elseif yuyv_type == 3
      yuyv = ROBOT.get_yuyv3();
    else
      return;
    end
%    labelA = ROBOT.get_labelA(); 
    lut = typecast(ROBOT.vcmImage.get_lut(), 'uint8');
    labelA = yuyv2label(yuyv, lut);
    [ycbcr, rgb] = yuyv2rgb(yuyv);
    DATA.yuv = ycbcr;
    DATA.rgb = rgb;
    set(DATA.Image, 'CData', rgb);
%    image(rgb, 'Parent', DATA.ImageAxes);

    % Show Label A
    colormap(cmap);
%    cla(DATA.LabelAxes);
    set(DATA.Label, 'CData', labelA);
%    image(labelA', 'Parent', DATA.LabelAxes);

%    r_mon = ROBOT.get_monitor_struct();
%    if (r_mon.ball.detect == 1)
%      hold on;
%      plot_ball(r_mon.ball, 2, DATA.LabelAxes);
%      hold off;
%    end
    % Show mask
%    mask_disp = DATA.mask_pos{DATA.icolor};
%    set(DATA.Mask, 'CData', mask_disp);
    drawnow;
  end

  function plot_ball( ballStats, scale, handle)
    radius = (ballStats.axisMajor / 2) / scale;
    centroid = [ballStats.centroid.x ballStats.centroid.y] / scale;
    ballBox = [centroid(1)-radius centroid(2)-radius 2*radius 2*radius];
    plot( handle, centroid(1), centroid(2),'k+')
    if( ~isnan(ballBox) )
      rectangle('Position', ballBox, 'Curvature',[1,1])

      strballpos = sprintf('%.2f %.2f',ballStats.x,ballStats.y);
      b_name=text(centroid(1),centroid(2)+radius, strballpos);
      set(b_name,'FontSize',8);
    end
  end

end
