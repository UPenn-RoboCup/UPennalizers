function colortable(action, varargin)

global COLORTABLE
if isempty(COLORTABLE),
  colortable_init;
end

if nargin < 1,
  action = 'Initialize';
end

feval(action, varargin{:});
return;

% Subfunction Initialize
function Initialize()
global COLORTABLE

% If colortable is already running, bring it to foreground
%{
h = findobj(allchild(0), 'tag', 'Colortable');
if ~isempty(h),
  figure(h(1));
  return;
end

%	      'NumberTitle','off', 'HandleVisibility', 'on', ...
%	      'IntegerHandle', 'off', ...
hfig = figure('Name', 'UPenn Colortable Selection', ...
	      'tag', 'Colortable', ...
	      'MenuBar', 'figure', ...
	      'ToolBar', 'figure', ...
	      'Color', [.8 .8 .8], ...
	      'Colormap', gray(256));
%}

hfig = gcf;
clf;
set(hfig, 'Name', 'UPenn Colortable Selection', ...
	  'tag', 'Colortable', ...
	  'MenuBar', 'figure', ...
	  'ToolBar', 'figure', ...
	  'Color', [.8 .8 .8], ...
	  'Colormap', gray(256));

figpos = get(hfig, 'Position');
figpos(3:4) = [600 400];
set(hfig, 'Position', figpos);

DATA.size = [240 160];
DATA.cthreshold = 24;
DATA.montage = [];
DATA.icolor = 1;

Std.Interruptible = 'off';
Std.BusyAction = 'queue';
DATA.ImageAxes = axes(Std, ...
		     'Parent', hfig, ...
		     'YDir', 'reverse', ...
		     'XLim', .5+[0 DATA.size(2)], ...
		     'YLim', .5+[0 DATA.size(1)], ...
		     'XTick', [], ...
		     'YTick', [], ...
		     'Units', 'Normalized', ...
		     'Position', [.2 .15 .7 .8]);
DATA.Image = image(Std, ...
		  'Parent', DATA.ImageAxes, ...
		  'XData', [1 DATA.size(2)], ...
		  'YData', [1 DATA.size(1)], ...
		  'ButtonDownFcn', 'colortable(''Button'')', ...
		  'CData', []);

DATA.LoadControl = uicontrol(Std, ...
			    'Parent', hfig, ...
			    'Style', 'pushbutton', ...
			    'String', 'Load Montage', ...
			    'Callback','colortable(''LoadMontage'')', ...
			    'Units', 'Normalized', ...
			    'Position', [.025 .90 .15 .05]);

DATA.SaveControl = uicontrol(Std, ...
			    'Parent', hfig, ...
			    'Style', 'pushbutton', ...
			    'String', 'Save Colors', ...
			    'Callback','colortable(''SaveColor'')', ...
			    'Units', 'Normalized', ...
			    'Position', [.025 .10 .15 .05]);
DATA.ClearControl = uicontrol(Std, ...
			    'Parent', hfig, ...
			    'Style', 'pushbutton', ...
			    'String', 'Clear Selection', ...
			    'Callback','colortable(''ClearSelection'')', ...
			    'Units', 'Normalized', ...
			    'Position', [.025 .35 .15 .05]);

DATA.ForwardControl = uicontrol(Std, ...
			    'Parent', hfig, ...
			    'Style', 'pushbutton', ...
			    'String', '->', ...
			    'Callback','colortable(''UpdateImage'',''forward'')', ...
			    'Units', 'Normalized', ...
			    'Position', [.65 .05 .05 .05]);

DATA.BackwardControl = uicontrol(Std, ...
			    'Parent', hfig, ...
			    'Style', 'pushbutton', ...
			    'String', '<-', ...
			    'Callback','colortable(''UpdateImage'',''backward'')', ...
			    'Units', 'Normalized', ...
			    'Position', [.4 .05 .05 .05]);


DATA.IndexControl = uicontrol(Std, ...
			    'Parent', hfig, ...
			    'Style', 'edit', ...
			    'String', '1', ...
			    'Callback','colortable(''UpdateImage'',str2num(get(gco,''String'')))', ...
			    'Units', 'Normalized', ...
			    'Position', [.5 .05 .1 .06]);

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

DATA.ThresholdControl = uicontrol(Std, ...
				 'Parent', hfig, ...
				 'Style', 'slider', ...
				 'Min', 0, ...
				 'Max', 128, ...
				 'Value', DATA.cthreshold, ...
				 'Callback','colortable(''UpdateThreshold'',get(gco,''Value''))', ...
				 'Units', 'Normalized', ...
				 'Position', [.025 .25 .15 .05]);

DATA.ThresholdEdit = uicontrol(Std, ...
			      'Parent', hfig, ...
			      'Style', 'edit', ...
			      'String', num2str(DATA.cthreshold), ...
			      'Callback','colortable(''UpdateThreshold'',str2num(get(gco,''String'')))', ...
			      'Units', 'Normalized', ...
			      'Position', [.075 .20 .05 .05]);
DATA.ThresholdLabel = uicontrol(Std, ...
			      'Parent', hfig, ...
			      'Style', 'text', ...
			      'String','Threshold', ...
			      'Units', 'Normalized', ...
			      'Position', [.025 .30 .15 .035]);


