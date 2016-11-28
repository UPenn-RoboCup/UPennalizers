function c = gen_costs(n,m,sparsity)

if nargin < 1,
  n = 100;
end
if nargin < 2,
  m = n;
end
if nargin < 3,
  sparsity = 0.1;
end

c0 = rand(m,n);
c0(c0 > sparsity) = 0;
c0 = c0./sparsity;
c1 = exp(5*c0);

nconv = 5;
kconv1 = exp(-2*abs([1:nconv]./nconv-.5));
kconv = kconv1'*kconv1;
kconv = kconv./sum(kconv(:));

c = conv2(c1, kconv, 'same');