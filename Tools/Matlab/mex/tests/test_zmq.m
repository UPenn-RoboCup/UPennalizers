% (c) 2013 Stephen McGill
% MATLAB script to test zeromq-matlab
clear all;
p1 = zmq( 'publish',   'matlab' );
p2 = zmq( 'publish',   5555 );
s1 = zmq( 'subscribe', 'matlab' );
s2 = zmq( 'subscribe', 'localhost', 5555 );
data1 = uint8('hello world!')';
data2 = [81;64;2000];
nbytes1 = zmq( 'send', p1, data1 );
nbytes2 = zmq( 'send', p2, data2 );
fprintf('Sent %d and %d bytes for ipc and tcp channels.\n',nbytes1,nbytes2);
[data,idx] = zmq('poll',1000);
for c=1:numel(data)
	if idx(c)==s1
		fprintf('ipc channel received: ');
		recv1 = data{c};
		disp( char(recv1') );
	elseif idx(c)==s2
		fprintf('tcp channel received: ');
		recv2 = typecast(data{c},'double');
		disp( recv2' )
	else
	end
end
if(sum(recv2==data2)==numel(data2))
	disp('TCP test passed!')
else
	disp('Bad tcp data!')
end
if(sum(recv1==data1)==numel(data1))
	disp('IPC test passed!')
else
	disp('Bad ipc data!')
end