set(hfig, 'UserData', DATA, 'Visible', 'on');
drawnow;
return;


% Subfunction UpdateImage
function UpdateImage(index)
global COLORTABLE


hfig = gcbf;
DATA = get(hfig, 'userdata');

if isempty(DATA.montage),
  return;
end
nMontage = size(DATA.montage,4);

if ~isfield(DATA, 'iImage'),
  DATA.iImage = 1;
end

if nargin >= 1,
  colortable_merge(DATA);
  
  if strcmp(index,'forward'), 
    DATA.iImage = DATA.iImage + 1;
  elseif strcmp(index,'backward'), 
    DATA.iImage = DATA.iImage - 1;
  else
    DATA.iImage = index;
  end

  DATA.iImage = min(max(DATA.iImage,1),nMontage);
  DATA.yuv = DATA.montage(:,:,:,DATA.iImage);
  DATA.cindex = yuv2index(DATA.yuv, COLORTABLE.size);
  DATA.rgb = ycbcr2rgb(DATA.yuv);

  for icolor = 1:COLORTABLE.ncolor,
    % Clear out mask with new image
    DATA.mask_pos{icolor} = false(DATA.size);
    DATA.mask_neg{icolor} = false(DATA.size);
  end

end

score = colortable_score(DATA.cindex, DATA.icolor);
im_display = DATA.rgb;
if (DATA.icolor == 5) % white
	im_display(:,:,2) = DATA.rgb(:,:,2) - uint8((score>0).*double(DATA.rgb(:,:,2)));
	im_display(:,:,3) = DATA.rgb(:,:,3) - uint8((score>0).*double(DATA.rgb(:,:,3)));
else
	im_display(:,:,2) = DATA.rgb(:,:,2) + uint8(score.*double(255-DATA.rgb(:,:,2)));
end
im_display = rgbmask(im_display, DATA.mask_pos{DATA.icolor}, ...
		     DATA.mask_neg{DATA.icolor}, DATA.icolor);
set(DATA.Image, 'CData', im_display);

set(DATA.IndexControl, 'String', num2str(DATA.iImage));


for icolor = 1:COLORTABLE.ncolor,
  if icolor == DATA.icolor,
    set(DATA.ColorControl(icolor),'Value',1);
  else
    set(DATA.ColorControl(icolor),'Value',0);
  end
end

set(hfig, 'UserData', DATA);

return;

% Subfunction Button
function Button()

hfig = gcbf;
DATA = get(hfig, 'userdata');

pt = get(gca,'CurrentPoint');
ptx = round(pt(1,1));
pty = round(pt(1,2));
mask = rgbselect(DATA.rgb, ptx, pty, DATA.cthreshold);

if strcmp(get(hfig,'SelectionType'),'normal'),
  DATA.mask_pos{DATA.icolor} = DATA.mask_pos{DATA.icolor} | mask;
  DATA.mask_neg{DATA.icolor} = DATA.mask_neg{DATA.icolor} & ~mask;
elseif strcmp(get(hfig,'SelectionType'),'extend'),
  DATA.mask_pos{DATA.icolor} = DATA.mask_pos{DATA.icolor} & ~mask;
  DATA.mask_neg{DATA.icolor} = DATA.mask_neg{DATA.icolor} | mask;
elseif strcmp(get(hfig,'SelectionType'),'alt'),
  DATA.mask_pos{DATA.icolor} = DATA.mask_pos{DATA.icolor} & ~mask;
  DATA.mask_neg{DATA.icolor} = DATA.mask_neg{DATA.icolor} & ~mask;
end

set(hfig, 'UserData', DATA);
UpdateImage();
return;


% Subfunction Color
function Color(icolor)

hfig = gcbf;
DATA = get(hfig, 'userdata');
DATA.icolor = icolor;
set(hfig, 'UserData', DATA);

UpdateImage();
return;

% Subfunction UpdateThreshold
function UpdateThreshold(value)
hfig = gcbf;
DATA = get(hfig, 'userdata');

DATA.cthreshold = round(value);
set(DATA.ThresholdControl,'Value',DATA.cthreshold);
set(DATA.ThresholdEdit,'String',num2str(DATA.cthreshold));
set(hfig, 'UserData', DATA);
return;

% Subfunction LoadMontage
function LoadMontage()
hfig = gcbf;
DATA = get(hfig, 'userdata');

[filename, pathname] = uigetfile('*.mat', 'Select montage file');
if filename ~= 0,
  s = load([pathname filename]);
%  if isfield(s, 'yuvMontage'),
  if isfield(s, 'yuyvMontage'),
    DATA.montage = yuyv2yuv(s.yuyvMontage);
    set(hfig, 'UserData', DATA);
    UpdateImage(1);
  end
end

% Subfunction ClearSelection
function ClearSelection()
global COLORTABLE

hfig = gcbf;
DATA = get(hfig, 'userdata');

DATA.mask_pos{DATA.icolor} = false(DATA.size);
DATA.mask_neg{DATA.icolor} = false(DATA.size);

set(hfig, 'UserData', DATA);
UpdateImage();

% Subfunction SaveColor
function SaveColor()
global COLORTABLE

[filename, pathname] = uiputfile('*.mat', 'Select colortable file to save');
if filename ~= 0,
  save([pathname filename],'COLORTABLE');
end
