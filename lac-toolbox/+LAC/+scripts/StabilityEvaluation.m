function StabilityEvaluation()
   
    path2program = fullfile(fileparts(which(['LAC.scripts.' mfilename])),['+' mfilename]);
    
    destination  = uigetdir(pwd,'Select destination folder');
    if destination == 0
        return
    end
        
    filenames = {'RunBladeEvaluation.m','PostBladeEvaluation.m','SetupStability.txt'};
    
    for iFile= 1:length(filenames)
        file2copy    = fullfile(path2program,filenames{iFile});
        copyfile(file2copy,destination)
        open(fullfile(destination,filenames{iFile}))
    end
end