close all; clear all;

setupFile = 'SetupStability.txt';
loadcasefile = '';

vts = 1 ;
stabilitylevel = 2;

reducedLoadCase = 0;
%% Initialize
simdir = pwd;

% Read Setupfile
Setup = Stability.common.Setup;
Setup.setupFile = fullfile(simdir,setupFile);
Setup.toolName = 'none';
disp('read setup file')
[Setup, status, msgArray] = Stability.common.readsetupfile(Setup);

%% Loads and AEP calc
if vts
    prep=LAC.vts.convert(Setup.prepHAWCStab2Template, 'REFMODEL');
    prep.Files('BLD') = Setup.VTSinputBladeFile;
    if reducedLoadCase
        txt = LAC.codec.CodecTXT(loadcasefile);
        loadcases = txt.getData;
        prep.comments = sprintf('%s \n',loadcases{:});
    end

    [folder, prepfile, postfix] = fileparts(Setup.prepHAWCStab2Template);
    outputPrep = fullfile(simdir,[prepfile postfix]);
    prep.encode(outputPrep);

    if exist(fullfile(folder,'_MasterFileChanges.txt'))==2
        copyfile(fullfile(folder,'_MasterFileChanges.txt'),fullfile(simdir))
    end
    if exist(fullfile(folder,'_CtrlParamChanges.txt'))==2
        copyfile(fullfile(folder,'_CtrlParamChanges.txt'),fullfile(simdir))
    end

    % Run FAT1
    sysCommandLine = ['FAT1 -R 0111001000101 -l -loads -pc -p ' outputPrep];
    [status results] = system(sysCommandLine);
end

%% Run Level1 Stability
if stabilitylevel==1
    mkdir('Stability')
    copyfile(fullfile(simdir,setupFile),fullfile(simdir,'Stability'))

    % obj = Stability.HAWC2Sim.run('speedup' , setupfile, 'baseline');
    % obj = Stability.HS2Sim.run('speedup' , setupfile, 'baseline');   
    % obj = Stability.HS2Sim.run('campbell' , setupfile); 
    Stability.run('level1',fullfile(simdir,'Stability',setupFile),'calculations')

end


%% Run Level2 Stability
if stabilitylevel==2
    mkdir('Stability')
    copyfile(fullfile(simdir,setupFile),fullfile(simdir,'Stability'))

    Stability.run('level2',fullfile(simdir,'Stability',setupFile),'calculations')
end