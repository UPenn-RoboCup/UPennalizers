disp('Running mex tests!');
addpath( genpath('.') );
test_zmq;
test_msgpack;
exit