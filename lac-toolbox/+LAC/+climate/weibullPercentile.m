function [windSpeed] = weibullPercentile(meanWindSpeed,kFactor,percentile,invert)
% windSpeed = weibullPercentile(meanWindSpeed,kFactor,percentile) 
% calculates a percentile wind speed of a given weibull distribution.
%   NOTE:
%   It is possible to invert the calculation by setting invert = true. In 
%   That case the call should be:
%   percentile = weibullPercentile(meanWindSpeed,kFactor,windSpeed,true)
%
if nargin == 3
    invert = false;
end
lambda = LAC.climate.weibullshape(meanWindSpeed, kFactor);

if ~invert    
    zeroFunction = @(windSpeed)percentile - (1 - exp(-(windSpeed/lambda)^kFactor));
    windSpeed = fzero(zeroFunction,lambda);
else
    windSpeed = 1 - exp(-(percentile/lambda)^kFactor);
end