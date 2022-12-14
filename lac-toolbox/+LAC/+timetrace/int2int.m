function int2int(varargin)

    Parser = inputParser;
    Parser.addOptional('int_directory_in', []);
    Parser.addOptional('int_directory_out', []);
    Parser.addOptional('sensor_names', []);
    Parser.addOptional('sensor_file_path', []);
    Parser.addOptional('search_type', 'exact');
    Parser.addOptional('skip_if_file_exists', false);

    % Parse.
    Parser.parse(varargin{:});

    % Set variables.
    int_directory_in = Parser.Results.('int_directory_in');
    int_directory_out = Parser.Results.('int_directory_out');
    sensor_names = Parser.Results.('sensor_names');
    sensor_file_path = Parser.Results.('sensor_file_path');
    search_type = Parser.Results.('search_type');
    skip_if_file_exists = Parser.Results.('skip_if_file_exists');
    
    if isempty(sensor_file_path)
        % No sensor file path is specified. Use default.
        sensor_file_path = fullfile(int_directory_in, 'sensor');
    end

    % Read sensor file.
    SensorObj = LAC.vts.convert(sensor_file_path, 'SENSOR');
    
    % Initiate.
    sensor_numbers = [];
    SensorObj_reduced = LAC.vts.codec.SENSOR();
    isensor_new = 1;
    
    % Loop through sensor names to use.
    for iSensor=1:length(sensor_names)
        % Set sensor name.
        sensor_name = sensor_names{iSensor};

        % Find sensor.
        [index,~,~] = SensorObj.findSensor(sensor_name, search_type);

        % Set new sensor.
        SensorObj_reduced.no(end+1) = isensor_new;
        SensorObj_reduced.gain(end+1) = SensorObj.gain(index);
        SensorObj_reduced.offset(end+1) = SensorObj.offset(index);
        SensorObj_reduced.correction(end+1) = SensorObj.correction(index);
        SensorObj_reduced.volt(end+1) = SensorObj.volt(index);
        SensorObj_reduced.unit{end+1} = SensorObj.unit{index};
        SensorObj_reduced.name{end+1} = SensorObj.name{index};
        SensorObj_reduced.description{end+1} = SensorObj.description{index};

        % Save sensor number for this sensor.
        sensor_numbers(end+1) = index;

        % Increase counter.
        isensor_new = isensor_new + 1;
    end

    % Write new sensor file.
    if ~exist(int_directory_out, 'dir')
        mkdir(int_directory_out);
    end
    Filename = fullfile(int_directory_out, 'sensor');
    SensorObj_reduced.encode(Filename);
    
    % Convert all INT files in directory.
    intFiles = dir(fullfile(int_directory_in,'*.int'));
    for i = 1:length(intFiles)        
        % Set name.
        filename = intFiles(i).name;
        filepath_existing = fullfile(int_directory_in,filename);
        filepath_new = fullfile(int_directory_out,filename);
        
        % Skip file?
        if skip_if_file_exists
            file_exists = exist(filepath_new,'file');
        end
        
        % Status.
        if skip_if_file_exists && file_exists
            string_status = ['Skipping INT file ' num2str(i) ' of ' num2str(length(intFiles)) ' since it already exists :' filename ', in folder: ' int_directory_out];
        else
            string_status = ['Processing INT file ' num2str(i) ' of ' num2str(length(intFiles)) ' :' filename]; 
        end
        disp(string_status);
        
        % Convert.
        if skip_if_file_exists && file_exists
            % Skip this file.
            continue
        else
            [~,t,dat,~] = LAC.timetrace.int.readint(filepath_existing,1,[],[],[]);   
           % [t,dat] = intreadTL(filepath_existing);
            dat1 = dat(:,sensor_numbers);
            LAC.timetrace.int.intwrite(filepath_new,t(end)/length(t),dat1);
            clear dat1 dat t;
        end
    end
end