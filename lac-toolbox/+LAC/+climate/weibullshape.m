function lambda = weibullscale(mean, k)
% WEIBULLSCALE Funtion to calculate distribution scale factor based on mean wind and shape factor k.
lambda = mean/gamma(1+1/k);