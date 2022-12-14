function [prepFile] = site2vts(intFiles,prepFilename,pathToIntfiles)
%SITE2VTS - Converts data from timetraces to VTS loadcases through GUI inputs
%Optional file header info (to give more details about the function than in the H1 line)
%
% Syntax:  [prepFile] = site2vts(intFiles,prepFilename,pathToIntfiles)
%
% Inputs:
%    intFiles       - list of intfiles to process
%                     intFiles = LAC.dir('path\INT\*')
%    prepFilename   - name of prepfile to be written
%    pathToIntfiles - path to infiles
%
% Outputs:
%    prepFile       - a prepfile with loadcase definition is written to the
%                     desired location
%
% Example: 
%    prepFile = site2vts(intFiles,'prepFilename','pathToIntfiles')
%
% Other m-files required: vdat,LAC.timetrace.int.intwrite
% Subfunctions: none
% MAT-files required: none
%
% See also: 

% Author: MAARD, Martin Brodsgaard
% May 2015; Last revision: 28-July-2015

if exist('vdat')~=2
    error('vdat is used for reading timetraces and need to be mapped in the path')
end

h = waitbar(0,'Reading data from INT files ...');
nIntFiles      = size(intFiles,1);
workPath           = uigetdir(pwd);

prepFilename = strrep(prepFilename,'\','');
prepFilename = strrep(prepFilename,'/','');
prepFile     = fullfile(workPath,sprintf('%s.txt',prepFilename));
fidPrep      = fopen(prepFile,'wt');  
fileNameLast = [];
iFile = 1;
while iFile <= nIntFiles
    %% Collect data 
    [~,filename]  = fileparts(intFiles{iFile});        
    if strcmp(fileNameLast,filename)
        iFile=iFile+1;
        continue
    end
    fileNameLast  = filename;
    
    if nargin>2
        Timetrace = vdat('convert',fullfile(pathToIntfiles,intFiles{iFile}));
    else
        % Read Timetrace
        Timetrace = vdat('convert',intFiles{iFile});
    end
    
    %% Collect userinputs
    if iFile==1

        % Determine wind speed sensors
        [Index.windspeeds,flagWind] = listdlg('PromptString','Select sensor for wind speeds:',...
            'ListString',Timetrace.GenInfo.SensorSym);

        if ~flagWind
           close(h)
           return 
        end
        if length(Index.windspeeds)>1

            for iWindSpeed = 1:length(Index.windspeeds)
                sensorText           = Timetrace.GenInfo.SensorSym(Index.windspeeds(iWindSpeed),:);
                nums                 = regexp(sensorText,'\d','match');
                if ~isempty(nums)
                    defaultInputs{iWindSpeed} = [nums{:}];
                else
                    defaultInputs{iWindSpeed} = '';
                end
                prompt{iWindSpeed}        = ['Enter hub height for ' sensorText ' :'];
            end
            name='Input for sensor heights';
            numlines=1;
            answer=inputdlg(prompt,name,numlines,defaultInputs);
            for iAnswers = 1:length(answer)
                sensorHeights(iAnswers) = str2num(answer{iAnswers});
            end
            flagWindshear = true;
        else
            flagWindshear = false;
        end


        % Determine temperature sensor
        [Index.temperature,flagTemp] = listdlg('PromptString','Select sensor for temperature:',...
            'ListString',Timetrace.GenInfo.SensorSym);
        
        if flagTemp
            % Determine pressure sensor
            [Index.pressure,flagPress] = listdlg('PromptString','Select sensor for pressure:',...
                'ListString',Timetrace.GenInfo.SensorSym);
        else
            flagPress = false;
        end

        % Determine yaw error
        [Index.wdir,flagWdir] = listdlg('PromptString','Select sensor for wind direction:',...
            'ListString',Timetrace.GenInfo.SensorSym);

        % VTS command
        strCommand{1} = '';
        prompt = {'VTS command for load case (leave blank if none):'};
        dlg_title = 'VTS command';
        def = {''};
        strCommand = inputdlg(prompt,dlg_title,1,def);
        if isempty(strCommand)
            strCommand{1} = '';
        end

        % Run ConSim?
        choice = questdlg('Run ConSim on load cases?', ...
            'ConSim', ...
            'Yes','No','No');
        switch choice
            case 'Yes'
                mkdir(fullfile(workPath,'ConSim'))
                cd(fullfile(workPath,'ConSim'))
                
                fidConSim  = fopen(fullfile(workPath,'ConSim','ConSim.bat'),'wt');  
                % Copy setfile
                [setFilename, setPathname] = uigetfile({'*.set','set-files (*.set)';},'Pick a set-file for ConSim', 'Untitled.set');
                setFile = fullfile(setPathname,setFilename);
                copyfile(setFile,fullfile(workPath,'ConSim','ConSim.set'))

                copyfile('W:\SOURCE\consim\ConSim.exe',fullfile(workPath,'ConSim'))

                fprintf(fidPrep,['* ' prepFilename ' for ConSim wind files.\n\n']);
                flagConSim = true;
            case 'No'
                fprintf(fidPrep,['* ' prepFilename '\n\n']);
                flagConSim = false;
        end
    end
    
    %% Process data
    waitbar(iFile/nIntFiles,h,['Reading data from INT file: ',num2str(iFile) ' out of ',num2str(nIntFiles)]);

    % Calc wind parameters
    windspeedHub      = Timetrace.Ydata(:,Index.windspeeds(1));
    windspeedHubMean  = mean(windspeedHub);

    % Turbulence Intensity
    windspeedHubStd          = std(detrend(windspeedHub));
    windspeedHubTurbulence   = windspeedHubStd/windspeedHubMean;

    % Critera
    if windspeedHubMean<3.5
        iFile=iFile+1;
        continue
    end

    if flagWindshear
        windspeedMid      = Timetrace.Ydata(:,Index.windspeeds(2));
        windspeedMidMean = mean(windspeedMid);

        windspeedBottom      = Timetrace.Ydata(:,Index.windspeeds(3));
        windspeedBottomMean = mean(windspeedBottom);

        % Wind shear
        windShear1 = log(windspeedHubMean/windspeedMidMean)/log(sensorHeights(1)/sensorHeights(2));
        windShear2 = log(windspeedMidMean/windspeedBottomMean)/log(sensorHeights(2)/sensorHeights(3));
        windShear3 = log(windspeedHubMean/windspeedBottomMean)/log(sensorHeights(1)/sensorHeights(3));
        windShear  = mean([windShear1,windShear2,windShear3]);
    end        
    if flagWdir
        wdir       = Timetrace.Ydata(:,Index.wdir); 
        % Wind direction
        wdir      = mean(wdir);
    else
        wdir      = randn(1)*3;
    end

    if flagTemp && flagPress
        temperatureDeg  = Timetrace.Ydata(:,Index.temperature);
        pressure        = Timetrace.Ydata(:,Index.pressure);    
        % Air density
        Pres_Mean = mean(pressure);
        Temp_Mean = mean(temperatureDeg);
        Rho       = (Pres_Mean*100)/(287.05*(Temp_Mean+273.15));
    end

    %% Write textfile
    filenameToWrite = filename;

    WriteVhub     = round(windspeedHubMean*10^2)/10^2;
    WriteWdir     = round(wdir*10^2)/10^2;
    strPrep   = sprintf('%s\nntm %s Freq 1 LF 1.00\n1 2 %s %s',filenameToWrite,num2str(randi(8,1,1)),num2str(WriteVhub),num2str(WriteWdir));
    if flagConSim
        writeTurbulence = 1;
    else
        writeTurbulence = round(windspeedHubTurbulence*10^4)/10^4;
    end
    strTurb   = sprintf(' turb %s',num2str(writeTurbulence));
    strPrep       = sprintf('%s%s',strPrep,strTurb);

    if flagWindshear
        writeWsh  = round(windShear*10^3)/10^3;
        strWsh    = sprintf(' vexp %s',num2str(writeWsh));
        strPrep       = sprintf('%s%s',strPrep,strWsh);
    end
    if flagPress && flagTemp
        writeRho  = round(Rho*10^3)/10^3;
        strRho    = sprintf(' rho %s',num2str(writeRho));
        strPrep   = sprintf('%s%s',strPrep,strRho);
    end
    strPrep = sprintf('%s ',strPrep,strCommand{:});        

    if iFile==1
        disp(strPrep)
        choice = questdlg(strPrep, ...
            'Load Case Example', ...
            'Correct','Not Correct','Correct');
        switch choice
            case 'Not Correct'
                fileNameLast = [];
                iFile = 1;
                continue
        end
    end
    fprintf(fidPrep,strPrep);        
    fprintf(fidPrep,'\n\n');
    
    %% Process ConSim
    if flagConSim  
        LAC.timetrace.int.intwrite(fullfile(workPath,'ConSim',[filename '.int']),Timetrace.GenInfo.TsAvg,windspeedHub)    
        fprintf(fidConSim,'call ConSim.exe %s %i\n',[filename '.int'],1); 
    end

    iFile=iFile+1;
end
close(h);
fclose(fidPrep);
fclose('all');
dos(['start ' workPath])
if flagConSim 
    fclose(fidConSim);
    dos('start ConSim.bat')
end


