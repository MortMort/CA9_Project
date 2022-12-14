function [Omega] = ts2rpm(TS, D)

% function [Omega] = ts2rpm(TS, D)
%
% Input
%   TS:         Tip speed [m/s]
%   D:          Rotor diameter [m]
%
% Output:
%   Omega:      Rotor speed [rps]

Omega = TS / (pi * D)*60;
