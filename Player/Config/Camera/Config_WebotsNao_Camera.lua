module(..., package.seeall);
-- Camera Parameters

camera = {};
camera.ncamera = 2;
camera.switchFreq = 1; 
--camera.width = 320; --We use custom model (higher resolution)
--camera.height = 240;
--camera.width = {320, 320};
--camera.height = {240, 240};
camera.width = {320, 320};
camera.height = {240, 240};

camera.x_center = camera.width[1]/2;
camera.y_center = camera.height[1]/2;

camera.auto_param = {};
camera.auto_param[1] = {key='auto_exposure',      val={0, 0}};
camera.auto_param[2] = {key='auto_white_balance', val={0, 0}};
camera.auto_param[3] = {key='autogain',           val={0, 0}};

camera.param = {};
camera.param[1] = {key='exposure',      val={150, 150}};
camera.param[2] = {key='gain',          val={61, 61}};
camera.param[3] = {key='brightness',    val={100, 100}};
camera.param[4] = {key='contrast',      val={75, 75}};
camera.param[5] = {key='saturation',    val={200, 200}};
camera.param[6] = {key='red_balance',   val={100, 100}};
camera.param[7] = {key='blue_balance',  val={120, 120}};
camera.param[8] = {key='hue',           val={0, 0}};

--NaoV4 values
camera.focal_length = 545.6; -- in pixels
camera.focal_base = 640; -- image width used in focal length calculation



camera.lut_file = {'lutWebots_btm.raw', 'lutWebots_btm.raw'};


camera.tStep = 30
