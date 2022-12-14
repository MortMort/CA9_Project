function f=normalpdf(x,mu,sig)
% Probability density function of a Normal Distribution
% -------------------------------------------------------------------------
% probability density function of a Normal Distribution. Created by SORSO @ Vestas
% -------------------------------------------------------------------------
% 
% F=normalpdf(x,mu,sig)
% 
% input:
% x = sample value
% mu = mean value
% sig = standard divaiation
% output:
% probability density function

if nargin==1
    sig=1;
    mu=0;
end
f=1/sqrt(2*pi*sig.^2)*exp(-(x-mu).^2/(2*sig.^2));
end