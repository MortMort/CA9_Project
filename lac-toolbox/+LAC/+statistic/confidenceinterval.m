function CI = confidenceinterval(alpha,Ndata,DataStdDev)
% calculate the confidence interval on the mean value estimate.
%  SYNTAX: CI = confidenceInterval(alpha,Ndata,DataMean,DataStdDev)
% 
% INPUT:
% alpha = alpha value in confidence interval. E.g. two-sided 95% confidence: alpha = 0.025
% Ndata = number of data point in each bin. 1-by-n array
% DataStdDeV = standard deviation of data in each bin. 1-by-n array
%
% OUTPUT:
% CI = confidence interval. where
% Two-sided interval = CI - mean <= mean <= CI + mean
% lower one-sided interval = CI - mean <= mean <= inf
% upper one-sided interval = -inf <= mean <= CI + mean
%
% EXAMPLE:
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
%
% Version history
% 00: New script by SORSO 14-02-2017
%
% Review:
% 00:
%
% See Also bin_stat

t_alpha = student_t(Ndata,alpha);
CI = t_alpha.*DataStdDev./sqrt(Ndata);  %     from Ayyub and McCuen p.381 eq. 11.5
end

function t_alpha = student_t(n,alpha)
%     from Ayyub and McCuen p.146
for i =1:length(n)
    k = n(i)-1;  % degree of fredom
    if k>200
       k=200; % numerical integral not possible for k>200, but k=inf is the same as k=200.
    end
    if k>0
        f_T = @(t)(gamma((k + 1) ./ 2)) ./ (sqrt(pi * k) * gamma(k / 2) * (1 + (t.^2/k)).^( (k + 1)/2));
        fun2 = @(t_alpha)integral(f_T,t_alpha,inf)-alpha;
        t_alpha(i) = fzero(fun2,2);
    else
        t_alpha(i) = NaN;
    end
end
end