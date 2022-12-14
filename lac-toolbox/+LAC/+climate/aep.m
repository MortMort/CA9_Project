function [aep, aep_dens]=aep(P,WS,Vavg,k)
%   Calculate AEP using power, corresponding wind and weibull distribution
%
%   aep = AEP(P,WS,Vavg,k)
%
%   Input:  P:  Array of power      (bin edge values)
%           WS: Array of wind speed (bin edge values)
%           Vavg:  mean wind for weibull dist, A = Vavg/gamma(1+1/k)
%           k:  k-factor for weibull dist
%   Output: aep: Annual Energy Production
%
%   Reviewed according to IEC 61400 ed3 Sec 3.63


%%update ATAND
WSbin = WS(2) - WS(1);
C = Vavg/gamma(1+1/k);

pdf = k / C * (WS/C).^(k - 1) .* exp(-(WS/C).^(k));
PowerPdf = P .* pdf;
aep_dens = 0.5*(PowerPdf(2:end) + PowerPdf(1:end-1)) * WSbin * 365.25 * 24;

aep = sum(aep_dens);


