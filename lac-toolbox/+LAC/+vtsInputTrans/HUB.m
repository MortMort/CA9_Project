
function Filename = HUB(HUB_InputConfig)
% Filename = HUB(HUB_InputConfig)
% NIWJO 2021
%
% Example of HUB_InputConfig file.
% %% INPUT File for HUB.m input transformation function
% VariantName         	= EV162_mk1a
% HubStructualFilePath 	= c:\repo\lac_nglt\Projects\F3Up\PartsInputs\HUB\HUB_structural_F3.csv
% outputPath      		= c:\repo\lac_nglt\Projects\F3Up\Parts\HUB\
% extension 				= 101
% 
% % Default parameters
% %Hub drag coefficient down wind
% Cdxs 	= 0.00E+00
% %Hub drag coefficient from side
% Cdyzs 	= 0.00E+00
% 

% Input handle
InputConfigRaw = textscan(fileread(HUB_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);
inputStrList = {
    {'VariantName',0}
    {'HubStructualFilePath',0}
    {'outputPath',0}
    {'Cdxs',0}
    {'Cdyzs',0}
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

% Inputs from Hub Engineering.
csv_reader_hub = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_hub.ReadFile(InputConfigData.HubStructualFilePath);

% Create object and set data.
HUBPartsFileObj = LAC.vts.codec.HUB();

% General.
if isempty(InputConfigData.header_comments)
    HUBPartsFileObj.Header = sprintf('Hub parts file for %s. Generated with %s.', InputConfigData.VariantName,regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
else
    HUBPartsFileObj.Header = sprintf('Hub parts file for %s. %s. Generated with %s.', InputConfigData.VariantName,InputConfigData.header_comments,regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
end

% From Hub Engineering.
HUBPartsFileObj.Cdxs        = InputConfigData.Cdxs; %Hub drag coefficient down wind
HUBPartsFileObj.Cdyzs       = InputConfigData.Cdyzs; %Hub drag coefficient from side

HUBPartsFileObj.Mhub        = csv_reader_hub.get_value_by_name('Mhub');
HUBPartsFileObj.ZGNAV       = csv_reader_hub.get_value_by_name('YGNAV');
HUBPartsFileObj.ZNAV        = csv_reader_hub.get_value_by_name('YNAV');
HUBPartsFileObj.ZRN         = csv_reader_hub.get_value_by_name('YRN');
HUBPartsFileObj.ZRMB        = csv_reader_hub.get_value_by_name('YRMB');
HUBPartsFileObj.Rhub        = csv_reader_hub.get_value_by_name('Rhub');
HUBPartsFileObj.Ixhub       = csv_reader_hub.get_value_by_name('Ixhub');
HUBPartsFileObj.Iyhub       = csv_reader_hub.get_value_by_name('Iyhub');
HUBPartsFileObj.Izhub       = csv_reader_hub.get_value_by_name('Izhub');
HUBPartsFileObj.ARx         = csv_reader_hub.get_value_by_name('ARx');
HUBPartsFileObj.ARyz        = csv_reader_hub.get_value_by_name('ARyz');
HUBPartsFileObj.XlatR       = csv_reader_hub.get_value_by_name('YlatR');
HUBPartsFileObj.Nacc        = csv_reader_hub.get_value_by_name('Nacc');
HUBPartsFileObj.comments    = '';

% Write file.
Filename = fullfile(InputConfigData.outputPath, sprintf('HUB_%s.%s', InputConfigData.VariantName,InputConfigData.extension));
HUBPartsFileObj.encode(Filename);

fclose('all');
end