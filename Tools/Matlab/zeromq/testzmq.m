clear all;
s1 = zmq('publish','matlab')
zmq('send',s1,'hello world!')
s2 = zmq('publish','debug')
zmq('send',s2,'hey-o')
s3 = zmq('subscribe','test')
s4 = zmq('subscribe','test2')
%r = zmq('receive',s3)
data = [];
while numel(data)<1
  [data,idx] = zmq('poll',100);
end
char( data{1}' )
