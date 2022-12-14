function [Teq,MyMBr,n]=shaftcalc(filenameMyMBr,plotfig)
%GEARCALC - calculates gear lrd on main bearing and gearbox 
%
% SYNTAX:
%   [Teq,MyMBr,n]=gearcalc('r:\2MW\MK8\Investigations\175\tools\test\Loads\Postloads\RAIN\0053_MyMBr.rfo')
%
% DESCRIPTION:
%   Calculation method according to 0040-8682.V01
%
%   Gear calculation is done for following gear ratios and life exponents 
%   and reference cycles:   
%       p=[8.0 8.0]
%       Nref=[1e7 1e3]
%
% OUTPUT:
%   Teq.shaft        - the estimated equivalent fatigue torque for the 
%                     shaft [kNm].
%   Teq.param.p     - the life exponent for gears.
%   Teq.param.Nref  - the reference cycle number indicating the endurance 
%                     limit.
%	MyMBr			- Load level
%	n		- Number of cycles MyMBr
%
% 11/08-2015 BHSUB: initial version
%
% Reviewers:
%
% Load reader class
postloads=LAC.scripts.MasterModel.misc.postloads();
%% Parameter settings

% Parameters shaft
p=[8.0 8.0 5];
Nref=[1E7 1E3 1E3];

%% Read data MyMbr
fid=fopen(filenameMyMBr);
[path, file]=fileparts(filenameMyMBr);

% Check if file is valid
if fid==-1
    files=dir(path);
    disp({files(3:end).name}')   
    error([file ' not recognized, please choose valid gear ldd file.'])
    
end
if ~strcmpi(file(end-4:end),'MyMBr')
   warning('Sensor is not MyMBr and may not be representable for main bearing torque!!')
end

rfc=postloads.decode(fid);
fclose(fid);
MyMBr   = rfc.spectrum(:,1);
n       = rfc.spectrum(:,2);
accum   = abs(rfc.spectrum(:,3));
%% Calculate shaft loads
for i=1:length(p)
    Teq.shaft(i)=(sum((0.5*abs(MyMBr)).^p(i).*n)/Nref(i))^(1/p(i));    
end
%%
Teq.shaft;
Teq.param.p=p;
Teq.param.Nref=Nref;
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
