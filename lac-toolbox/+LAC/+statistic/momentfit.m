function par=momentfit(disttype,x)
% Moment based fitting
%**********************************************************
% Moment based fitting. Created by SORSO @ Vestas
%**********************************************************
%
% par=momentfit(disttype,x)
%
%Input:
% disttype='wbl3'; 3 parameters Weibull dristribution
% disttype='gbl'; Gumbel dristribution
% disttype='logn'; linear distribution
% x=[T1, T2, ..., Tk ] or x=[X1, X2, ..., Xmax ]; Input data sorted ascended
% output:
% par=[B A (k)]       A= std est.  B= mean est.


mux=mean(x);        % 1. moment of data samples
sigmax=std(x);      % 2. moment of data samples
if strcmp('gbl',disttype)==1 %Gumble Distribution
    A=sigmax*sqrt(6)/pi;
    ec=0.577216;            % Euler's constant approx.
    B=mux-A*ec;
    par=[B A];
elseif strcmp('wbl3',disttype)==1 %Weibull Distribution
    skewx=skewness(x);
    iniguess=2;
        
    if skewx>=0
        k=fzero(@(k)(skewwbl3(k)-skewx),iniguess);
        if isnan(k)==1
            zerofinder; % homemade zero finder. If all other things fails use this. Do not try this at home :)
        end
    else
        zerofinder;
    end
        
    sigmay=sqrt(2/k*gamma(2/k)-(1/k*gamma(1/k))^2);
    muy=1/k*gamma(1/k);
    A=sigmax/sigmay;
    B=mux-A*muy;
    par=[B A k];
elseif strcmp('logn',disttype)==1 % lognormal distribution
    A=sqrt(log(sigmax.^2/mux.^2+1));
    B=log(mux)-A.^2/2;
    par=[B A];
else
    disp('undefined distribution type')
    return
end
