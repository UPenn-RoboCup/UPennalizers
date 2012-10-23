module(..., package.seeall);

require('Config');	-- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');	-- For Projection
require('Vision');

-- Dependency
require('Detection');

-- Define Color
colorOrange = 1;
colorYellow = 2;
colorCyan = 4;
colorField = 8;
colorWhite = 16;

min_white_pixel = Config.vision.line.min_white_pixel or 200;
min_green_pixel = Config.vision.line.min_green_pixel or 5000;

--min_width=Config.vision.line.min_width or 4;
max_width=Config.vision.line.max_width or 8;
connect_th=Config.vision.line.connect_th or 1.4;
max_gap=Config.vision.line.max_gap or 1;
min_length=Config.vision.line.min_length or 3;

function detect()
  --TODO: test line detection
  line = {};
  line.detect = 0;

  if (Vision.colorCount[colorWhite] < min_white_pixel) then 
    --print('under 200 white pixels');
    return line;
  end
  if (Vision.colorCount[colorField] < min_green_pixel) then 
    --print('under 5000 green pixels');
    return line; 
  end

  linePropsB = ImageProc.field_lines(Vision.labelB.data, Vision.labelB.m,
		 Vision.labelB.n, max_width,connect_th,max_gap,min_length);

  if #linePropsB==0 then 
    --print('linePropsB nil')
    return line; 
  end

  line.propsB=linePropsB;
  nLines=0;

  nLines=#line.propsB;
  vcm.add_debug_message(string.format(
    "Total %d lines detected\n" ,nLines));

  if (nLines==0) then
    return line; 
  end

  line.v={};
  line.endpoint={};
  line.angle={};
  line.length={}

  for i = 1,6 do
    line.endpoint[i] = vector.zeros(4);
    line.v[i]={};
    line.v[i][1]=vector.zeros(4);
    line.v[i][2]=vector.zeros(4);
    line.angle[i] = 0;
  end


  bestindex=1;
  bestlength=0;
  linecount=0;

  for i=1,nLines do
    local length = math.sqrt(
	(line.propsB[i].endpoint[1]-line.propsB[i].endpoint[2])^2+
	(line.propsB[i].endpoint[3]-line.propsB[i].endpoint[4])^2);

      local vendpoint = {};
      vendpoint[1] = HeadTransform.coordinatesB(vector.new(
		{line.propsB[i].endpoint[1],line.propsB[i].endpoint[3]}),1);
      vendpoint[2] = HeadTransform.coordinatesB(vector.new(
		{line.propsB[i].endpoint[2],line.propsB[i].endpoint[4]}),1);

      vHeight = 0.5*(vendpoint[1][3]+vendpoint[2][3]);

      vHeightMax = 0.50;

    if length>min_length and linecount<6 and vHeight<vHeightMax then
      linecount=linecount+1;
      line.length[linecount]=length;
      line.endpoint[linecount]= line.propsB[i].endpoint;
      vendpoint[1] = HeadTransform.projectGround(vendpoint[1],0);
      vendpoint[2] = HeadTransform.projectGround(vendpoint[2],0);
      line.v[linecount]={};
      line.v[linecount][1]=vendpoint[1];
      line.v[linecount][2]=vendpoint[2];
      line.angle[linecount]=math.abs(math.atan2(vendpoint[1][2]-vendpoint[2][2],
			    vendpoint[1][1]-vendpoint[2][1]));
      vcm.add_debug_message(string.format(
		"Line %d: length %d, angle %d\n",
		linecount,line.length[linecount],
		line.angle[linecount]*180/math.pi));
    end
  end
  nLines = linecount;
  line.nLines = nLines;

  --TODO::::find distribution of v
  sumx=0;
  sumxx=0;
  for i=1,nLines do 
    --angle: -pi to pi
    sumx=sumx+line.angle[i];
    sumxx=sumxx+line.angle[i]*line.angle[i];
  end

  if nLines>0 then
    line.detect = 1;
  end
  return line;
end
