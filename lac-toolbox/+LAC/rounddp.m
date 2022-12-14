%ROUNDDP round number on one of the decimal places 
%
%   The number is round to the specified decimal using matlab's round function
%
%   Syntax:  [out] = rounddp(in,dp)
%
%   Input:   in         the number to round off
%            dp         the desired decimal place
%
%   Outputs: out        the rounded number
%
%   Example:
%            [out]=rounddp(2.1234,3)
%   See also round
%
%   PBC, 03/01
%

function [out] = rounddp(in,dp)

fac=eval(['1e' num2str(dp)]);
out=round(in*fac)/fac;
