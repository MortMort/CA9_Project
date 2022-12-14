function x=invlognormalcdf(F,mu,sigma)
% Inverse Cumulative Log-Normal Distribution
% -------------------------------------------------------------------------
% Inverse Cumulative Log-Normal Distribution. Created by GUOVI @ Vestas
% -------------------------------------------------------------------------
% 
% z=invlognormalcdf(F)
% 
% input: 
% F = non-exceedence probability
% output:
% x

x = exp(erfinv(2*F-1)*sqrt(2)*sigma+mu);

end