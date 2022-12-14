function [xx,fx,normfit,mu,sigma] = epdf(x,P)
%% Computes empiric probability density function for a given data set

if nargin<2
    P=1000;
end

xx=linspace(min(x),max(x),P);
binspacing=(max(x)-min(x))/P;

fx=histc(x,xx)/(binspacing*length(x));

if (nargout>2)||(nargout==0)
    mu=mean(x);
    sigma=sqrt(var(x));
    normfit=1/(sigma*sqrt(2*pi))*exp(-(xx-mu).^2./(2*sigma^2));
end

if nargout==0
    %figure();
    plot(xx,fx,xx,normfit);
    legend('Data','Normal fit');
    xlabel('x');ylabel('f_X(x)');
end