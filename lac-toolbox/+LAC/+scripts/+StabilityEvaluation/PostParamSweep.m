close all; clear all;
currentpath = pwd;
orgBldPath     = 'h:\2MW\MK10C\V110\Investigations\44_SingleWeb_StabilityAssessment\PARTS\BLD\Blade_V110_a18_l08_s17_2_WithPA.001 ';
orgBld = LAC.vts.convert(orgBldPath,'BLD');
structFields = fields(orgBld.SectionTable);

%% Run Level1 Stability
for iProp = 1:length(structFields)
    if ~ismember(iProp,[4,7,8,14])
       continue 
    end   
    newDir = fullfile(currentpath,structFields{iProp});
    Stability.run('level1',fullfile(newDir,'SetupAll_v002.txt'),'postprocess')
end


%% Plot HAWCStab Comparison
Turbine = Stability.HS2Sim.Turbine;
HS2(1)   = Turbine.getturbine(fullfile('h:\2MW\MK10C\V110\Investigations\44_SingleWeb_StabilityAssessment\Iter00_Stability_of_Reference_Blade\Stability\','HAWCStab2_speedup','Outputs','allTurbineData.mat'));
leg{1}   = 'baseline';
bld{1}   = 0;

HS2(2)   = Turbine.getturbine(fullfile('h:\2MW\MK10C\V110\Investigations\44_SingleWeb_StabilityAssessment\Iter07_FullStability_Blade006\Stability\','HAWCStab2_speedup','Outputs','allTurbineData.mat'));
leg{2}   = 'Iteration 6';
bld{2}   = 0;

idx = 3;
for iProp = 1:length(structFields)
    if ismember(iProp,[1,9:13,15:17])
       continue 
    end    
    newDir = fullfile(currentpath,structFields{iProp});
    HS2(idx)   = Turbine.getturbine(fullfile(newDir,'HAWCStab2_speedup','Outputs','allTurbineData.mat'));
    leg{idx}   = structFields{iProp};
    
    bld{idx} = 0
    idx = 1+idx;
end

%% Plot HAWCStab Comparison

hFig(1)     = Stability.HS2Sim.comparespeedup('Edge1bw',HS2, bld,leg);
fignames{1} = 'HS2_Edge1bw';
hFig(2)     = Stability.HS2Sim.comparespeedup('Edge1fw',HS2, bld,leg);
fignames{2} = 'HS2_Edge1fw';
hFig(3)     = Stability.HS2Sim.comparespeedup('Edge2bw',HS2, bld,leg);
fignames{3} = 'HS2_Edge2bw';
hFig(4)     = Stability.HS2Sim.comparespeedup('Edge2fw',HS2, bld,leg);
fignames{4} = 'HS2_Edge2fw';

%%
outputfolder = fullfile(currentpath,'Outputs');
mkdir(outputfolder)
LAC.savefig(hFig,fignames,outputfolder,1)