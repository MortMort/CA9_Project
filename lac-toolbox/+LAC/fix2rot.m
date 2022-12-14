function [rotatingA,rotatingB,rotatingC]=fix2rot(azimuthRadians,fixedColl,fixedCos,fixedSin)
% [localA,localB,localC]=fixed2local(azimuthRadians,fixedColl,fixedCos,fixedSin)
%
% Multi-Blade Coordinate Transformation 
%
% Inputs:
%   azimuthRadians  - Azimuth angle (radians)
%   fixedColl       - Collective, fixed system
%   fixedCos        - Cosine, fixed system
%   fixedSin        - Sine, fixed system
%
% Outputs:
%   localA       -   signal blade A
%   localB       -   signal blade B
%   localC       -   signal blade C
%
% V00: 3/12-14 Initial version by MAARD 

localCoord = zeros(3,length(azimuthRadians));
for i=1:length(azimuthRadians)
    T=matrix(azimuthRadians(i));    
    localCoord(:,i)=T*[fixedColl(i); fixedCos(i); fixedSin(i);];    
end
rotatingA=localCoord(1,:);
rotatingB=localCoord(2,:);
rotatingC=localCoord(3,:);
end

function T=matrix(azimuthRadians)

T=[ 1   cos(azimuthRadians)         sin(azimuthRadians);...
    1   cos(azimuthRadians+2*pi/3)  sin(azimuthRadians+2*pi/3);...
    1   cos(azimuthRadians+4*pi/3)  sin(azimuthRadians+4*pi/3)];
end