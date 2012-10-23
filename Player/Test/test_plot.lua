require('init')
require('gnuplot')
require('matrix')
require('vector')

local N = 50

local x = vector.ones(N)
for i = 0,N-1 do
  x[i+1] =  math.cos(2*math.pi/(N-1)*i)
end

--local xx = matrix:new(N, N)
--for i = 0,N-1 do
--  for j = 0,N-1 do
--    xx[i+1][j+1] =  math.cos(2*math.pi/(N-1)*i)*math.cos(2*math.pi/(N-1)*j)
--  end
--end

gnuplot.figure()
gnuplot.bar(x)

gnuplot.figure()
gnuplot.plot(x, '~')

--gnuplot.figure()
--gnuplot.imagesc(xx, 'gray')
--
--gnuplot.figure()
--gnuplot.splot(xx, '-')
--
--gnuplot.figure()
--gnuplot.plot3d(xx, 'color')
