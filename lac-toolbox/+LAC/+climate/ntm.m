function [I, sig1]=ntm(Iref,Vhub,quantile,edType,IrefType)
% Turbulence intensity according to NTM in IEC ed3 and ed4-
% Syntax
% [I sig1]=ntm(Iref,Vhub)
% [I sig1]=ntm(Iref,Vhub,fractile)
% [I, sig1]=ntm(Iref,Vhub,quantile,edType)
% [I, sig1]=ntm(Iref,Vhub,quantile,edType,IrefType)
%
% Input:
% Iref = referance turbulence intensity.
% Vhub = wind speed at hub height.
% fractile default 90%
% edType = 'ed3'/'ed4' IEC edition type (default='ed3')
% IrefType = 'mean' / 'Iref' Edition 4 option only.
%                'mean': Iref variable = mean value
%                'Iref': Iref = IEC ed4 definition.
%                (default = 'Iref')
%
% Output:
% I = turb intensity
% sig = downstream free wind standard diviation
%
% revision history:
% 00: New script by SORSO
% 01: ed4 definition added. by SORSO 09-06-2017
% 02: Minor modification, if input is ntm(Iref,Vhub) by ASKNE 26-09-2017
%
% Review:
% 00:
% 01:
% 02: By SORSO 26-09-2017.

% set defaults options

if nargin<4
    edType = 'ed3';
elseif nargin<5
    IrefType = 'Iref';
end

if strcmpi(edType,'ed3')
    
    if nargin==2 % 90% fractile
        sig1 = Iref * (0.75 * Vhub + 5.6);
        I = sig1 ./ Vhub;
    else
        MUsig1=Iref*(0.75*Vhub+3.8);                % mu_x
        VARsig1=(Iref*1.4).^2;                      % sig_x.^2
        sig=sqrt(log(1+(sqrt(VARsig1)./MUsig1).^2)); % sig_y
        mu=log(MUsig1)-0.5*sig.^2;                  % mu_y
        
        z=normalinvcdf(quantile);
        
        sig1=exp(z*sig+mu);
        I=sig1./Vhub;
    end
    
elseif strcmpi(edType,'ed4')
    
    if strcmpi(IrefType, 'mean')
        Iref = Iref / 0.9;
    end
    
    A = Iref.*(0.75*Vhub+3.3);                     % scale factor
    k = 0.27*Vhub+1.4;                            % shape factor
    sig1 = weibullinvcdf(A,k,quantile);
    I = sig1./Vhub;
    
else
    error('%s is an unknown edition type',edType)
end
end

function z=normalinvcdf(F)
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

function z=weibullinvcdf(A,k,F)
% ---------------------------------------------------------------------------
% Inverse Cumulative 2-parameter Weibull Distribution. Created by LT @ Vestas
% ---------------------------------------------------------------------------
%
% z=weibullinvcdf(A,k,F)
%
% input:
% F = non-exceedence probability
% output:
% z = inverse value

z = A.*(-log(1-F)).^(1./k);
end
