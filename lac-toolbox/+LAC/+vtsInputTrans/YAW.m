function Filename = YAW(YAW_InputConfig)
% Filename = YAW(YAW_InputConfig)
% NIWJO 2021
%
%% INPUT File for YAW.m input transformation function
%VariantName         	= Vidar_V162
%outputPath      		= w:\ToolsDevelopment\vtsInputTrans\YAW\
%filename_nacelle 		= w:\ToolsDevelopment\vtsInputTrans\NAC\NAC.csv
%filename_yaw 			= w:\ToolsDevelopment\vtsInputTrans\YAW\YAW.csv
%extension 				= 101
%writePlfStudy 			= no

%% Default parameters
%%Logaritmic decrement for yaw mode
%LogD11 	= 0.03
%%Logaritmic decrement for tilt mode
%LogD12 	= 0.03


% Input handle
InputConfigRaw = textscan(fileread(YAW_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);
inputStrList = {
    {'VariantName',0}
    {'filename_nacelle',0}
    {'filename_yaw',0}
    {'LogD11',0}
    {'LogD12',0}
    {'outputPath',0}
    {'writePlfStudy',0}
    {'extension',0}
    {'header_comments',0}
    };
for i = 1:length(inputStrList)
    if any(contains(InputConfigRaw{1},inputStrList{i}{1}))
        InputConfigData.(inputStrList{i}{1}) = InputConfigRaw{2}{contains(InputConfigRaw{1},inputStrList{i}{1})};
        if inputStrList{i}{2}==1
            InputConfigData.(inputStrList{i}{1}) = strsplit(strrep(InputConfigData.(inputStrList{i}{1}),' ',''),',');
        elseif length(strsplit(InputConfigData.(inputStrList{i}{1}),','))>1
            error([inputStrList{i}{1} 'not allowed to have multiple inputs'])
        end
    else
        error([inputStrList{i}{1} ' not found in input config file'])
    end
end

csv_reader_nacelle = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_nacelle.ReadFile(InputConfigData.filename_nacelle);

% Input parameters.
csv_reader_yaw = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_yaw.ReadFile(InputConfigData.filename_yaw);

% Create object and set data.

YAWPartsFileObj = LAC.vts.codec.YAW();
if isempty(InputConfigData.header_comments)
    YAWPartsFileObj.Header = sprintf('Yaw parts file for %s. Generated with: %s', InputConfigData.VariantName,regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
else
    YAWPartsFileObj.Header = sprintf('Yaw parts file for %s. %s. Generated with: %s', InputConfigData.VariantName,InputConfigData.header_comments,regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
end


% Loads input.
YAWPartsFileObj.LogD11 = InputConfigData.LogD11;
YAWPartsFileObj.LogD12 = InputConfigData.LogD12;

% Nacelle input.
YAWPartsFileObj.ktilt = csv_reader_nacelle.get_value_by_name('ktilt');
YAWPartsFileObj.Kyawlo = csv_reader_nacelle.get_value_by_name('Kyawlo');
YAWPartsFileObj.Kyawhi = csv_reader_nacelle.get_value_by_name('Kyawhi');
YAWPartsFileObj.R = csv_reader_nacelle.get_value_by_name('R');
YAWPartsFileObj.V = csv_reader_nacelle.get_value_by_name('V');

% Yaw input.
YAWPartsFileObj.vmot = csv_reader_yaw.get_value_by_name('vmot');
YAWPartsFileObj.igear = csv_reader_yaw.get_value_by_name('igear');
YAWPartsFileObj.Tau = csv_reader_yaw.get_value_by_name('Tau');
YAWPartsFileObj.nomt = csv_reader_yaw.get_value_by_name('nmot');
YAWPartsFileObj.Imot = csv_reader_yaw.get_value_by_name('Imot');
YAWPartsFileObj.Mfricmot = csv_reader_yaw.get_value_by_name('Mfricmot');
YAWPartsFileObj.Eta = csv_reader_yaw.get_value_by_name('Eta');
YAWPartsFileObj.nbrk = csv_reader_yaw.get_value_by_name('nbrk');
YAWPartsFileObj.Mfricbrk = csv_reader_yaw.get_value_by_name('Mfricbrk');
YAWPartsFileObj.MfricStat = csv_reader_yaw.get_value_by_name('MfricStat');
YAWPartsFileObj.cFz = csv_reader_yaw.get_value_by_name('cFz');
YAWPartsFileObj.cFxy = csv_reader_yaw.get_value_by_name('cFxy');
YAWPartsFileObj.cMxy = csv_reader_yaw.get_value_by_name('cMxy');
YAWPartsFileObj.MfricDyn = csv_reader_yaw.get_value_by_name('MfricDyn');
YAWPartsFileObj.UserDefined = 0;

% Write file.
Filename = fullfile(InputConfigData.outputPath, sprintf('YAW_%s.%s', InputConfigData.VariantName,InputConfigData.extension));
YAWPartsFileObj.encode(Filename);

% **************************
% Create variants which has reduced resistance, i.e. to be used for checking yaw sliding. Since we cannot simulate with "design loads", we need to reduce the resistance instead.
% **************************
% Define load factors.
if strcmpi(InputConfigData.writePlfStudy,'yes')
    load_factors = [1.10, 1.35, 1.50];
    
    % Print file for each load factor.
    for iload_factor=1:length(load_factors)
        % Set load factor.
        load_factor = load_factors(iload_factor);
        
        % Make copy of original object.
        YAWPartsFileObj_tmp = YAWPartsFileObj;
        
        YAWPartsFileObj_tmp.Header = 'Create variants which has reduced resistance, i.e. to be used for checking yaw sliding. Since we cannot simulate with "design loads", we need to reduce the resistance instead.';
        
        % Reduce resistances.
        YAWPartsFileObj_tmp.Mfricbrk = num2str(str2double(YAWPartsFileObj.Mfricbrk)/load_factor);
        YAWPartsFileObj_tmp.Mfricmot = num2str(str2double(YAWPartsFileObj.Mfricmot)/load_factor, '%.2f');
        YAWPartsFileObj_tmp.MfricStat = num2str(str2double(YAWPartsFileObj.MfricStat)/load_factor, '%.0f');
        YAWPartsFileObj_tmp.MfricDyn = num2str(str2double(YAWPartsFileObj.MfricDyn)/load_factor, '%.0f');
        
        % Set separate file name.
        [folder, filename, extension] = fileparts(Filename);
        Filename_tmp = fullfile(folder, [filename '_plf_' strrep(sprintf('%.2f',load_factor),'.','_') extension]);
        
        % Write file.
        YAWPartsFileObj_tmp.encode(Filename_tmp);
    end
end
end