function StandstillStability()


    path2program = fullfile(fileparts(which(['LAC.scripts.' mfilename])),['+' mfilename]);
    
    destination  = uigetdir(pwd,'Select destination folder');
    if destination == 0
        return
    end
        
    filenames = {'setupAndRunStandstillStability.m', 'defineTurbineConfigurations.m'};
    
    for iFile= 1:length(filenames)
        file2copy    = fullfile(path2program,filenames{iFile});
        copyfile(file2copy,destination)
        open(fullfile(destination,filenames{iFile}))
    end

    md5Hash = LAC.scripts.StandstillStability.misc.calcDirectoryMD5;
    fid = fopen(fullfile(destination,'toolboxHash'),'w');
    fprintf(fid,'%s',md5Hash);
    fclose(fid);
    
    
    %Try to find the hash of the current commit 
    commitInfoFile = (([fileparts(which('LAC.scripts.StandstillStability')) '\..\..\.git\logs\HEAD']));
    fid = fopen(commitInfoFile,'r'); 
    %Find last line
    while 1
        line = fgetl(fid);
        if ~ischar(line)
            break;
        end
        lastline = line;
    end
    fclose(fid);

    %Write commit Id to file
    lineparts= strsplit_LMT(lastline);
    fid = fopen(fullfile(destination,'toolboxCommitId'),'w');
    fprintf(fid,'%s',lineparts{2});
    fclose(fid);
    
    
end