function rho=airdensity(Tc,RH,H)
% Air density based on temp, humidity and height
% Syntax:
% rho=airdensity()       % Tc=15deg, RH=0% H=0m
% rho=airdensity(Tc,RH,H)
%
% inputs:
% Tc = Temperature in celsius [c^\circ]
% RH = relative humidity [%]
% H = Height above sea level [m]
%
% Output:
% rho = air density [kg/m^3]
%
% Example:
% rho=airDensity(25,0.5,1500)
% rho = 0.9810 kg/m^3
%
% This Script is based on the formula in ref [1].
% [1] ref: http://wahiduddin.net/calc/density_altitude.htm
%
% History:
% V00: Created by SORSO @ Vestas d. 07-04-2011
%
% Review:
% V00:

if ~nargin
    Tc=15; RH=0; H=0;                                   %Default
end
Es = 6.1078*10.^(7.5*Tc./(237.3+Tc));                   % saturation pressure of water vapor [mb]
Pv=RH*Es *100;                                          % partial pressure of water vapor

Rd= 287.05;                                             % Gas constant for dry air, [J/(kg*degK)]
P0=101325;                                              % sea level standard pressure, Pa
T=273.15+Tc;                                            % Temperature in Kelvin [K^o]
T0=288.15;                                              % sea level standard temperature, deg K
H=H/1000;                                               % convert m to km
P=P0.*(1-6.5*H./T0).^(9.80665*28.9644/(8.31432*6.5));   % Estimated Preassure at height H
D=(P./(Rd*T)).*(1-0.378*Pv./P);                         % Air Density [kg/m^3]
rho=D;