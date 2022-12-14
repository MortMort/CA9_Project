clear all;

%% User Inputs
windSpeed  = '';%<insertWindSpeed>;
designLoad = '';%<insertDesignLoad>;
Load1P     = '';%<insert1PLoad>;

selFolders = 1:3;
%% Preconditions
% addpath('W:\SOURCE\LACtoolbox\')
basePath   = pwd;
PLF               = 1.35;
LC                = sprintf('11%s', num2str(windSpeed));
SenstivityCaseExt = sprintf('Extreme Loads, %s m/s',num2str(windSpeed));
SenstivityCaseFat = sprintf('Fatigue Loads, %s m/s',num2str(windSpeed));

%%
simPath = fullfile(basePath,'01_ReferenceNTM');

[folders, values]=LAC.fat1.fat1info(simPath);
i=1;
hFig1 = figure;
for iFolder=folders
    iPath=fullfile(simPath,iFolder);
    sta.(['sim' iFolder{1}])=LAC.vts.stapost(iPath{1});
    sta.(['sim' iFolder{1}]).read() 
    
    stdMy11(i) = sta.(['sim' iFolder{1}]).getLoad('My11r','std',{LC});
    eq1Hz8My11(i) = sta.(['sim' iFolder{1}]).getLoad('My11r','eq1hz8',{LC});
    
    iLCs=sta.(['sim' iFolder{1}]).findLC(LC);
    iSensor = sta.(['sim' iFolder{1}]).findSensor('My11r');
    staValsMax = abs(sta.(['sim' iFolder{1}]).stadat.max(iSensor,iLCs)-sta.(['sim' iFolder{1}]).stadat.mean(iSensor,iLCs));
    maxMy11(i) = mean(staValsMax);
    stdValsMax(i) = 2*std(staValsMax) + maxMy11(i);    
    staVals1Hz = sta.(['sim' iFolder{1}]).stadat.eq1hz(iSensor,iLCs,5);
    
    omega   = sta.(['sim' iFolder{1}]).stadat.mean(sta.(['sim' iFolder{1}]).findSensor('OmGen'),iLCs);
%     h1=plot(ones(length(staValsMax),1)*values(i,1),staValsMax/Load1P,'b*');hold on;
    
    i=i+1;
end
h1=plot(values(:,1),maxMy11/Load1P*PLF,'b','linewidth',2); grid on; hold on;

hFig2 = figure;
hAx1=plot(values(:,1),eq1Hz8My11/Load1P,'b','linewidth',2); grid on; hold on
%%
simPath = fullfile(basePath,'02_ReferenceETM');

[folders, values, parameters]=LAC.fat1.fat1info(simPath);
i=1;
figure(hFig1)
for iFolder=folders
    iPath=fullfile(simPath,iFolder);
    sta.(['sim' iFolder{1}])=LAC.vts.stapost(iPath{1});
    sta.(['sim' iFolder{1}]).read() 
    
    stdMy11(i) = sta.(['sim' iFolder{1}]).getLoad('My11r','std',{LC});
    eq1Hz8My11(i) = sta.(['sim' iFolder{1}]).getLoad('My11r','eq1hz8',{LC});
    
    iLCs=sta.(['sim' iFolder{1}]).findLC(LC);
    iSensor = sta.(['sim' iFolder{1}]).findSensor('My11r');
    staValsMax = abs(sta.(['sim' iFolder{1}]).stadat.max(iSensor,iLCs)-sta.(['sim' iFolder{1}]).stadat.mean(iSensor,iLCs));
    maxMy11(i) = mean(staValsMax);
    stdValsMax(i) = 2*std(staValsMax) + maxMy11(i);    
    staVals1Hz = sta.(['sim' iFolder{1}]).stadat.eq1hz(iSensor,iLCs,5);
    
    omega   = sta.(['sim' iFolder{1}]).stadat.mean(sta.(['sim' iFolder{1}]).findSensor('OmGen'),iLCs);
    
    i=i+1;
end
h2=plot(values(:,1),maxMy11/Load1P*PLF,'m','linewidth',2); grid on;
%%
simPath =fullfile(basePath,'03_WorstCaseTI05');
[folders, values, parameters]=LAC.fat1.fat1info(simPath);
i=1;
figure(hFig1)
for iFolder=folders(selFolders)
    iPath=fullfile(simPath,iFolder);
    sta.(['sim' iFolder{1}])=LAC.vts.stapost(iPath{1});
    sta.(['sim' iFolder{1}]).read() 
    
    stdMy11(i) = sta.(['sim' iFolder{1}]).getLoad('My11r','std',{LC});
    eq1Hz8My11(i) = sta.(['sim' iFolder{1}]).getLoad('My11r','eq1hz8',{LC});
    
    iLCs=sta.(['sim' iFolder{1}]).findLC(LC);
    iSensor = sta.(['sim' iFolder{1}]).findSensor('My11r');
    staValsMax = abs(sta.(['sim' iFolder{1}]).stadat.max(iSensor,iLCs)-sta.(['sim' iFolder{1}]).stadat.mean(iSensor,iLCs));
    maxMy11(i) = mean(staValsMax);
    stdValsMax(i) = 2*std(staValsMax) + maxMy11(i);    
    staVals1Hz = sta.(['sim' iFolder{1}]).stadat.eq1hz(iSensor,iLCs,5);
    
    omega   = sta.(['sim' iFolder{1}]).stadat.mean(sta.(['sim' iFolder{1}]).findSensor('OmGen'),iLCs);
   
    i=i+1;
end
h3=plot(values(selFolders,1),maxMy11/Load1P*PLF,'g','linewidth',2); grid on;

figure(hFig2);
hAx2=plot(values(selFolders,1),eq1Hz8My11/Load1P,'g','linewidth',2); grid on; hold on
xlabel('Edgewise stiffness ratio to nominal'); ylabel('My11r Fatigue load, 1Hz m=8 [kNm]')
legend([hAx1 hAx2],'Design conditions (NTM)','Worst conditions (TI 0.05)')
title(SenstivityCaseFat)
ylim([0.8 3]);xlim([0.85 1.15]);
%%
simPath =  fullfile(basePath,'04_WorstCaseETM');
[folders, values, parameters]=LAC.fat1.fat1info(simPath);
i=1;
figure(hFig1)
for iFolder=folders(selFolders)
    iPath=fullfile(simPath,iFolder);
    sta.(['sim' iFolder{1}])=LAC.vts.stapost(iPath{1});
    sta.(['sim' iFolder{1}]).read() 
    
    stdMy11(i) = sta.(['sim' iFolder{1}]).getLoad('My11r','std',{LC});
    eq1Hz8My11(i) = sta.(['sim' iFolder{1}]).getLoad('My11r','eq1hz8',{LC});
    
    iLCs=sta.(['sim' iFolder{1}]).findLC(LC);
    iSensor = sta.(['sim' iFolder{1}]).findSensor('My11r');
    staValsMax = abs(sta.(['sim' iFolder{1}]).stadat.max(iSensor,iLCs)-sta.(['sim' iFolder{1}]).stadat.mean(iSensor,iLCs));
    maxMy11(i) = mean(staValsMax);
    stdValsMax(i) = 2*std(staValsMax) + maxMy11(i);    
    staVals1Hz = sta.(['sim' iFolder{1}]).stadat.eq1hz(iSensor,iLCs,5);
    
    omega   = sta.(['sim' iFolder{1}]).stadat.mean(sta.(['sim' iFolder{1}]).findSensor('OmGen'),iLCs);
    
    i=i+1;
end
h4=plot(values(selFolders,1),maxMy11/Load1P*PLF,'c','linewidth',2); grid on;
h5=plot([0 3],[designLoad designLoad]/Load1P,'r','linewidth',2);
xlabel('Edgewise stiffness ratio to nominal'); ylabel('My11r, ratio to 1P load')
legend([h1 h2 h3 h4 h5],'Design conditions (NTM)','Design conditions (ETM)','Worst conditions (TI 0.05)','Worst conditions (ETM)','Design Load')
ylim([0.95 2.9]);xlim([0.85 1.15]);
title(SenstivityCaseExt)


%% Save Figs
LAC.savefig([hFig1,hFig2],{sprintf('WS%02.0f_Extreme_Sensitivity',windSpeed),sprintf('WS%02.0f_Fatigue_Sensitivity',windSpeed)},basePath,1)
