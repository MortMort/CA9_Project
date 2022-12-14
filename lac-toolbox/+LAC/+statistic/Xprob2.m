function Ptot = Xprob2(nwsp,Pwsp,par,x,nj,disttype)
% Aggregated Exceedence Probability
%**********************************************************
% Aggregated Exceedence Probability. Modified by SORSO @ Vestas
%**********************************************************
% 
% Ptot = Xprob2(nwsp,Pwsp,par,x,nj,disttype)
% 
%input:
% x = ordinate (x-axis)
% nwsp = number of windspeed bins.
% Pwsp = probability of a wind speed bin
% par = fitting parameters.
% nj = number of extremes extracted from time serie
% disttype = distribution type. valid types: wbl3, gbl ,logn
% output:
% Ptot = exceedence probability of x

Ptot0 = 0;

for i = 1:nwsp
    
    if strcmp('wbl3',disttype)==1
        if x < par(i,1)
            Px(i,1) = 1;
        else
            Px(i,1) = 1-LAC.statistic.wbl3cdf(x,par(i,1),par(i,2),par(i,3)).^nj;
        end
    elseif strcmp('gbl',disttype)==1
        if x < 0
            Px(i,1) = 1;
        else
            Px(i,1) = 1-(LAC.statistic.gblcdf(x,par(i,1),par(i,2))).^nj;
        end
    elseif strcmp('logn',disttype)==1
        if x < 0
            Px(i,1) = 1;
        else
            Px(i,1) = 1-(LAC.statistic.normalcdf(log(x),par(i,1),par(i,2))).^nj;
        end
    end
end
Ptot = Ptot0+Px'*Pwsp;
end

