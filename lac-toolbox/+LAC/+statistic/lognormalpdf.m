function [f mu2 sig2]=lognormalpdf(x,mu,sig,opt)
% -------------------------------------------------------------------------
% probability density function of a log Normal Distribution. Created by SORSO @ Vestas
% -------------------------------------------------------------------------
%
% f=lognormalpdf(x,mu,sig)
% f=lognormalpdf(x,mu,sig,opt)
% [f mu2 sig2]=lognormalpdf(x,mu,sig,opt)
%
% input:
% x = sample value
% muy = mean value
% sigy = standard deviation
% opt = 'ymoment' (default) / 'xmoment'
% output:
% probability density function
% mu2 = transformed moment. mux --> muy / muy --> mux
% sig2 = transformed moment. sigx --> sigy / sigy --> sigx
%%
if nargin==1
    sig=1;
    mu=0;
end
if nargin== 4 % calc ymoment
    if strcmp(opt,'xmoment')
        sig=sqrt(log(1+(sig/mu).^2));
        mu=log(mu)-0.5*sig.^2;
        sig2=sig;
        mu2=mu;
    end
end

f(x>0)=1./(x(x>0).*sqrt(2*pi*sig.^2)).*exp(-(log(x(x>0))-mu).^2/(2*sig.^2));
f(x<=0)=0;

if nargin== 4
    if strcmp(opt,'ymoment')   % calc xmoment
        mu2=exp(mu+0.5*sig.^2);
        sig2=sqrt(mu2.^2*(exp(sig.^2)-1));
    end
else % calc xmoment
    mu2=exp(mu+0.5*sig.^2);
    sig2=sqrt(mu2.^2*(exp(sig.^2)-1));
end
end