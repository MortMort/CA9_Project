function WhirlingMargin()
   
    path2program = fullfile(fileparts(which(['LAC.scripts.' mfilename])),['+' mfilename]);
    
    destination  = uigetdir(pwd,'Select destination folder');
    if destination == 0
        return
    end
        
    filenames = {'PlotWhirlingStability.m','CheckEdgewiseLoadAmplitude.m','RunWhirlingStability.m ','LC_01_ReferenceNTM.txt','LC_02_ReferenceETM.txt','LC_03_WorstCaseTI05.txt','LC_04_WorstCaseETM.txt','_ParameterStudyWorstCase.txt','_ParameterStudyNominal.txt','DeleteFiles_PostHook.bat'};
    
    for iFile= 1:length(filenames)
        file2copy    = fullfile(path2program,filenames{iFile});
        copyfile(file2copy,destination)
        open(fullfile(destination,filenames{iFile}))
    end
    
    mkdir(destination,'01_ReferenceNTM')
    mkdir(destination,'02_ReferenceETM')
    mkdir(destination,'03_WorstCaseTI05')
    mkdir(destination,'04_WorstCaseETM')
end