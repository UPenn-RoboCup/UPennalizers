module(..., package.seeall);
-- Camera Parameters

camera = {};
camera.ncamera = 1;
camera.switchFreq = 0; --unused for OP
camera.width = 320; 
camera.height = 240;
camera.width = 160; 
camera.height = 120;

camera.x_center = camera.width/2;
camera.y_center = camera.height/2;

camera.auto_param = {};
camera.auto_param[1] = {key='auto_exposure',      val={0}};
camera.auto_param[2] = {key='auto_white_balance', val={0}};
camera.auto_param[3] = {key='autogain',           val={0}};

camera.param = {};
camera.param[1] = {key='exposure',      val={150}};
camera.param[2] = {key='gain',          val={61}};
camera.param[3] = {key='brightness',    val={100}};
camera.param[4] = {key='contrast',      val={75}};
camera.param[5] = {key='saturation',    val={200}};
camera.param[6] = {key='red_balance',   val={100}};
camera.param[7] = {key='blue_balance',  val={120}};
camera.param[8] = {key='hue',           val={0}};


camera.focal_length = 120; -- in pixels
camera.focal_base = 125.6; -- 1.0472 * 120 image width used in focal length calculatio
camera.lut_file = 'lutWebots.raw';
camera.lut_file_obs = 'lut_webots_ob.raw';

