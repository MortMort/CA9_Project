function OptiTip()
   
    path2program = fullfile(fileparts(which(['LAC.scripts.' mfilename])),['+' mfilename]);
    
    destination  = uigetdir(pwd,'Select destination folder');
    if destination == 0
        return
    end
        
    filenames = 'OptiTip_Configuration.m';
	
    copyfile(path2program,destination)
    open(fullfile(destination,filenames))

    
end