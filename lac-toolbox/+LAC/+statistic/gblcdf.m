function F=gblcdf(x,mu,sig)
% Gumbel distribution (CDF)
%**********************************************************
% Gumbel distribution (CDF). Created by SORSO @ Vestas
%**********************************************************
% 
% F=gblcdf(x,mu,sig)
% 
%input:
% x = data sample
% mu = corresponding mean value in normal dist. 
% sig = corresponding std. value in normal dist.
% output:
% F = non-exceedence probability

F=exp(-exp(-(x-mu)/sig));

end