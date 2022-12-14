function [Vgust VgustA VgustB] = eog(D,HH,V50,TI,Vhub)
% EOG gust velocity according to IEC III
% Syntax
% [Vgust VgustA VgustB] = eog(D,HH,V50,TI,Vhub)
% [Vgust VgustA VgustB] = eog(D,HH,V50)
%
% Input:
% D = rotor diameter
% HH = Hub height
% V50 = Reference 50 year reccurrent wind
% TI = reference turbulence intensity (90% quantile)
% Vhub = Hub wind speed vector or single value
%
% Output:
% Vgust  = Gust Velocity min(VgustA,VgustB)
% VgustA = Gust Velocity driven by 50 year wind
% VgustB = Gust Velocity driven by turbulence
% 
% Example:
% [Vgust VgustA VgustB]=eog(112,94,32.5,0.16)
%
% Created by MAARD 29/10/2012

if nargin<5
    Vhub=4:0.5:30;
end
if nargin<4
    TI=0.16;
end
if HH<=60
    scale=0.7*HH;
else
    scale=42;
end 
[I, sigma]=LAC.climate.ntm(TI,Vhub);
VgustA=1.35*(0.8*V50-Vhub);
VgustB=3.3*sigma/(1+0.1*D/scale);
Vgust=min(VgustA,VgustB);

if nargin<5
    figure
    plot(Vhub,[VgustA;VgustB]); grid on
    xlabel('V_{hub} [m/s]');ylabel('V_{gust} [m/s]')
    %axis([4 30 0 25]); 
    legend('V_{50} driven','Turbulence driven','location','best')
end