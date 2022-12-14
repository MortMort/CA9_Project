function F=wbl3cdf(x,mu,sig,k)
% Weibull distribution (CDF)
%**********************************************************
% Weibull distribution (CDF). Created by SORSO @ Vestas
%**********************************************************
% 
% F=gblcdf(x,mu,sig,k)
% 
%input:
% x = data sample
% mu = corresponding mean value in normal dist. 
% sig = corresponding std. value in normal dist.
% k = Weibull exponent
% output:
% F = non-exceedence probability

F=1-exp(-((x-mu)/sig).^k);

end