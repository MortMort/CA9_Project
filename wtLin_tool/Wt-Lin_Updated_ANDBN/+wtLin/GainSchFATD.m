function [KposGS,KvelGS] = GainSchFATD(fatd,WindSpd,TowFrqHz1)
% Computes wind dependent gain sch for FATD (Kpos gain sch)
% Computes freq dependent gain for FATD (Kvel gain sch)

% Version history – Responsible JSTHO
% V0 - 16-08-2017 - JSTHO


%% Wind speed gain sch

% delta to ensure interp1 working when x-vals equal
dd = 0.0000001; % m/s

X = [...
    fatd.GainSchWind.Wind1 + 0*dd;...
    fatd.GainSchWind.Wind2 + 1*dd;...
    fatd.GainSchWind.Wind3 + 2*dd;...
    fatd.GainSchWind.Wind4 + 3*dd];
Y = [...
    fatd.GainSchWind.Gain1;...
    fatd.GainSchWind.Gain2;...
    fatd.GainSchWind.Gain3;...
    fatd.GainSchWind.Gain4];

u = min(max(WindSpd,X(1)),X(end));
KposGS = interp1(X,Y,u);


%% Tower freq gain sch

% delta to ensure interp1 working when x-vals equal
dd = 0.0000001; % Hz

X = [...
    fatd.GainSchFreq.SwitchOffVelFb + 0*dd;...
    fatd.GainSchFreq.SwitchOnVelFb + 1*dd];

Y = [...
    fatd.GainSchFreq.MinVelFbGain;...
    1];

u = min(max(TowFrqHz1,X(1)),X(end));
KvelGS = interp1(X,Y,u);











