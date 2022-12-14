function RenameAndSetUp(prepfilename,theProfiles)
folder = pwd;
theFolders = dir(fullfile(folder));
% theProfiles = {'PrdMix', 'HRM4-7','GL3-7', 'HR2-7', 'HR2-7x'};
for w = 1:length(theFolders)
    FolderCandidate = [folder '\' theFolders(w).name]; 
    if isdir(FolderCandidate) && length(theFolders(w).name) == 6
        fileID = fopen([FolderCandidate, '\_ModifyLoadCaseDescriptions.txt']);
        ModifyFile = textscan(fileID,'%s');
        fclose(fileID);
        idxProf = strmatch('all:add=profdat',ModifyFile{1});
        if ~isempty(idxProf)
            ProfNum = str2double(ModifyFile{1}(idxProf+1));
        end
        fileID = fopen([FolderCandidate, '\_CtrlParamChanges.txt']);
        CtrlParamChangeFile = textscan(fileID,'%s');
        fclose(fileID);
        idxCCO = strmatch('Px_OTC_DegrProfile_IceDetected',CtrlParamChangeFile{1});
        if ~isempty(idxCCO)
            CCOEnabled = str2double(strrep(CtrlParamChangeFile{1}{idxCCO+1},'=',''));
        end
        % Copy File
        copyfile([FolderCandidate, '\Loads\', prepfilename], FolderCandidate)

        % Rename Folder
        if CCOEnabled
            Enable = '_CCOEn';
        else
            Enable = '_CCODis';
        end
        FolName = [theProfiles{ProfNum},Enable];
        if ~exist(FolName,'dir')
            movefile(FolderCandidate,FolName);
            BatFile = [theProfiles{1},'_CCODis\QuickStart_FAT1.bat'];
            if ~exist(BatFile, 'file')
                Bf = fopen(BatFile, 'w' );
                fprintf(Bf,'%s','start FAT1_V029.01.exe -u -p');
                fprintf(Bf,'%c',' ');
                fprintf(Bf,'%s',[folder,'\',FolName,'\', prepfilename]);
                fprintf(Bf,'%c',' ');
                fclose(Bf);
            else 
                Bf = fopen(BatFile, 'a' );
                fprintf(Bf,'%s',[folder,'\',FolName,'\', prepfilename]);
                fprintf(Bf,'%c',' ');
                fclose(Bf);
            end
        end
    end
end



