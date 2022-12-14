function [Teq,amplitudeModified,n]=structElementsCalcUser(filename,p,Nref, meanBoolean)
%structElementsCalc - calculates proxy torque equivalent using Markov matrix for various structural elements based on sec 4.5 in  Design Guideline
% Enveloping of Design Duty Cycle for Powertrain System, DMS: 0040 8682 V01

% SYNTAX:
%   [Teq,ranges,n]=structElementsCalc('r:\2MW\MK8\Investigations\175\tools\test\Loads\Postloads\MARKOV\0053_MyMBr.mko')
%
% DESCRIPTION:
%   Calculation method according to 0040-8682.V01
%
%   Proxy torque equivalent for structural elements calculation is done for following gear ratios and life exponents
%   and reference cycles:
%       p=[5.0 5.0]
%       Nref=[1e6 1e3]
%
% OUTPUT:
%   Teq.fat       - the estimated equivalent fatigue torque [kNm]
%   Teq.param.p   - the life exponent for structural elements.
%   Teq.param.Nref  - the reference cycle number indicating the endurance limit.
%	amplitudeModified - Load level modified.
%	n		       - Number of cycles of given sensor.
%
% 13/08-2015 BHSUB: initial version
% 21/11-2015 BHSUB: updated for user defined input for p, nref, mean level
% modification
% Reviewers:
%
% Load reader class
postloads=LAC.scripts.MasterModel.misc.postloads();
%% Parameter settings

% Parameters gear
% user defined (from input)
% p=[5.0 5.0];
% Nref=[1E6 1E3];

%% Read data MyMbr
fid=fopen(filename);
[path, file]=fileparts(filename);

% Check if file is valid
if fid==-1
    files=dir(path);
    disp({files(3:end).name}')
    error([file ' not recognized, please choose valid gear ldd file.'])
end
switch file(end-4:end)
    case 'MyMBr'
        
    case 'MxMBr'
        
    case 'MzMBr'
        
    case 'MxMBf'
        
    case 'MzMBf'
        
    case '_MrMB'
        
    otherwise
        disp('Sensor is not MyMBr,MxMBr, MzMBr, MxMBf, MzMBf, MrMB  and may not be representable for main bearing torque!!')
end
M = 0.3; % mean stress sensitivity.
mko = postloads.decode(fid);
fclose(fid);
level    = mko.spectrum(:,1);
ranges   = mko.spectrum(:,2);
n        = mko.spectrum(:,3);
accum    = abs(mko.spectrum(:,4));
amplitude = ranges*0.5;
amplitudeModified = amplitude;

% transform the levels based on various conditions
% modify the mean levels based on user input
if meanBoolean
    for i = 1:length(level)
        % calculate ratio lm/la
        ratio = level(i)/amplitude(i);
        
        % check the conditions
        if ratio <= -1
            amplitudeModified(i)     = LaTransform1(amplitude(i),level(i),M);
            
        elseif (-1<=ratio && ratio <=1)
            amplitudeModified(i)     = LaTransform2(amplitude(i),level(i),M);
            
        elseif (1<=ratio && ratio<=3)
            amplitudeModified(i)     = LaTransform3(amplitude(i),level(i),M);
            
        elseif (3<=ratio)
            amplitudeModified(i)     = LaTransform4(amplitude(i),level(i),M);
        end
    end
end
%% Calculate gear loads
for i=1:length(p)
    Teq.fat(i)=(sum((abs(amplitudeModified)).^p(i).*n)/Nref(i))^(1/p(i));
end
%%
Teq.fat;
Teq.param.p=p;
Teq.param.Nref=Nref;

    function [LaTransformed] = LaTransform1(La,Lm,M)
        LaTransformed = La*(1-M);
    end

    function [LaTransformed] = LaTransform2(La,Lm,M)
        LaTransformed  = La*(1+(M*(Lm/La)));
    end

    function [LaTransformed] = LaTransform3(La,Lm,M)
        fac1 = (1+M)/(1+(M/3));
        fac2 = 1+((M/3)*(Lm/La));
        LaTransformed  = La*fac1*fac2;
    end

    function [LaTransformed] = LaTransform4(La,Lm,M)
        fac1 = (1+M)^2;
        fac2 = 1+(M/3);
        LaTransformed = La*(fac1/fac2);
    end
end

