Lua and Matlab Mex modules for accessing double
variables in shared memory.

To setup and use variables from a "motion" shared memory in Lua:
lua> require('shm')
lua> t = shm.new('motion')
lua> t.a = 3.14
lua> print(t.a)
3.14
lua> t.b = {1, -2, -3}
lua> table.foreach(t.b, print)
1 1
2 -2
3 -3

In Matlab, you can access these variables as well:
>> shm_handle = mexshm('new', 'motion')
Starting mexshm...
shm_handle =

     0

>> mexshm('get', shm_handle, 'a')

ans =

    3.1400

>> mexshm('get', shm_handle, 'b')

ans =

     1    -2    -3

>> mexshm('set', shm_handle, 'c', rand(1,5))


A double[5] array under field "c" will now be available
in Lua as a table:

lua> table.foreach(t.c, print)
1 0.81472368639318
2 0.90579193707562
3 0.12698681629351
4 0.91337585613902
5 0.63235924622541


Added a memcpy operation for Vision:

c=require 'darwinCam'
require 'shm'
os.execute("sleep 2")
img = c.get_image()
t = shm.new('test', 320000)
print(img)
t:set('big_img', img, 153600 )
t:get('big_img', img)
