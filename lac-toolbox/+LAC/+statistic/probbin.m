function Pbin=probbin(prams,mu,sig,openend,disttype)
% Probability of bin, supports normal, logn, 2-par weibull and discreate.                     
%
% Description:
% Calculate the probability of a bin according to the specified
% distribution. 
% 
% syntax:
%       Pbin = ProbBin(prams)
%       Pbin = ProbBin(prams,mu,sig,openend)
%       Pbin = ProbBin(prams,mu,sig,openend,disttype)
%
% input:
%       mu = mean value of data
%       sig = standard deviation of data
%       prams = x parameter. Center value for bin. Must be a 1-by-n vector
%       openend = open ended interval(default 0). if set to 1 bin edges are
%       set to +-inf
%       disttype =  'nom'(default), 'logn', 'wbl' or disc. 
%
%       Note for the Weibull distribution, the mu = Vave and sig=k according to IEC61400-1 3.63 eq 3
%       Note for the Discreate cumulative distribution the mu =x and sig= F(x) 
%       
%
% output:
%       Pbin = Probability of bin. open ended discretisation
%
%Version history:
% 00:  new script SORSO 30/08/2010
% 
% review:
% 00: 
if nargin==1
    mu=0;
    sig=1;
end
if nargin<4
    openend=0;
end
if nargin<5
    disttype = 'nom';
end

Pbin=zeros(1,length(prams));

x1=prams;
dx=diff(prams)/2;
x=[x1(1)-dx(1) x1+[dx dx(end)]];

if strcmpi(disttype,'logn') && x(1)<0 
    x(1)=0;         % lower value can not be smaler than 0 for a log normal dist.
end

if min(x)<0 && strcmpi(disttype,'logn')
    error('Bad discretisation for a log-normal distribution. "prams" can not be negative.')
end

if strcmpi(disttype,'logn')
    sig=sqrt(log(1+(sig/mu).^2));           % sig_y
    mu=log(mu)-0.5*sig.^2;                  % mu_y
    F=normalcdf(log(x),mu,sig);
elseif strcmpi(disttype,'nom')
    F=normalcdf(x,mu,sig);
    
elseif strcmpi(disttype,'wbl')
    k=sig;
    C=mu./gamma(1+1/k);
    F=weibullcdf(x,C,k);
elseif strcmpi(disttype,'disc')
    F=interp1(mu,sig,x);
else
    error('invalid disttype')
    return
end

for i=1:length(F)-1
    if i==1 && openend
        Pbin(i)=F(2);
    elseif i==length(F)-1   && openend
        Pbin(i)=1-F(end-1);
    else
        Pbin(i)=F(i+1)-F(i);
    end
end
end


function F=normalcdf(x,mu,sig)
% -------------------------------------------------------------------------
% Cumulative Normal Distribution. Created by SORSO @ Vestas
% -------------------------------------------------------------------------
%
% F=normalcdf(x,mu,sig)
%
% input:
% x = sample value
% mu = mean value
% sig = standard divaiation
% output:
% non-exceedence probability

z=(x-mu)./(sqrt(2)*sig);
F=0.5*(erfc(-z));
end

function [F, Vave]=weibullcdf(V0,C,k)
    F=1-exp(-(V0./C).^k);
    Vave=C*gamma(1+1/k);
end