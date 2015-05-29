require('Config');	-- For Ball and Goal Size
require('HeadTransform');	-- For Projection

min_white_pixel = Config.vision.line.min_white_pixel or 200;
min_green_pixel = Config.vision.line.min_green_pixel or 5000;

--min_width=Config.vision.line.min_width or 4;
max_width=Config.vision.line.max_width or 8;
connect_th=Config.vision.line.connect_th or 1.4;
max_gap=Config.vision.line.max_gap or 1;
min_length=Config.vision.line.min_length or 5;

local update = function(self, color, p_vision)
  --TODO: test line detection
  self.detect = 0;
  linePropsB = ImageProc.field_lines(p_vision.labelB.data, p_vision.labelB.m,
		 p_vision.labelB.n, max_width,connect_th,max_gap,min_length);

  if #linePropsB==0 then 
    --print('no linePropsB')
    return 
  end

  self.propsB=linePropsB;
  nLines=math.min(#self.propsB,12);
  p_vision:add_debug_message(string.format(
    "Total %d lines detected\n" ,nLines));

  self.v={};
  self.endpoint={};
  self.angle={};
  self.length={}

  for i = 1, nLines do
    self.endpoint[i] = vector.zeros(4);
    self.v[i]={};
    self.v[i][1]=vector.zeros(4);
    self.v[i][2]=vector.zeros(4);
    self.angle[i] = 0;
  end


  bestindex=1;
  bestlength=0;
  linecount=0;

  for i=1,nLines do
    local vendpoint = {};
    vendpoint[1] = HeadTransform.coordinatesB(vector.new(
		  {self.propsB[i].endpoint[1],self.propsB[i].endpoint[3]}),1);
    vendpoint[2] = HeadTransform.coordinatesB(vector.new(
		  {self.propsB[i].endpoint[2],self.propsB[i].endpoint[4]}),1);
    vHeight = 0.5*(vendpoint[1][3]+vendpoint[2][3]);

    if self.propsB[i].length > min_length then
      linecount=linecount+1;
      self.length[linecount]=length;
      self.endpoint[linecount]= self.propsB[i].endpoint;
      vendpoint[1] = HeadTransform.projectGround(vendpoint[1],0);
      vendpoint[2] = HeadTransform.projectGround(vendpoint[2],0);
      self.v[linecount]={};
      self.v[linecount][1]=vendpoint[1];
      self.v[linecount][2]=vendpoint[2];
      self.angle[linecount]=math.abs(math.atan2(vendpoint[1][2]-vendpoint[2][2],
			    vendpoint[1][1]-vendpoint[2][1]));
      p_vision:add_debug_message(string.format(
		    "Line %d: (%d %d)->(%d %d) avg(%d %d)\n",
		    linecount,self.propsB[i].endpoint[1],self.propsB[i].endpoint[3],
        self.propsB[i].endpoint[2],self.propsB[i].endpoint[4],
		    self.propsB[i].meanpoint[1],self.propsB[i].meanpoint[2]));
        
    end
  end
  nLines = linecount;
  self.nLines = nLines;
  --[[
  --TODO::::find distribution of v
  sumx=0;
  sumxx=0;
  for i=1,nLines do 
    --angle: -pi to pi
    sumx=sumx+self.angle[i];
    sumxx=sumxx+self.angle[i]*self.angle[i];
  end
  --]]
  if nLines>0 then
    self.detect = 1;
  end
  return
end

local update_shm = function(self, parent_vision)
  vcm.set_line_detect(self.detect);
  if (self.detect == 1) then
    vcm.set_line_nLines(self.nLines);
    local v1x=vector.zeros(12);
    local v1y=vector.zeros(12);
    local v2x=vector.zeros(12);
    local v2y=vector.zeros(12);
    local endpoint11=vector.zeros(12);
    local endpoint12=vector.zeros(12);
    local endpoint21=vector.zeros(12);
    local endpoint22=vector.zeros(12);
    local xMean=vector.zeros(12);
    local yMean=vector.zeros(12);
    max_length=0;
    max_index=1;
    for i=1,self.nLines do 
      v1x[i]=self.v[i][1][1];
      v1y[i]=self.v[i][1][2];
      v2x[i]=self.v[i][2][1];
      v2y[i]=self.v[i][2][2];
      --x0 x1 y0 y1
      endpoint11[i]=self.endpoint[i][1];
      endpoint12[i]=self.endpoint[i][3];
      endpoint21[i]=self.endpoint[i][2];
      endpoint22[i]=self.endpoint[i][4];
      xMean[i]=self.propsB[i].meanpoint[1];
      yMean[i]=self.propsB[i].meanpoint[2];
      if max_length<self.propsB[i].length then
        max_length=self.propsB[i].length;
	      max_index=i;
      end
    end

    --TODO: check line length 

    vcm.set_line_v1x(v1x);
    vcm.set_line_v1y(v1y);
    vcm.set_line_v2x(v2x);
    vcm.set_line_v2y(v2y);
    vcm.set_line_endpoint11(endpoint11);
    vcm.set_line_endpoint12(endpoint12);
    vcm.set_line_endpoint21(endpoint21);
    vcm.set_line_endpoint22(endpoint22);
    vcm.set_line_xMean(xMean);
    vcm.set_line_yMean(yMean);
    vcm.set_line_v({(v1x[max_index]+v2x[max_index])/2,
	 	   (v1y[max_index]+v2y[max_index])/2,0,0});
    vcm.set_line_angle(self.angle[max_index]);

  end

end

local detectLine = {}

function detectLine.entry(parent_vision)
  print('init Line detection')
  local self = {}
  self.update = update
  self.update_shm = update_shm

  self.detect = 0

  return self
end

return detectLine
