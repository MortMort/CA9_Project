function Xest=invwbl3cdf(F,mu,sig,k)
% Inverse 3-par. Weibull distribution
%**********************************************************
% Inverse 3-par. Weibull distribution. Created by SORSO @ Vestas
%**********************************************************
% 
% Xest=invgblcdf(F,mu,sig,k)
% 
%input:
% F = non-exceedence probability
% mu = corresponding mean value in normal dist. 
% sig = corresponding std. value in normal dist.
% k = Weibull exponent
% output:
% x = estimated value (eg. extreme load)
Zest=(-log(1-F)).^(1/k);
Xest=Zest*sig+mu;
end