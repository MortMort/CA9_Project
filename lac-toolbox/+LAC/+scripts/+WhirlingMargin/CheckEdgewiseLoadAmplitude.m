%% User Inputs:
loadsPath = ...
pwd;
%%
% addpath('W:\SOURCE\LACtoolbox\')
DLC11 = {'1104' '1106' '1108' '1110' '1112' '1114' '1116' '1118' '1120' '1122' '1124'};
DLC13 = {'13'};
sensor = 'My11r';

%% Read turbine
turbine  = LAC.vts.stapost(loadsPath);turbine.read;

%% Get amplitude of DLC 11 loads
maxFamily = turbine.getLoad(sensor,'maxFamily',DLC11);
meanVal      = turbine.getLoad(sensor,'mean',DLC11);
amplitudeDLC11 = maxFamily - meanVal;

%% Get 1P amplitude
stdev     = turbine.getLoad(sensor,'std',DLC11);
oneP      = sqrt(2).*stdev(1);

%% 1Hz eq NTM
fat8_NTM = turbine.getLoad(sensor,'eq1hz8',DLC11);

%% 1Hz eq ETM
fat8_ETM = turbine.getLoad(sensor,'eq1hz8',DLC13);

%% Max edgeload (Family), Normalized
normalizedEdgeload = amplitudeDLC11/oneP

%% Plot
figH = figure;
set(figH,'color','white'); set(figH, 'Position', [120 75 900 400]);
                
% bar(4:2:24,[normalizedEdgeload;fat8_NTM/fat8_NTM(1)]'); grid on; hold on;
bar(4:2:24,normalizedEdgeload); grid on; hold on;
xlabel('Wind Speed [m/s]'); ylabel('Max Edge (family) / 1P amplitude')
plot([0 25],[1.7 1.7],'-r','linewidth',2); 
legend('Max (family)','1.7 factor','location','northwest')
title(loadsPath)

LAC.savefig(figH,{'NormalizedEdgeLoads'},pwd,1)