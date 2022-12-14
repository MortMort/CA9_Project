function [fixedColl,fixedCos,fixedSin]=rot2fix(azimuthRadians,rotatingA,rotatingB,rotatingC)
% [fixedColl,fixedCos,fixedSin]=local2fixed(azimuthRadians,localA,localB,localC)
%
% Multi-Blade Coordinate Transformation 
%
% Inputs:
%   azimuthRadians  - Azimuth angle (radians)
%   rotatingA          - signal blade A (blade I)
%   rotatingB          - signal blade B (blade III)
%   rotatingC          - signal blade C (blade II)
%
% Outputs:
%   fixedColl       - Collective, fixed system
%   fixedCos        - Cosine, fixed system
%   fixedSin        - Sine, fixed system
%
% V00: 3/12-14 Initial version by MAARD
 

fixedCoord = zeros(3,length(azimuthRadians));
for i=1:length(azimuthRadians)
    T=matrix(azimuthRadians(i));    
    fixedCoord(:,i)=T\[rotatingA(i); rotatingB(i); rotatingC(i);];    
end
fixedColl = fixedCoord(1,:);
fixedCos  = fixedCoord(2,:);
fixedSin  = fixedCoord(3,:);
end

function T=matrix(azimuthRadians)

T=[ 1   cos(azimuthRadians)         sin(azimuthRadians);...
    1   cos(azimuthRadians+2*pi/3)  sin(azimuthRadians+2*pi/3);...
    1   cos(azimuthRadians+4*pi/3)  sin(azimuthRadians+4*pi/3)];
end