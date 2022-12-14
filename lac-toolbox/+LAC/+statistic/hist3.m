function [nn,x1,x2] = hist3(x,n,m,x1lim,x2lim)
%HIST3  simple 3-D Histogram.
%   x must be a 2 by * matrix.
%   n must be a scalar which specifys the number of bins 
%     for the first culumn of X. (optional)
%   m must be a scalar which specifys the number of bins 
%     for the second culumn of X. (optional)
%   x1lim = [x1min x1max]
%   x2lim = [x2min x2max]
%
%   NN = HIST(X) bins the elements of X into 10 equally spaced containers
%   and returns the number of elements in each container. 
%
%   NN = HIST(X,N), where N is a scalar, uses N bins for both columns.
%
%   NN = HIST(X,N,M), where N and M are scalars, uses N bins for the
%   first column and M for the second.
%
%   [NN,X1,X2] = HIST(...) also returns the position of the bin centers in X.
%
% modified by SORSO 11-05-2010
%%
if nargin == 0
    error('Requires one or two or three input arguments.')
end
if nargin == 1
    n = 10;
    m = 10;
end
if nargin == 2
    m = n;
end
if isstr(x) | isstr(n) | isstr(m)
    error('Input arguments must be numeric.')
end
%
if nargin < 4
    minx1 = min(x(1,:));
    maxx1 = max(x(1,:));
else
    minx1 = x1lim(1);
    maxx1 = x1lim(2);
end

bw1 = (maxx1 - minx1) ./ n;
x1 = minx1 + bw1*(1:n);
x1(length(x1)) = maxx1;
%
if nargin < 5
    minx2 = min(x(2,:));
    maxx2 = max(x(2,:));
else
    minx2 = x2lim(1);
    maxx2 = x2lim(2);
end
bw2 = (maxx2 - minx2) ./ m;
x2 = minx2 + bw2*(1:m);
x2(length(x2)) = maxx2;
%
nn=zeros(length(x1),length(x2));
for k=1:size(x,2)
  [y,i]=min(abs(ceil(x(1,k)-x1)));
  [z,j]=min(abs(ceil(x(2,k)-x2)));
  nn(i,j)=nn(i,j)+1;
end
if nargout == 0
  bar3(x1-bw1/2,nn,'hist');
end
x1=x1-bw1/2;
x2=x2-bw2/2;