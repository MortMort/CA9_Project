function F=normalcdf(x,mu,sig)
% Cumulative Normal Distribution
% -------------------------------------------------------------------------
% Cumulative Normal Distribution. Created by SORSO @ Vestas
% -------------------------------------------------------------------------
% 
% F=normalcdf(x,mu,sig)
% 
% input:
% x = sample value
% mu = mean value
% sig = standard divaiation
% output:
% non-exceedence probability

z=(x-mu)./(sqrt(2)*sig);
F=0.5*(erfc(-z));
end