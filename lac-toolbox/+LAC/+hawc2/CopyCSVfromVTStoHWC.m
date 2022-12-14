function CopyCSVfromVTStoHWC(rootfol,simulationpath,VTS)
%% Copy CSV from VTS to HAWC2 simulations
fn=fieldnames(VTS);
    for i=1:length(fn)
        copyfile(fullfile(rootfol,'_VTS\Loads\INPUTS\',VTS.(fn{i})), fullfile(simulationpath, 'INPUTS'),'f');
    end
end