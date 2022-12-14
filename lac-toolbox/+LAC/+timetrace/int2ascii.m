function int2ascii(intdir,LC,sensors,varargin)
% Translate int-files to asc-files
%   intdir:     Path to int directory, ex: 'V:\26MW\V100\Investigation\009_Brake\V100-2.6MW\INT'
%   LC:         if only a load case is of interest, ex: '11' (DLC 11)
%   sensors:    sensors of interest, ex: [20:23 45]
%
%   Syntax
%   int2ascii('V:\26MW\V100\Investigation\009_Brake\V100-2.6MW\INT','',[18 20]);
%   or
%   int2ascii('C:\VestasToolbox\TLtoolbox\Example_Inputs\LoadCases_reduced\INT\','',[18 20]); 
%
% ALKJA 24-02-2011
% MOFEJ 07-11-2011  'Skip-existing-file' routine implemented

% Input parser.
Parser = inputParser;
Parser.addOptional('FatigueOnly',false); % Only include INT files that contribute to fatigue.
Parser.addOptional('FrequencyFile','');

% Parse.
Parser.parse(varargin{:});

% Set variables.
FatigueOnly = Parser.Results.('FatigueOnly');
FrequencyFile = Parser.Results.('FrequencyFile');

dirstart=pwd;
cd(intdir);
SpecSensor = false;
if nargin == 1
    LC = '';
elseif nargin >= 3 
    SpecSensor = true;
end


if ~isdir('ASCII')
    mkdir('ASCII')
end

% Find all files.    
files = dir([LC '*.int']);

% Filter away files that does not contribute to fatigue.
if FatigueOnly
    % Read frequency file.
    FrqObj = LAC.vts.convert(FrequencyFile, 'FRQ');
    
    % Find indices to keep.
    IndicesToKeep = FrqObj.frq ~= 0;

    % Filter.
    FrqObj.LC = FrqObj.LC(IndicesToKeep);
    FrqObj.time = FrqObj.time(IndicesToKeep);
    FrqObj.frq = FrqObj.frq(IndicesToKeep);
    FrqObj.family = FrqObj.family(IndicesToKeep);
    FrqObj.method = FrqObj.method(IndicesToKeep);
    FrqObj.LF = FrqObj.LF(IndicesToKeep);
    FrqObj.V = FrqObj.V(IndicesToKeep);
    
    % Filter list of files.
    files_filtered = struct;
    for iFile=1:size(files,1)
        % Set local.
        filename = files(iFile).name;
        
        % Set flag.
        keep_file = any(strcmp(filename, FrqObj.LC));
        
        % Update list.
        if keep_file
            % Flag.
            is_struct_empty = isempty(fieldnames(files_filtered));
            
            % Update struct.
            if is_struct_empty
                % Initiate struct.
                files_filtered = files(iFile);
            else
                files_filtered(end+1) = files(iFile);
            end
        end
    end
    
    % Update list.
    files = files_filtered;
    
    % Change dimension such that "size" below will still work.
    files = files';
end

if exist('sensor', 'file')
    sensorfile = true;
    SensorFileObj = LAC.vts.convert('sensor', 'SENSOR');
else
    sensorfile = false;
end

for i = 1:size(files,1)
    if exist([cd '\ASCII\' files(i).name(1:size(files(i).name,2)-4) '.asc'], 'file')
        disp(['Skipping ' files(i).name(1:size(files(i).name,2)-4) '.asc'])
        continue
    end
    % Read int file.
    dataflag = 1;
    Tmin = 0;
    Tmax = 9999;
    channels = sensors;
    [~,t,dat,~]=LAC.timetrace.int.readint(files(i).name,dataflag,channels,Tmin,Tmax);
    if SpecSensor
        Data = dat(:,sensors);
    else
        Data = dat(:,:);
        sensors = 1:size(Data,2);
    end
    NSens = size(Data,2);
    NDat = size(Data,1);
    
    fil = fopen(['ASCII\' files(i).name(1:size(files(i).name,2)-4) '.asc'],'wt+');
    disp(['Writing: ' files(i).name(1:size(files(i).name,2)-4) '.asc... ' '(file ' num2str(i) ' of ' num2str(size(files,1)) ')'])
    
    fprintf(fil,['Filename: ' files(i).name ' ' files(i).date '      Load case: ' files(i).name(1:size(files(i).name,2)-4) '\n\n']);
    if ~sensorfile
        fprintf(fil,'       ');
        for iSensor = 1:NSens
            fprintf(fil,'%14.0f', iSensor);
        end
        fprintf(fil,'\n');
    else
        fprintf(fil,'       ');
        for iSensor=1:NSens
            fprintf(fil,'%14.0f', SensorFileObj.no(sensors(iSensor)));
        end
        fprintf(fil,'\n     t ');        
        for iSensor=1:NSens
            fprintf(fil,'%14s', SensorFileObj.name{sensors(iSensor)});
        end
        fprintf(fil,'\n    (s)');
        for iSensor=1:NSens
            fprintf(fil,'%14s', SensorFileObj.unit{sensors(iSensor)});
        end
        fprintf(fil,'\n');
    end;
    
    for iData = 1:NDat
        fprintf(fil,'\n%7.2f',t(iData));
        %fprintf(fil,'%14.4e',Data(i,:));
        fprintf(fil,'%14.2f',Data(iData,:));
    end
    fprintf(fil,'\n');
    
    fclose(fil);
end