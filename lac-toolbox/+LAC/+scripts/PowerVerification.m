function PowerVerification()
   
    path2program = fullfile(fileparts(which(['LAC.scripts.' mfilename])),['+' mfilename]);
    
    destination  = uigetdir(pwd,'Select destination folder');
    LIDAR = input('Do you want to use met-mast or LiDAR measured wind speed? L-LiDAR, M-MetMast\n', 's');
    
    if destination == 0
        return
    end
    
    if strcmpi(LIDAR,'l')
        filenames = {'PowerPerformance_Mainscript.m', 'PowerVerificationInputs_VIDAR_LIDAR.xlsx', '_Guideline.txt'};
    elseif strcmpi(LIDAR,'m')
        filenames = {'PowerPerformance_Mainscript.m', 'PowerVerificationInputs_VIDAR.xlsx', '_Guideline.txt'};
    else
        disp('Input not recognized.');
        return;
    end
    
    for iFile= 1:length(filenames)
        file2copy    = fullfile(path2program,filenames{iFile});
        copyfile(file2copy,destination)
        if iFile == 1
        open(fullfile(destination,filenames{iFile}))
        end
    end
    cd(destination)
end