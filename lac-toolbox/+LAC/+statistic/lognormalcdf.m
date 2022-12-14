function F=lognormalcdf(x,mu_y,sig_y)
% Cumulative Logormal Distribution
% -------------------------------------------------------------------------
% Cumulative Logormal Distribution. Created by RSTEV @ Vestas
% -------------------------------------------------------------------------
%
% F=lognormalcdf(x,mu_y,sig_y)
%
% input:
% x = sample value
% mu_y = mean value for lognormal distribution
% sig_y = standard divaiation for lognormal distribution
% output:
% non-exceedence probability
NoVal = isnan(x) | isnan(mu_y) | isnan(sig_y);

F(NoVal)=nan;

z(~NoVal)=(log(x(~NoVal))-mu_y(~NoVal))./(sqrt(2)*sig_y(~NoVal));
F(~NoVal)=0.5*(erfc(-z(~NoVal)));
end