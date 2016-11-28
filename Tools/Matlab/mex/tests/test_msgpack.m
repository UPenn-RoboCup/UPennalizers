clear all;
data = [1,432,43.4];
msg = msgpack('pack', data);
unpack = msgpack('unpack', msg);
if numel(data)==numel(unpack)
	for i=1:numel(data)
		if data(i)~=unpack(i)
			disp('Msgpack: Bad match!')
			return
		end
	end
	disp('Msgpack test passed!')
else
	disp('Msgpack: Bad number of data!')
end