function z=normalinvcdf(F)
% Inverse Cumulative Normal Distribution
% -------------------------------------------------------------------------
% Inverse Cumulative Normal Distribution. Created by SORSO @ Vestas
% -------------------------------------------------------------------------
% 
% z=normalinvcdf(F)
% 
% input: 
% F = non-exceedence probability
% output:
% z=(x-mu)/sig

z=-sqrt(2)*erfcinv(2*F);
end