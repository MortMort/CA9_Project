function [VTS]=VTSCtrlfiles(rootfol)
%% This function identifes the controller files and required parameters
% Inputs
% - rootfolder
Allfiles_dir = dir([rootfol '_VTS\Loads\INPUTS\*.csv']);

    for i=1:length(Allfiles_dir)
        VTS.(char(extractBefore(Allfiles_dir(i).name,'_')))=Allfiles_dir(i).name;
    end
end

