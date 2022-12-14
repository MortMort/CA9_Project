function Xest=invgblcdf(F,mu,sig)
% Inverse Gumbel distribution
%**********************************************************
% Inverse Gumbel distribution . Created by SORSO @ Vestas
%**********************************************************
% 
% Xest=invgblcdf(F,mu,sig)
% 
%input:
% F = non-exceedence probability
% mu = corresponding mean value in normal dist. 
% sig = corresponding std. value in normal dist.
% output:
% x = estimated value (eg. extreme load)
Zest=-log(-(log(F)));
Xest=sig*Zest+mu;
end