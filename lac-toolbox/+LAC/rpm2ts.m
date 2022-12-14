function [TS] = rpm2ts(Omega, D)

% function [TS] = rpm2ts(Omega, D)
%
% Input
%   Omega:      Rotor speed [rps]
%   D:          Rotor diameter [m]
%
% Output:
%   TS:         Tip speed [m/s]

TS = Omega.*pi.*D/60;
