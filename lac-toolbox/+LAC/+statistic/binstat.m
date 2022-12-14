function [yBinMean, yBinStd, yBinN, xBinC]= binstat(xdat,ydat,xBinEdge)
%find mean and std.dev for data in bin
% SYNTAX: 
% [yBinMean, yBinStd, yBinN, xBinC]= bin_stat(xdat,ydat,xBinEdge)
%
% INPUT:
% xdat = data used to identify "data in bin"
% ydat = data on which the bin value will be calculated
% xBinEdge = binning vector. Edge values
%
% OUTPUT:
% yBinMean = mean of the y data in the bin
% yBinStd = std.dev of the y data in the bin
% yBinN = Number of data points in bin.
% xBinC = center values of the bin vector
%
%
% Example:
% ydat = randn(100,1);
% xdat = rand(100,1);
% xBinEdge = 0:0.1:1;
% alpha = 0.025; % 2 sided 95% confidence interval
% [yBinMean, yBinStd, yBinN, xBinC]= bin_stat(xdat,ydat,xBinEdge);
% CI = confidenceInterval(alpha, yBinN,yBinStd);
% figure
% plot(xdat,ydat,'.')
% hold on
% errorbar(xBinC,yBinMean,CI)
%
% Version control
% 00: new script by SORSO 06-02-2016
% 01: Confidence interval added by SORSO 09-02-2017
% 02: Confidence interval moved to seperate function 14-02-2017
% 
% Review history
% 00:
% 01:
% 02:
%
% See Also confidenceInterval

n = length(xBinEdge);
yBinMean = zeros(1,n-1);
yBinStd = zeros(1,n-1);
yBinN = zeros(1,n-1);
for i = 1 : n-1
    idx = xBinEdge(i)<= xdat & xdat <xBinEdge(i+1); % identify data in bin
    yBinMean(i) = mean(ydat(idx));
    yBinStd(i) = std(ydat(idx));
    yBinN(i) = sum(idx);
end

d = xBinEdge(2) - xBinEdge(1); % bin size
xBinC = xBinEdge(1:n-1) + d/2;  % xbin center values