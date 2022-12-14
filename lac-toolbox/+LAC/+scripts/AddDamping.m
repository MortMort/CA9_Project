function AddDamping()
   
    path2program = fullfile(fileparts(which(['LAC.scripts.' mfilename])),['+' mfilename]);
    
    destination  = uigetdir(pwd,'Select destination folder');
    if destination == 0
        return
    end
        
    filenames = {'AddDamping_script.m'};
    
    for iFile= 1:length(filenames)
        file2copy    = fullfile(path2program,filenames{iFile});
        copyfile(file2copy,destination)
        if iFile == 1
        open(fullfile(destination,filenames{iFile}))
        end
    end
    cd(destination)
end