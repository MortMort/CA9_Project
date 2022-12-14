
function Filename = CNV(CNV_InputConfig)
% Filename = CNV(CNV_InputConfig)
% NIWJO 2021
%
% Example of CNV_InputConfig file.
% VariantName         = EV162_mk1a
% LaPM_settingsPath   = c:\repo\lac_nglt\Projects\F3Up\PartsInputs\LaPM_settings.csv
% CNV_Path            = c:\repo\lac_nglt\Projects\F3Up\PartsInputs\CNV\CNV.csv
% CNV_controls_Path   = c:\repo\lac_nglt\Projects\F3Up\PartsInputs\CNV\CNV_controls.csv
% CNV_loads_Path      = c:\repo\lac_nglt\Projects\F3Up\PartsInputs\CNV\CNV_loads.csv
% outputPath      = c:\repo\lac_nglt\Projects\F3Up\Parts\CNV\


% Input handle

InputConfigRaw = textscan(fileread(CNV_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);
inputStrList = {
    {'VariantName',0}
    {'LaPM_settingsPath',0}
    {'CNV_Path',0}
    {'CNV_controls_Path',0}
    {'CNV_loads_Path',0}
    {'outputPath',0}
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

T = readtable(InputConfigData.LaPM_settingsPath, 'ReadVariableNames', 0, 'ReadRowNames', 1,'Format','auto');
for iLaPM = 1:size(T,2)
    %i = i+1;
    PWR  = T{3,iLaPM}; PWR = str2double(PWR);
    SPD  = T{4,iLaPM}; SPD = str2double(SPD);
    CNV_file_struct(iLaPM).rated_power = PWR;
    CNV_file_struct(iLaPM).rated_speed = SPD;
    CNV_file_struct(iLaPM).filename_CNV_loads    = InputConfigData.CNV_loads_Path;
    CNV_file_struct(iLaPM).filename_CNV_controls = InputConfigData.CNV_controls_Path;
    CNV_file_struct(iLaPM).filename_CNV          = InputConfigData.CNV_Path;
    
    % Output name
    CNV_file_struct(iLaPM).filename_CNV_parts_file = fullfile(InputConfigData.outputPath, sprintf('CNV_%s_%dkW.%s',InputConfigData.VariantName, PWR,InputConfigData.extension));
    CNV_file_struct(iLaPM).header = sprintf('Converter parts file for %s %dkW and %drpm. ', InputConfigData.VariantName , PWR, SPD);
end

% Loop.
for iconverter_file_struct=1:length(CNV_file_struct)
    
    % Input parameters.
    csv_reader_converter = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
    csv_reader_converter.ReadFile(CNV_file_struct(iconverter_file_struct).filename_CNV);
    
    csv_reader_converter_loads = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
    csv_reader_converter_loads.ReadFile(CNV_file_struct(iconverter_file_struct).filename_CNV_loads);
    
    csv_reader_converter_controls = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
    csv_reader_converter_controls.ReadFile(CNV_file_struct(iconverter_file_struct).filename_CNV_controls);
    
    
    % Create object and set data.
    CNVPartsFileObj = LAC.vts.codec.CNV();
    CNVPartsFileObj.Header = CNV_file_struct(iconverter_file_struct).header;
    if isempty(InputConfigData.header_comments)
        CNVPartsFileObj.Header = sprintf('%s Generated with: %s.m',CNVPartsFileObj.Header, regexprep(mfilename('fullpath'),'^.*(?=(\+LAC))',''));
    else
        CNVPartsFileObj.Header = sprintf('%s %s. Generated with: %s',CNVPartsFileObj.Header,InputConfigData.header_comments, regexprep(mfilename('fullpath'),'^.*(?=(\+LAC))',''));
    end
    
    % **************************************
    % Loads input.
    % **************************************
    % Based on VTS experience / legacy.
    CNVPartsFileObj.T_PM = csv_reader_converter_loads.get_value_by_name('T_PM');
    CNVPartsFileObj.Ti = csv_reader_converter_loads.get_value_by_name('Ti');
    CNVPartsFileObj.kP = csv_reader_converter_loads.get_value_by_name('kP');
    CNVPartsFileObj.T_est = csv_reader_converter_loads.get_value_by_name('T_est');
    CNVPartsFileObj.Tdamp = csv_reader_converter_loads.get_value_by_name('Tdamp');
    % Power.
    CNVPartsFileObj.Pel_rtd = CNV_file_struct(iconverter_file_struct).rated_power;
    % Dummy value. VTS manual: "Generator voltage. Not used in VTS002V05.058".
    CNVPartsFileObj.gen_Voltage = 9999;
    
    % **************************************
    % Controls input.
    % **************************************
    % Drivetrain damping parameters from controls.
    CNVPartsFileObj.kdamp = csv_reader_converter_controls.get_value_by_name('kdamp');
    CNVPartsFileObj.dlim = csv_reader_converter_controls.get_value_by_name('dlim');
    
    % Rated rpm.
    CNVPartsFileObj.ratedRPM = CNV_file_struct(iconverter_file_struct).rated_speed;
    
    % Bypass settings.
    CNVPartsFileObj.BypassStopType0 = csv_reader_converter_controls.get_value_by_name('BypassStopType0');
    CNVPartsFileObj.BypassStopType1 = csv_reader_converter_controls.get_value_by_name('BypassStopType1');
    CNVPartsFileObj.BypassStopType2 = csv_reader_converter_controls.get_value_by_name('BypassStopType2');
    CNVPartsFileObj.BypassStopType3 = csv_reader_converter_controls.get_value_by_name('BypassStopType3');
    CNVPartsFileObj.BypassStopType4 = csv_reader_converter_controls.get_value_by_name('BypassStopType4');
    
    CNVPartsFileObj.OverspeedReaction1 = csv_reader_converter_controls.get_value_by_name('Oreac (DELTA)');
    CNVPartsFileObj.UnderspeedReaction1 = csv_reader_converter_controls.get_value_by_name('Ureac (DELTA)');
    CNVPartsFileObj.OverspeedReaction2 = csv_reader_converter_controls.get_value_by_name('Oreac (STAR)');
    CNVPartsFileObj.UnderspeedReaction2 = csv_reader_converter_controls.get_value_by_name('Ureac (STAR)');
    
    % **************************************
    % Converter input.
    % **************************************
    % Overspeed limits.
    CNVPartsFileObj.OverspeedLimit1 = csv_reader_converter.get_value_by_name('Olim (DELTA)');
    CNVPartsFileObj.UnderspeedLimit1 = csv_reader_converter.get_value_by_name('Ulim (DELTA)');
    CNVPartsFileObj.OverspeedLimit2 = csv_reader_converter.get_value_by_name('Olim (STAR)');
    CNVPartsFileObj.UnderspeedLimit2 = csv_reader_converter.get_value_by_name('Ulim (STAR)');
    
    % VTS manual: "RPM set point for Stop-Slow, Pause-Fast. See Figure 6-11, p. 42"
    CNVPartsFileObj.Omega0 = csv_reader_converter.get_value_by_name('Omega0');
    % VTS manual: "Rate of power decrease during stop-fast events. VCS turbines only."
    CNVPartsFileObj.StopFastPowerRampRate = csv_reader_converter.get_value_by_name('StopFastPowerRampRate');
    
    CNVPartsFileObj.comments = '';
    
    % Write file.
    Filename{iconverter_file_struct} = fullfile(CNV_file_struct(iconverter_file_struct).filename_CNV_parts_file);
    CNVPartsFileObj.encode(Filename{iconverter_file_struct});
    
    fclose('all');
end
end