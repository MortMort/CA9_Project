function Filenames = VRB(VRB_InputConfig)
% Filename = VRB(VRB_InputConfig)
% NIWJO 2021
%
% Example of VRB_InputConfig.txt file.
%% INPUT File for VRB_InputTrans.m function
% VariantName							= Vidar_V162
% outputpath							= w:\ToolsDevelopment\vtsInputTrans\VRB\
% filename_vrb_base_file				= w:\ToolsDevelopment\vtsInputTrans\VRB\VRB.txt
% filename_acceleration_sensors_file	= w:\ToolsDevelopment\vtsInputTrans\VRB\acceleration_sensors.csv
% LaPM_file 							= w:\ToolsDevelopment\vtsInputTrans\LaPM_settings.csv
% extension 							= 101
% header_comments  					= Source DMS xxxx-xxxx
%
% % Set useModes if power or load modes are used in the project
% useModes 							= yes



% Input handle
InputConfigRaw = textscan(fileread(VRB_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);
inputStrList = {
    {'VariantName',0}
    {'filename_vrb_base_file',1}
    {'filename_acceleration_sensors_file',0}
    {'outputpath',0}
    {'extension',0}
    {'acceleration_comments',0}
    {'LaPM_file',0}
    {'mode_line_id',1}
    };
for i = 1:length(inputStrList)
    if any(strcmpi(regexprep(InputConfigRaw{1}, '\s+', ''),inputStrList{i}{1}))
        InputConfigData.(inputStrList{i}{1}) = InputConfigRaw{2}{strcmpi(regexprep(InputConfigRaw{1}, '\s+', ''),inputStrList{i}{1})};
        if inputStrList{i}{2}==1
            InputConfigData.(inputStrList{i}{1}) = strsplit(strrep(InputConfigData.(inputStrList{i}{1}),' ',''),',');
        elseif length(strsplit(InputConfigData.(inputStrList{i}{1}),','))>1
            error([inputStrList{i}{1} 'not allowed to have multiple inputs'])
        end
    else
        error([inputStrList{i}{1} ' not found in input config file'])
    end
end

for k = 1:length(InputConfigData.filename_vrb_base_file)
    
    % Load baseline data
    vrb_base_content = textscan(fileread(InputConfigData.filename_vrb_base_file{k}), '%s', 'delimiter', '\n');
    
    % Load acceleration file
    acceleration_sensors_position = textscan(fileread(InputConfigData.filename_acceleration_sensors_file), '%s', 'delimiter', '\n');
    
    % For each variant / type combination open the LaPM file describing
    % the power, speed and mode number, save in structure
    if ~isempty(InputConfigData.LaPM_file)
        T = readtable(InputConfigData.LaPM_file, 'ReadVariableNames', 0, 'ReadRowNames', 1,'Format','auto');
        for i = 1:size(T,2)
            VRB_files_list(i).mode = T{1,i};
            VRB_files_list(i).number = cell2mat(T{2,i});
            VRB_files_list(i).PWR = str2double(T{3,i});
            VRB_files_list(i).SPD = str2double(T{4,i});
            VRB_files_list(i).VRB_parts_name = fullfile(InputConfigData.outputpath, sprintf('VRB_%s_%.0fkW.%s', InputConfigData.VariantName, VRB_files_list(i).PWR, InputConfigData.extension));
            
        end
    else
        VRB_files_list(1).mode = 0;
        VRB_files_list(1).number = 0;
        VRB_files_list(1).PWR = 0;
        VRB_files_list(1).SPD = 0;
        VRB_files_list(1).VRB_parts_name = fullfile(InputConfigData.outputpath, sprintf('VRB_%s.%s', InputConfigData.VariantName, InputConfigData.extension));
    end
    
    % Generate files.
    for ifile_struct = 1:length(VRB_files_list)
        
        % Update the Mode
        if ~isempty(InputConfigData.LaPM_file)
            for i = 1:length(InputConfigData.mode_line_id)
                mode_line = strsplit(vrb_base_content{1}{contains(vrb_base_content{1},InputConfigData.mode_line_id{i})},' ');
                mode_line{end-2} = num2str(VRB_files_list(ifile_struct).number, '%i');

                vrb_base_content{1}{contains(vrb_base_content{1},InputConfigData.mode_line_id{i})} = strjoin(mode_line,' ');
            end
        end
        
        % Update acceleration sensors
        if ~isempty(acceleration_sensors_position)
            accIdx =  find(cellfun(@(x) ~isempty(x),strfind(vrb_base_content{1},'ACCELERATIONSENSORS:')));
            if isempty(accIdx)
                error('ACCELERATIONSENSORS: not found in VRB file')
            elseif length(accIdx)>1
                error('more than one ACCELERATIONSENSORS: found in VRB file. Only one is allowed')
            end
            
            spaceIdx =  find(strcmpi(vrb_base_content{1},''));
            if isempty(spaceIdx)
            else
                if ~any(spaceIdx>accIdx)
                    vrb_base_content{1} = vrb_base_content{1}(1:accIdx);
                else
                    vrb_base_content{1} = [vrb_base_content{1}(1:accIdx)' vrb_base_content{1}(min(spaceIdx(spaceIdx>accIdx)):end)']';
                end
            end
            
            vrb_base_content{1}{accIdx-1} = sprintf('! %s',InputConfigData.acceleration_comments);
            
            % Make space for the acceleration sensors
            vrb_base_content{1} = [vrb_base_content{1}(1:accIdx)' cell(1,length(acceleration_sensors_position{1})-1) vrb_base_content{1}(accIdx+1:end)']';
            for iSens = 1:length(acceleration_sensors_position{1})-1
                accData =  strsplit(acceleration_sensors_position{1}{iSens+1},';');
                location = sprintf('%-7.3f %-7.3f %.3f', str2double(accData{2}), str2double(accData{3}), str2double(accData{4}));
                vrb_base_content{1}{accIdx+iSens} = sprintf('%-25s! Acceleration sensor at %-s', location, accData{6});
            end
        end
        
        % Open file for editing
        Filenames{ifile_struct} = VRB_files_list(ifile_struct).VRB_parts_name;
        fid = fopen(Filenames{ifile_struct}, 'w');
        % Write base VRB data
        for iLine = 1:length(vrb_base_content{1})
            fprintf(fid, '%s\n', vrb_base_content{1}{iLine});
        end
        fclose(fid);
    end
end
end