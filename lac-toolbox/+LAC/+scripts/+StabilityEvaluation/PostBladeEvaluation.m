close all; clear all;
setupFn        = 'SetupStability.txt';
leg.current    = '';

compareSetupfile = {''};
leg.compare      = {''};

stabilityLevel = 'level2'; %level1 = HS2 campbell + HS2 speedup; level2 = level1 + HAWC2 speedup

%%
simdir    = pwd;
currentSetupfile = fullfile(simdir,'Stability',setupFn);

% Read Setupfile
Setup = Stability.common.Setup;
Setup.setupFile = currentSetupfile;
Setup.toolName  = 'none';
disp('read setup file')
SetupInfo.current = Stability.common.readsetupfile(Setup);

%% Run Level1 Stability
% obj = Stability.HAWC2Sim.run('postspeedup' , setupfile, 'datahandling'); obj = Stability.HAWC2Sim.run('postspeedup' , setupfile, 'plots');
% obj = Stability.HS2Sim.run('postspeedup' , setupfile, 'datahandling');   obj = Stability.HS2Sim.run('postspeedup' , setupfile, 'plots');
% obj = Stability.HS2Sim.run('postcampbell' , setupfile, 'GUI');   

% obj = Stability.run(stabilityLevel , currentSetupfile, 'postprocess');
Stability.common.stabilityreport(currentSetupfile,stabilityLevel)
% return
%% Initialize comparison
iFig=1;
for iPaths = 1:length(compareSetupfile)
    % Read Compare Setupfile
    Setup.setupFile = compareSetupfile{iPaths};
    disp('read setup file')
    SetupInfo.compare{iPaths} = Stability.common.readsetupfile(Setup);
end

%% Plot HAWC2 Comparison
if strcmp(stabilityLevel,'level2')
    Turbine = Stability.HAWC2Sim.Turbine;
    HAWC2.V100 = Turbine.getturbine('T:\DesignForStability\Investigations\038_FleetEvaluation\001_V100\Iter01\HAWC2_speedup\Outputs\allTurbineData.mat');
    HAWC2.V110 = Turbine.getturbine('T:\DesignForStability\Investigations\038_FleetEvaluation\002_V110\Iter02\HAWC2_speedup\Outputs\allTurbineData.mat');

    HAWC2.V112 = Turbine.getturbine('T:\DesignForStability\Investigations\038_FleetEvaluation\004_V112\Iter02\HAWC2_speedup\Outputs\allTurbineData.mat');

    HAWC2.V126     = Turbine.getturbine('T:\DesignForStability\Investigations\038_FleetEvaluation\006_V126\Iter01\HAWC2_speedup\Outputs\allTurbineData.mat');
    HAWC2.V136_893 = Turbine.getturbine('H:\3MW\MK3\Investigations\152_V136_Hybrid_Blade\V1363450.082.Rev893\It01\Stability\HAWC2_speedup\Outputs\allTurbineData.mat');

    % Stability.HAWC2Sim.compareturbines([V100 V110 V112 V126 V136_893], {0,0,0,0,0},{'V100','V110','V112','V126','V136'})

    % HAWC2.baseline = Turbine.getturbine(fullfile(SetupInfo.baseline.workingPath,'HAWC2_speedup','Outputs','allTurbineData.mat'));
    HAWC2.current  = Turbine.getturbine(fullfile(simdir,'Stability','HAWC2_speedup','Outputs','allTurbineData.mat'));
    for iCompare = 1:length(SetupInfo.compare)
        HAWC2.compare{iCompare}  = Turbine.getturbine(fullfile(SetupInfo.compare{iCompare}.workingPath,'HAWC2_speedup','Outputs','allTurbineData.mat'));
    end

    blades   = [HAWC2.V110 HAWC2.compare{:} HAWC2.current];
    bladeIdx = num2cell(zeros(1,length(blades)));
    hFig = Stability.HAWC2Sim.compareturbines(blades,bladeIdx ,{'V110 Mk10B',leg.compare{:},leg.current});
    fignames{1} = 'HAWC2_Peak2PeakSpeedup';
    fignames{2} = 'HAWC2_Peak2PeakSummary';
    iFig=iFig+2;
end
%% Plot HAWCStab Comparison
Turbine = Stability.HS2Sim.Turbine;

HS2.current  = Turbine.getturbine(fullfile(simdir,'Stability','HAWCStab2_speedup','Outputs','allTurbineData.mat'));
for iCompare = 1:length(SetupInfo.compare)
    HS2.compare{iCompare}  = Turbine.getturbine(fullfile(SetupInfo.compare{iCompare}.workingPath,'HAWCStab2_speedup','Outputs','allTurbineData.mat'));
end

blades      = [HS2.compare{:} HS2.current];
bladeIdx    = num2cell(zeros(1,length(blades)));
hFig(iFig)     = Stability.HS2Sim.comparespeedup('Edge1bw',blades,bladeIdx ,{leg.compare{:},leg.current});
fignames{iFig} = 'HS2_Edge1bw';iFig=iFig+1;
hFig(iFig)     = Stability.HS2Sim.comparespeedup('Edge1fw',blades,bladeIdx ,{leg.compare{:},leg.current});
fignames{iFig} = 'HS2_Edge1fw';iFig=iFig+1;
hFig(iFig)     = Stability.HS2Sim.comparespeedup('Edge2bw',blades,bladeIdx ,{leg.compare{:},leg.current});
fignames{iFig} = 'HS2_Edge2bw';iFig=iFig+1;
hFig(iFig)     = Stability.HS2Sim.comparespeedup('Edge2fw',blades,bladeIdx ,{leg.compare{:},leg.current});
fignames{iFig} = 'HS2_Edge2fw';iFig=iFig+1;

%%
outputfolder = fullfile(simdir,'Stability','Outputs');
mkdir(outputfolder)
LAC.savefig(hFig,fignames,outputfolder,1)

%%
bldBaseline = LAC.vts.convert(SetupInfo.compare{1}.VTSinputBladeFile,'BLD');
bldCurrrent = LAC.vts.convert(SetupInfo.current.VTSinputBladeFile,'BLD');

hBld{1} = bldBaseline.compareProperties(bldCurrrent,'relative')
hBld{2} = bldBaseline.compareProperties(bldCurrrent)

%%
Stability.common.stabilityreport(currentSetupfile,'compare')