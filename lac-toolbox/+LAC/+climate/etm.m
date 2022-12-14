function [I sig1]=etm(Iref,Vave,Vhub,c)
% Extreme Turbulence intensity according to ETM in IEC III 61400-1
% Syntax
% [I sig1]=etm()
% [I sig1]=etm(Iref,Vave,Vhub)
% [I sig1]=etm(Iref,Vave,Vhub,c)
%
% Input:
% Iref = Expected value of the turbulence intensity
% Vave = Average wind speed on site
% Vhub = Wind speed at hub height. 1xN array
% c = Adjustment factor. Default c=2
%
% Output:
% I = turb intensity
% sig = downstream free wind standard diviation
%
% Created by SORSO

%%
if nargin<4
    c=2;
end

if nargin==0        % example
    Vave=[10, 8.5, 7.5];
    Vhub=2:1:24;
    Iref=0.12:0.02:0.16;
    for j=1:length(Vave)
        for i=1:length(Iref)
            sig1=c*Iref(i).*(0.072*(Vave(j)./c+3).*(Vhub./c-4)+10);
            I(i,:)=sig1./Vhub;
        end
        figure(j)
        hold on
        hh=plot(Vhub,I);
        xlabel('mean wind speed [m/s]')
        ylabel('turbulence inetensity [-]')
        legend(hh,{'IECA', 'IECB', 'IECC'},'Location','NorthEast')
        title(['Mean wind speed: ',num2str(Vave(j)),'m/s'])
    end
else
sig1=c*Iref.*(0.072*(Vave./c+3).*(Vhub./c-4)+10);
I=sig1./Vhub;
end
