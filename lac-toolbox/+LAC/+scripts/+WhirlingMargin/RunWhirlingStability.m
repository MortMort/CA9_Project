close all; clear all;

prepTemplate = '';%<preptemplate>;

%% Initialize
simdir = pwd;
prep=LAC.vts.convert(prepTemplate, 'REFMODEL');
[folder, prepfile, postfix] = fileparts(prepTemplate);

%% Preparing simulations

% Setup 01_ReferenceNTM 
lcObj         = LAC.codec.CodecTXT('LC_01_ReferenceNTM.txt');
loadcases     = lcObj.getData;
prep.comments = sprintf('%s \n',loadcases{:});
outputPrep1 = fullfile(simdir,'01_ReferenceNTM',[prepfile postfix]);
prep.encode(outputPrep1);
if exist(fullfile(folder,'_MasterFileChanges.txt'))==2
    copyfile(fullfile(folder,'_MasterFileChanges.txt'),fullfile(simdir,'01_ReferenceNTM'))
end
if exist(fullfile(folder,'_CtrlParamChanges.txt'))==2
    copyfile(fullfile(folder,'_CtrlParamChanges.txt'),fullfile(simdir,'01_ReferenceNTM'))
end
copyfile('_ParameterStudyNominal.txt',fullfile(simdir,'01_ReferenceNTM','_ParameterStudy.txt'))
mkdir(fullfile(simdir,'01_ReferenceNTM','MainHooks'))
copyfile('DeleteFiles_PostHook.bat',fullfile(simdir,'01_ReferenceNTM','MainHooks'))

% Setup 02_ReferenceETM 
lcObj         = LAC.codec.CodecTXT('LC_02_ReferenceETM.txt');
loadcases     = lcObj.getData;
prep.comments = sprintf('%s \n',loadcases{:});
outputPrep2 = fullfile(simdir,'02_ReferenceETM',[prepfile postfix]);
prep.encode(outputPrep2);
if exist(fullfile(folder,'_MasterFileChanges.txt'))==2
    copyfile(fullfile(folder,'_MasterFileChanges.txt'),fullfile(simdir,'02_ReferenceETM'))
end
if exist(fullfile(folder,'_CtrlParamChanges.txt'))==2
    copyfile(fullfile(folder,'_CtrlParamChanges.txt'),fullfile(simdir,'02_ReferenceETM'))
end
copyfile('_ParameterStudyNominal.txt',fullfile(simdir,'02_ReferenceETM','_ParameterStudy.txt'))
mkdir(fullfile(simdir,'02_ReferenceETM','MainHooks'))
copyfile('DeleteFiles_PostHook.bat',fullfile(simdir,'02_ReferenceETM','MainHooks'))

% Setup 03_WorstCaseTI05 
lcObj         = LAC.codec.CodecTXT('LC_03_WorstCaseTI05.txt');
loadcases     = lcObj.getData;
prep.comments = sprintf('%s \n',loadcases{:});
outputPrep3 = fullfile(simdir,'03_WorstCaseTI05',[prepfile postfix]);
prep.encode(outputPrep3);
if exist(fullfile(folder,'_MasterFileChanges.txt'))==2
    copyfile(fullfile(folder,'_MasterFileChanges.txt'),fullfile(simdir,'03_WorstCaseTI05'))
end
if exist(fullfile(folder,'_CtrlParamChanges.txt'))==2
    copyfile(fullfile(folder,'_CtrlParamChanges.txt'),fullfile(simdir,'03_WorstCaseTI05'))
end
copyfile('_ParameterStudyWorstCase.txt',fullfile(simdir,'03_WorstCaseTI05','_ParameterStudy.txt'))
mkdir(fullfile(simdir,'03_WorstCaseTI05','MainHooks'))
copyfile('DeleteFiles_PostHook.bat',fullfile(simdir,'03_WorstCaseTI05','MainHooks'))

% Setup 04_WorstCaseETM 
lcObj         = LAC.codec.CodecTXT('LC_04_WorstCaseETM.txt');
loadcases     = lcObj.getData;
prep.comments = sprintf('%s \n',loadcases{:});
outputPrep4 = fullfile(simdir,'04_WorstCaseETM',[prepfile postfix]);
prep.encode(outputPrep4);
if exist(fullfile(folder,'_MasterFileChanges.txt'))==2
    copyfile(fullfile(folder,'_MasterFileChanges.txt'),fullfile(simdir,'04_WorstCaseETM'))
end
if exist(fullfile(folder,'_CtrlParamChanges.txt'))==2
    copyfile(fullfile(folder,'_CtrlParamChanges.txt'),fullfile(simdir,'04_WorstCaseETM'))
end
copyfile('_ParameterStudyWorstCase.txt',fullfile(simdir,'04_WorstCaseETM','_ParameterStudy.txt'))
mkdir(fullfile(simdir,'04_WorstCaseETM','MainHooks'))
copyfile('DeleteFiles_PostHook.bat',fullfile(simdir,'04_WorstCaseETM','MainHooks'))
%% Run FAT1
sysCommandLine = ['FAT1 -r 0101000000001 -par ' outputPrep1 '&'];
[status results] = system(sysCommandLine);

sysCommandLine = ['FAT1 -r 0101000000001 -par ' outputPrep2 '&'];
[status results] = system(sysCommandLine);

sysCommandLine = ['FAT1 -r 0101000000001 -par ' outputPrep3 '&'];
[status results] = system(sysCommandLine);

sysCommandLine = ['FAT1 -r 0101000000001 -par ' outputPrep4 '&'];
[status results] = system(sysCommandLine);
