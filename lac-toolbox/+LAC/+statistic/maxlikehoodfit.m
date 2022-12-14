function par = maxlikehoodfit(disttype,x)
% Maximum Likelihood Fitting
%**********************************************************
% Maximum Likelihood Fitting. Created by SORSO @ Vestas
%**********************************************************
%
% par = maxlikehoodfit(disttype,x)
%
%Input:
% disttype='wbl3'; 3 parameters Weibull dristribution
% disttype='gbl'; Gumbel dristribution
% disttype='logn'; linear distribution
% x=[T1, T2, ..., Tk ] or x=[X1, X2, ..., Xmax ]; Input data sorted ascended
% output:
% par=[B A (k)]     A= std est.  B= mean est.

if strcmp('gbl',disttype)==1 %Gumble Distribution
    N=length(x);
    iniguess=min(x);
    A=fzero(@(A)(x*exp(-x./A)'-(1/N*sum(x-A))*sum(exp(-x./A))),iniguess);
    
    if A<=0.01*min(x) || isnan(A)==1;
        for i=1:5
            if A<=0.01*min(x);
                A=i*0.1*min(x);
                A=fzero(@(A)(x*exp(-x./A)'-(1/N*sum(x-A))*sum(exp(-x./A))),A);
            end
        end
        if A<=0 || isnan(A)==1;
            warning(['A is smaller than zero or NaN!!! A=',num2str(A)]);
            A=min(x);
        end
    end
    
    B=A*log(N*(sum(exp(-x./A)))^(-1));
    par = [B A ];
elseif strcmp('wbl3',disttype)==1 %Weibull Distribution
    threshold=linspace(min(x)*0.7,min(x)-1e-1,100);
    for i=1:length(threshold)
        par(i,:) = wbl3fit(x,threshold(i));
        wbl3fg(i) = wbl3goodfit(x,par(i,:));
    end
    [val pos]=min(wbl3fg);
    par=par(pos,:);
elseif strcmp('logn',disttype)==1 % lognormal distribution
    N=length(x);
    B=sum(log(x))/N;
    A=sqrt(sum((log(x)-B).^2)/N);
    par=[B A];
end
end

%% Weibull fitting functions
function par = wbl3fit(x,threshold) % maximum likehood fitting
N=length(x);
iniguess=2.0;
th=threshold;
k=fzero(@(k)((N+k*sum(log(x-th)))-(N*k*((x-th).^k*log(x-th)')*(sum((x-th).^k))^(-1))),iniguess);
if k<0
    iniguess=10.0;
    k=fzero(@(k)((N+k*sum(log(x-th)))-(N*k*((x-th).^k*log(x-th)')*(sum((x-th).^k))^(-1))),iniguess);
    if k<0
        warning('k is smaller than zero in max likelihood fit. Must be larger!!')
    end
end
A=(1/N*sum((x-th).^k))^(1/k);
par = [ threshold A k];
end

function wbl3fg = wbl3goodfit(x,par) % Goodness of fit
N=length(x);
F=(linspace(1,N,N)-0.3)/(N+0.4);        % median rank (Benard's approximation)
A=par(2);
B=par(1);
k=par(3);
for i=1:N
    fitval(i)=A*(-log(1-F(i)))^(1/k)+B;
end
wbl3fg=1/N*sum(abs(fitval-x)./x);
end