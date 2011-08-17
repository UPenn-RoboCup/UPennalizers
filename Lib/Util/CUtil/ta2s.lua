require('cutil')
t = cutil.test_array();
s = cutil.array2string(t, 10, 1, 'int32');
for k,v in pairs(s) do print(k,v) end
cutil.string2userdata(t, s.data);
s2 = cutil.array2string(t, 10, 1, 'int32');
for k,v in pairs(s2) do print(k,v) end

