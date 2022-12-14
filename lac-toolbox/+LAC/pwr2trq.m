function [T] = pwr2trq(P,Omega)

% function [T] = pwr2trq(P,Omega)
%
% Input
%   P:          Power 
%   Omega:      Rotor speed [rps]
%
% Output:
%   T:          Torque

T=P./(Omega*2*pi);



