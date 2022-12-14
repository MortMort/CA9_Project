function CreatePcComList(folder,pcName)
theFolders = dir(fullfile(folder));
for w = 1:length(theFolders)
    FolderCandidate = [folder,theFolders(w).name,'\PC\Normal\Rho1.325\'];
    Folder2Exclude{1} = [folder,'.','\PC\Normal\Rho1.325\'];
    Folder2Exclude{2} = [folder,'..','\PC\Normal\Rho1.325\'];
    Folder2Exclude{3} = [folder,'_LOG','\PC\Normal\Rho1.325\'];
    Folder2Exclude{4} = [folder,'Rel2020_20','\PC\Normal\Rho1.325\'];
    IncludeFolder = sum([isempty(strmatch(Folder2Exclude{1},FolderCandidate));
                        isempty(strmatch(Folder2Exclude{2},FolderCandidate));
                        isempty(strmatch(Folder2Exclude{3},FolderCandidate))
                        isempty(strmatch(Folder2Exclude{4},FolderCandidate))]);
    if isdir(FolderCandidate) && IncludeFolder == 4
        PcComFile = [folder,'PcComList.txt'];
        if ~exist(PcComFile, 'file')
            Pc = fopen(PcComFile, 'w' );
            fprintf(Pc,'%s\n',[FolderCandidate,pcName]);
            fclose(Pc);
        else 
            Pc = fopen(PcComFile, 'a' );
            fprintf(Pc,'%s\n',[FolderCandidate,pcName]);
            fclose(Pc);
        end
    end
end