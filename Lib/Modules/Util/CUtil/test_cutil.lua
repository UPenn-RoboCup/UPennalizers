local cutil = require('cutil')
--[[
t = cutil.test_array();
s = cutil.array2string(t, 10, 1, 'int32','myname');
for k,v in pairs(s) do print(k,v) end
cutil.string2userdata(t, s.data);
s2 = cutil.array2string(t, 10, 1, 'int32','myname2');
for k,v in pairs(s2) do print(k,v) end
--]]

l = cutil.test_label(10,0)
cutil.print_label(l,10)
s= cutil.label2array_rle(l,10)

k=s[5]
s[5]=s[6]
s[6]=k

l2 = cutil.test_label(10,0)
cutil.array2label_rle(l2,#s,s)

