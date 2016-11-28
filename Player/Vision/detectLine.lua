require('Config');	-- For Ball and Goal Size
require('HeadTransform');	-- For Projection
require('vcm');

	min_white_pixel = Config.vision.line.min_white_pixel or 200;
	min_green_pixel = Config.vision.line.min_green_pixel or 5000;
	lwratio = Config.vision.line.lwratio or 2
	max_width=Config.vision.line.max_width or 8;
	connect_th=Config.vision.line.connect_th or 1.4;
	max_gap=Config.vision.line.max_gap or 1;
	min_length=Config.vision.line.min_length or 5;

local update = function(self, color, p_vision)
	self.detect = 0; 
	linePropsB = ImageProc.field_lines(p_vision.labelB.data, p_vision.labelB.m,
	p_vision.labelB.n, max_width,connect_th,max_gap,min_length);
  if #linePropsB==0 then return end
  self.propsB=linePropsB;
	nLines=math.min(#self.propsB,12);
  -- p_vision:add_debug_message(string.format("Total %d lines detected\n" ,nLines));
  self.detect = 1;
 	self.v={};
 	self.endpoint={};
  self.angle={};
  self.meanpoint={};
  self.length={};
  bestindex=1;
  bestlength=0;
  linecount=0;
  for i = 1, nLines do
	  self.endpoint[i] = vector.zeros(4);
	  self.v[i]={};
	  self.v[i][1]=vector.zeros(4);
    self.v[i][2]=vector.zeros(4);
    self.angle[i] = 0;
	end
  local function in_bbox(pointx, pointy, bbox)
	  if (pointx>=bbox[1] and pointx<=bbox[2]
	   	and pointy>=bbox[3] and pointy<=bbox[4]) then
	   	return true
    else 
      return false 
    end
	end

	for i=1,nLines do

    -- Print line info
    -- table.foreach(self.propsB[i],
    --   function (k, v)
    --     if type(v) == "table" then
    --       print(k);
    --       table.foreach(v, print)
    --     else
    --       print(k, v)
    --     end
    --   end);
    local valid = true

    -- Remove lines above the horizon
    if self.propsB[i].endpoint[3] < HeadTransform.get_horizonB() or self.propsB[i].endpoint[4] < HeadTransform.get_horizonB() then
      valid = false;
    end

    --valid keeps track of if the line is a line
    --we assume that it is true at first, but change it to false if it is actually a Spot or a Goalpost
    
    --check if the line is actually a Spot
    if vcm.get_spot_detect() == 1 then
    	local spotbboxB = vcm.get_spot_bboxB()
    	if in_bbox(self.propsB[i].endpoint[1],self.propsB[i].endpoint[3],spotbboxB) or 
        in_bbox(self.propsB[i].endpoint[2],self.propsB[i].endpoint[4],spotbboxB) then
        -- p_vision:add_debug_message(string.format("spot check failed\n")) 
        valid = false
      end
    end
    if valid then
      local ratio = self.propsB[i].length/self.propsB[i].max_width;
      if ratio<=lwratio then 
      	-- p_vision:add_debug_message(string.format("Line too fat %.2f < .2f\n",ratio,lwratio));
      	valid = false
      end
    end 
    -- Check if the line is actually a Goalpost
    -- if it is a vertical line and goes all the way to top
    -- we don't do goalpost detection on the bottom camera, so check if everything works with this commented out
    --[[
    if valid then
    	if 3 >= math.abs(self.propsB[i].endpoint[2]-self.propsB[i].endpoint[1]) then
      	if ImageProc.line_connect(p_vision.labelB.data, p_vision.labelB.m,p_vision.labelB.n,
         	self.propsB[i].meanpoint[1],self.propsB[i].meanpoint[2],
         	self.propsB[i].meanpoint[1],1) > 0 then
        	-- p_vision:add_debug_message(string.format("(%d %d)->(%d %d) post check fail\n",
        	-- self.propsB[i].endpoint[1],self.propsB[i].endpoint[3],
        	-- self.propsB[i].endpoint[2],self.propsB[i].endpoint[4]));
        	valid = false
        end
      end
    end
    ]]
    if valid then
      local vendpoint = {};
    	vendpoint[1] = HeadTransform.coordinatesB(vector.new(
  	    {self.propsB[i].endpoint[1],self.propsB[i].endpoint[3]}),1);
    	vendpoint[2] = HeadTransform.coordinatesB(vector.new(
  		  {self.propsB[i].endpoint[2],self.propsB[i].endpoint[4]}),1);
      linecount=linecount+1;
    	self.length[linecount]=length;
    	self.endpoint[linecount]= self.propsB[i].endpoint;
    	vendpoint[1] = HeadTransform.projectGround(vendpoint[1],0);
    	vendpoint[2] = HeadTransform.projectGround(vendpoint[2],0);
    	self.v[linecount]={};
    	self.v[linecount][1]=vendpoint[1];
    	self.v[linecount][2]=vendpoint[2];
    	local angle = math.atan2(vendpoint[1][2]-vendpoint[2][2],
      vendpoint[1][1]-vendpoint[2][1]);
      if angle<=0 then angle=angle+math.pi end
      self.angle[linecount] = angle;
      self.meanpoint[linecount]={};
      self.meanpoint[linecount][1]=self.propsB[i].meanpoint[1];
      self.meanpoint[linecount][2]=self.propsB[i].meanpoint[2];
    end       
  end
  nLines = linecount;

  if p_vision.camera_index == 2 then
    self.ballOnLineCheck_info = {};
    self.ballOnLineCheck_info["nLines"] = nLines;
    self.ballOnLineCheck_info["endpoint"] = self.endpoint;
    self.ballOnLineCheck_info["v"] = self.v;
  end  

	-- connect line segments in the same line
 	-- Use equal table to label line segments on the same line
	self.equalTable = {}
	for i=1,nLines do self.equalTable[i]=i end
	for i=1,nLines do
  	for j=i+1,nLines do
  		if math.abs(self.angle[i]-self.angle[j]) < 15/180*math.pi then
        local v_meanpoint_i = HeadTransform.coordinatesB(vector.new({self.meanpoint[i][1],self.meanpoint[i][2]}), 1);
        v_meanpoint_i = HeadTransform.projectGround(v_meanpoint_i, 0);
        local v_meanpoint_j = HeadTransform.coordinatesB(vector.new({self.meanpoint[j][1],self.meanpoint[j][2]}), 1);
        v_meanpoint_j = HeadTransform.projectGround(v_meanpoint_j, 0);
        local meanpoint_angle = math.atan2(v_meanpoint_i[2]-v_meanpoint_j[2], v_meanpoint_i[1]-v_meanpoint_j[1]);
        -- p_vision:add_debug_message(string.format("%.2f, %.2f, %.2f\n", self.angle[i], self.angle[j], meanpoint_angle));
        if math.abs(meanpoint_angle - (self.angle[i] + self.angle[j]) / 2) < 10/180*math.pi then
          -- If top camera, don't use ImageProc.line_connect

          local lineEndpointsAreClose = function(line1, line2)
            if math.sqrt((line1[1][1] - line2[1][1])^2 + (line1[1][2] - line2[1][2]^2)) < 1 or
              math.sqrt((line1[1][1] - line2[2][1])^2 + (line1[1][2] - line2[2][2]^2)) < 1 or
              math.sqrt((line1[2][1] - line2[1][1])^2 + (line1[2][2] - line2[1][2]^2)) < 1 or
              math.sqrt((line1[2][1] - line2[2][1])^2 + (line1[2][2] - line2[2][2]^2)) < 1 then
              return true
            else
              return false
            end
          end

          if lineEndpointsAreClose(self.v[i], self.v[j]) then
            if p_vision.camera_index == 1 or ImageProc.line_connect(p_vision.labelB.data, p_vision.labelB.m,p_vision.labelB.n,
            	self.meanpoint[i][1],self.meanpoint[i][2],
           		self.meanpoint[j][1],self.meanpoint[j][2]) > 0 then
          		-- p_vision:add_debug_message(string.format("L%d and L%d is one line\n",i,j))
          		local ind = math.min(i,self.equalTable[i],self.equalTable[j]);
            	self.equalTable[j] = ind;
            	self.equalTable[i] = ind;
            end
          end
        end
      end
    end
  end
  for i=1,nLines do 
  	if self.equalTable[i]~=i then
    	rootind = self.equalTable[i];
    	xseries = {self.endpoint[i][1],self.endpoint[rootind][1],
        self.endpoint[i][2],self.endpoint[rootind][2]}
    	yseries = {self.endpoint[i][3],self.endpoint[rootind][3],
        self.endpoint[i][4],self.endpoint[rootind][4]}
    	xprojseries = {self.v[i][1][1],self.v[rootind][1][1],
        self.v[i][2][1],self.v[rootind][2][1]}
    	yprojseries = {self.v[i][1][2],self.v[rootind][1][2],
        self.v[i][2][2],self.v[rootind][2][2]}
    	xmin = math.min(xseries[1],xseries[2],xseries[3],xseries[4]); 
    	xmax = math.max(xseries[1],xseries[2],xseries[3],xseries[4]);
    	for j=1,4 do
        if xmin==xseries[j] then 
          ymin=yseries[j];xprojmin=xprojseries[j];yprojmin=yprojseries[j]; 
        end
      	if xmax==xseries[j] then 
        	ymax=yseries[j];xprojmax=xprojseries[j];yprojmax=yprojseries[j]; 
      	end
    	end
  		-- connect things in labelB and do the transform again
		  self.endpoint[rootind][1]=xmin; self.endpoint[rootind][2]=xmax;
		  self.endpoint[rootind][3]=ymin; self.endpoint[rootind][4]=ymax;
      x1 = self.meanpoint[i][1]
      y1 = self.meanpoint[i][2]
      x2 = self.meanpoint[rootind][1]
      y2 = self.meanpoint[rootind][2]
		  -- Dickens: this is an easy fix: use the midpoint of endpoint
      -- should use color_count
      self.meanpoint[rootind][1]=(xmin+xmax)/2
      self.meanpoint[rootind][2]=(ymin+ymax)/2
      
      local vendpoint = {};
		  vendpoint[1] = HeadTransform.coordinatesB(vector.new(
		    {self.endpoint[rootind][1],self.endpoint[rootind][3]}),1);
		  vendpoint[2] = HeadTransform.coordinatesB(vector.new(
			  {self.endpoint[rootind][2],self.propsB[i].endpoint[4]}),1);
      --
      vendpoint[1] = HeadTransform.projectGround(vendpoint[1], 0);
      vendpoint[2] = HeadTransform.projectGround(vendpoint[2], 0);
      self.v[rootind][1] = vendpoint[1];
      self.v[rootind][2] = vendpoint[2];
      --
		  -- self.v[rootind][1] = {xprojmin, yprojmin};
	    --  self.v[rootind][2] = {xprojmax, yprojmax};
		  -- local angle = math.atan2(yprojmax-yprojmin,xprojmax-xprojmin);
      -- 	if angle<=0 then angle=angle+math.pi end
      --
      local angle = math.atan2(vendpoint[1][2]-vendpoint[2][2],
      vendpoint[1][1]-vendpoint[2][1]);
      if angle<=0 then angle=angle+math.pi end
      --
    	self.angle[rootind] = angle;
    end
  end
  local validcount=0;
  for i=1,nLines do
    if self.equalTable[i] == i then
     	validcount = validcount+1;
    	--i is no less then validcount
	    self.endpoint[validcount]=self.endpoint[i];
      self.meanpoint[validcount]=self.meanpoint[i];
	    self.v[validcount]=self.v[i];
	    self.angle[validcount]=self.angle[i];
	    --[[
      p_vision:add_debug_message(string.format("L%d: (%d %d)->(%d %d) angle %d v: (%.2f, %.2f) length: %.2f\n",
	    i,self.endpoint[validcount][1],self.endpoint[validcount][3],
	    self.endpoint[validcount][2],self.endpoint[validcount][4],
		  180/math.pi*self.angle[validcount], (self.v[validcount][1][1]+self.v[validcount][2][1])/2,
      (self.v[validcount][1][2]+self.v[validcount][2][2])/2,
      math.sqrt((self.v[validcount][2][1]-self.v[validcount][1][1])^2 + (self.v[validcount][2][2]-self.v[validcount][1][2])^2)));
      --]]
      -- print("i = "..validcount);
      -- print("endpoint:");
      -- table.foreach(self.endpoint[validcount], print);
      -- print("meanpoint:");
      -- table.foreach(self.meanpoint[validcount], print);
      -- print("v:");
      -- table.foreach(self.v[validcount], function (k, v) table.foreach(v, print) end);
      -- print("angle = "..self.angle[validcount]);
    end
  end
  self.nLines = validcount;
  return
end

local update_shm = function(self, parent_vision)
  local cidx = parent_vision.camera_index;
  parent_vision:add_debug_message("cidx: "..cidx.." detect: "..self.detect);
  vcm['set_line'..cidx..'_detect'](self.detect);
  if (self.detect == 1) then
    local v1x=vector.zeros(12);
    local v1y=vector.zeros(12);
    local v2x=vector.zeros(12);
    local v2y=vector.zeros(12);
    local real_length=vector.zeros(12);
    local endpoint11=vector.zeros(12);
    local endpoint12=vector.zeros(12);
    local endpoint21=vector.zeros(12);
    local endpoint22=vector.zeros(12);
    local xMean = vector.zeros(12);
    local yMean = vector.zeros(12);
    max_length=0;
    max_real_length = 0;
    max_index=1;
    for i=1,self.nLines do 
      v1x[i]=self.v[i][1][1];
      v1y[i]=self.v[i][1][2];
      v2x[i]=self.v[i][2][1];
      v2y[i]=self.v[i][2][2];--x0 x1 y0 y1
      real_length[i]=math.sqrt((v2x[i]-v1x[i])^2 + (v2y[i]-v1y[i])^2);
     --parent_vision:add_debug_message(string.format("Real length of line "..i..": %.2f\n", real_length[i]));
      endpoint11[i]=self.endpoint[i][1];
      endpoint12[i]=self.endpoint[i][3];
      endpoint21[i]=self.endpoint[i][2];
      endpoint22[i]=self.endpoint[i][4];
      xMean[i]=self.meanpoint[i][1];
      yMean[i]=self.meanpoint[i][2];
    --  if max_length<self.propsB[i].length then
      if max_length<real_length[i] then
     --   max_length=self.propsB[i].length;
         max_length=real_length[i]
		    max_index=i;
      end
    end

    vcm['set_line'..cidx..'_v1x'](v1x);
    vcm['set_line'..cidx..'_v1y'](v1y);
    vcm['set_line'..cidx..'_v2x'](v2x);
    vcm['set_line'..cidx..'_v2y'](v2y);
    vcm['set_line'..cidx..'_real_length'](real_length);
    vcm['set_line'..cidx..'_endpoint11'](endpoint11);
    vcm['set_line'..cidx..'_endpoint12'](endpoint12);
    vcm['set_line'..cidx..'_endpoint21'](endpoint21);
    vcm['set_line'..cidx..'_endpoint22'](endpoint22);
    vcm['set_line'..cidx..'_xMean'](xMean);
    vcm['set_line'..cidx..'_yMean'](yMean);
    local max_lengthB = math.sqrt(
      (endpoint11[max_index]-endpoint21[max_index])^2+
      (endpoint12[max_index]-endpoint22[max_index])^2);
    local mean_v = {(v1x[max_index]+v2x[max_index])/2,(v1y[max_index]+v2y[max_index])/2,0,1};
    vcm['set_line'..cidx..'_v'](mean_v);
    vcm['set_line'..cidx..'_angle'](self.angle[max_index]);
    vcm['set_line'..cidx..'_nLines'](self.nLines);
    local max_real_length = real_length[max_index];
    vcm['set_line'..cidx..'_lengthB'](max_real_length);
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

return detectLine;
