function [Teq,MyMBr,n]=gearcalc(filename,plotfig)
%GEARCALC - calculates gear lrd on main bearing and gearbox 
%
% SYNTAX:
%   [Teq,MyMBr,n]=gearcalc('H:\3MW\MK2A\V1053300.072\iec1a.005\PostLoads\LDD\0053_MyMBr_rev.ldd')
%
% DESCRIPTION:
%   Calculation method according to 0040-8682.V00
%
%   Gear calculation is done for following gear ratios and life exponents 
%   and reference cycles:   
%       p=[8.7 6.6 8.7 6.6 8.7 6.6 8.0]
%       u=[2.5 15 20 20 120 120 20]
%       Nref=[3000000 50000000 3000000 50000000 3000000 50000000 1000]
%
%   Gear bearing calculation is done for following life exponent:
%       m=[3.3300 8]
%
% OUTPUT:
%   Teq.gear        - the estimated equivalent fatigue torque for the 
%                     checked gear [kNm].
%   Teq.bear        - the estimated equivalent fatigue torque for gearbox 
%                     bearings [kNm].
%   Teq.param.u     - the gear ratio between main shaft and checked gear
%   Teq.param.p     - the life exponent for gears.
%   Teq.param.Nref  - the reference cycle number indicating the endurance 
%                     limit.
%   Teq.param.m     - the life exponent for rolling element bearings.
%	MyMBr			- Load level
%	n 				- Number of cycles
%
% 20/11-2013 MAARD: initial version
% 03/03-2014 MAARD: reader function changed, improved error handling.
% 25/06-2014 MAARD: Help header updated
% 07/08-2014 FACAP: Output list updated
%
% Reviewers:
%   MJR
%   THBK
%
%% Parameter settings

% Parameters bearing
m=[3.33 8];

% Parameters gear
p=[8.7 6.6 8.7 6.6 8.7 6.6 8.0];
Nref=[3e6 5e7 3e6 5e7 3e6 5e7 1e3];
u=[2.5 15 20 20 120 120 20];

%% Read data
[path, file]=fileparts(filename);

% Check if file is valid
if ~strcmpi(file(end-8:end),'MyMBr_rev')
   warning('Sensor is not MyMBr_rev and may not be representable for main bearing torque!!')
end

ldd     = LAC.intpostd.convert(filename);
MyMBr   = ldd.spectrum(:,1);
n       = ldd.spectrum(:,2);
accum   = abs(ldd.spectrum(:,3));

%% Calculate gear loads
for i=1:length(p)
    % Find cycles up to Nref
    n_i=n(accum<Nref(i));    
    MyMBr_i=MyMBr(accum<Nref(i));
    
    % Add cycles from next bin to mathc Nref
    if ~(length(MyMBr_i)==length(MyMBr))     
        n_i(end+1)=Nref(i)-sum(n_i);
        MyMBr_i(end+1)=MyMBr(length(MyMBr_i)+1);
    else
        error('%s contains %i accumulated cycle. %i are required.',file,accum(end),Nref(i))
    end

    Teq.gear(i)=(sum(abs(MyMBr_i).^p(i).*n_i*u(i))/Nref(i))^(1/p(i));    

end

%% Calculate bearing loads
Nref_bear=sum(n);
% Nref_bear=6.3072e8;
for i=1:length(m)
    Teq.bear(i)=(sum(abs(MyMBr).^m(i).*n)/Nref_bear)^(1/m(i));
end


%%
Teq.gear;
Teq.bear;
Teq.param.u=u;
Teq.param.p=p;
Teq.param.Nref=Nref;
Teq.param.m=m;


%% Figure
if nargin>1 && plotfig==1
    [~, name]=fileparts(filename);
    figure
    plot(MyMBr,n);
    xlabel('Load');ylabel('n'); grid on;
    title(strrep(name,'_',' '))
    
    figure
    plot(MyMBr,accum); hold on;
    plot([min(MyMBr) max(MyMBr)],[3e6 3e6],'r')
    plot([min(MyMBr) max(MyMBr)],[5e7 5e7],'r')
    xlim([min(MyMBr) max(MyMBr)])
    xlabel('Load');ylabel('n accum'); grid on;
    title(strrep(name,'_',' '))
end
