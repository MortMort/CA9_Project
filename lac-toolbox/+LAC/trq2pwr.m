function [P] = trq2pwr(T,Omega)

% function [P] = t2p(T,Omega)
%
% Input
%   T:          Torque 
%   Omega:      Rotor speed [rps]
%
% Output:
%   P:          Power

P=T.*(Omega*2*pi);



