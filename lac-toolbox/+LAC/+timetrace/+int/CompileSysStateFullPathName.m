function [SysStateFiles,VmpSubDir,ReleaseDir]=CompileSysStateFullPathName(GenInfo,UserSettings)

switch GenInfo.Processor
    case {'CT5000.01','CT5000.02','CT6000'}
        VmpSubDir='vmp8';
    case 'CT3500'
        VmpSubDir='vmp3';
    case 'CT4400'
        VmpSubDir='vmp1';
end

if GenInfo.Release<10
    ReleaseDir=(['v00' int2str(GenInfo.Release)]);
elseif GenInfo.Release<100
    ReleaseDir=(['v0' int2str(GenInfo.Release)]);
else
    ReleaseDir=(['v' int2str(GenInfo.Release)]);
end

% find the file with SysState descriptions based on primary VMP directory
if strmatch(GenInfo.Processor,'CT4400','exact')   % according to mail from MHOJ on Jan 25, 2002
    SysStateFiles.VMPHomeDir=([UserSettings.VMPHomeDir '\' VmpSubDir '\' ReleaseDir '\state.txt']);
    SysStateFiles.AltVMPHomeDir=([UserSettings.AltVMPHomeDir '\' VmpSubDir '\' ReleaseDir '\state.txt']);
else
    SysStateFiles.VMPHomeDir=([UserSettings.VMPHomeDir '\' VmpSubDir '\' ReleaseDir '\topstate.txt']);
    SysStateFiles.AltVMPHomeDir=([UserSettings.AltVMPHomeDir '\' VmpSubDir '\' ReleaseDir '\topstate.txt']);
end

