function Filename = BRK(BRK_InputConfig)
% Filename = BRK(BRK_InputConfig)
% NIWJO 2021
%
% %% INPUT File for BRK.m input transformation function
% VariantName         					= mk1a_EV162
% outputPath      						= c:\repo\lac_nglt\Projects\F3Up\Parts\BRK\
% filename_brake 							= c:\repo\lac_nglt\Projects\F3Up\PartsInputs\BRK\BRK.csv

% Input handle
InputConfigRaw = textscan(fileread(BRK_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);
inputStrList = {
    {'VariantName',0}
    {'filename_brake',0}
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

% input - Mechanical brake data.

%read input
csv_reader_drivetrain = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_drivetrain.ReadFile(InputConfigData.filename_brake);


% Create object and set data.
Filename = fullfile(InputConfigData.outputPath, sprintf('BRK_%s.%s', InputConfigData.VariantName,InputConfigData.extension));

% Initiate.
BrakePartsFileObj = LAC.vts.codec.BRK();

% Header.
if isempty(InputConfigData.header_comments)
    BrakePartsFileObj.Header = sprintf('Brake parts file for %s. Generated with: %s', InputConfigData.VariantName,regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
else
    BrakePartsFileObj.Header = sprintf('Brake parts file for %s. %s. Generated with: %s',InputConfigData.header_comments, InputConfigData.VariantName,regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
end

% Inertia of HSS brake;
BrakePartsFileObj.Jbrake = csv_reader_drivetrain.get_value_by_name('Jbrake');

% HSS speed for emergency braking;
BrakePartsFileObj.OmBrkOn = csv_reader_drivetrain.get_value_by_name('OmBrkOn');

% Static moment divided by dynamic braking moment;
BrakePartsFileObj.DynFak = csv_reader_drivetrain.get_value_by_name('DynFak');

% From VTS manual: "Factor multiplied to the braking moment of each individual brake (provided there is no brake file- the brake file can be specified as an option (Mbrk) in the load case definition)"
BrakePartsFileObj.Swdfak = csv_reader_drivetrain.get_value_by_name('SwdFak');

% Number of brakes;
BrakePartsFileObj.nCallibers = csv_reader_drivetrain.get_value_by_name('NoCallibers');

% Dynamic brake torque;
BrakePartsFileObj.DynBrakeTorque = csv_reader_drivetrain.get_value_by_name('DynBrkTorque');

% Time constant for exponential brake moment curve;
BrakePartsFileObj.Tau = csv_reader_drivetrain.get_value_by_name('Tau');

% Time constant for exponential brake moment curve;
BrakePartsFileObj.TdelayCalliper1 = csv_reader_drivetrain.get_value_by_name('Tdelay');

BrakePartsFileObj.comments = '';

BrakePartsFileObj.encode(Filename);
end