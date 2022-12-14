function Filename = DRT(DRT_InputConfig)
% Filename = DRT(DRT_InputConfig)
% NIWJO 2021
%
%% INPUT File for NAC.m input transformation function
%VariantName         					= Vidar_V162_HTq
%outputPath      						= w:\ToolsDevelopment\vtsInputTrans\DRT\
%filename_torque_envelope 				= w:\ToolsDevelopment\vtsInputTrans\DRT\torque_envelope.csv
%filename_drivetrain 					= w:\ToolsDevelopment\vtsInputTrans\DRT\DRT.csv
%filename_drivetrain_structural 			= w:\ToolsDevelopment\vtsInputTrans\DRT\DRT_structural.csv
%filename_drivetrain_structural_nacelle 	= w:\ToolsDevelopment\vtsInputTrans\DRT\DRT_structural_NAC.csv
%filename_powertrain_type				= w:\ToolsDevelopment\vtsInputTrans\DRT\powertrain_type.csv
%header_comments 						=
%extension 								= 103
%
%% Default parameters
%%Logarithmic decrement for main shaft rotation DOF. The value is forced to zero during the initialization. DOF 5 is special see 5.4 DOFs, p. 10
%Damping5 	= 0
%%Logarithmic decrement for main shaft vertical bending DOF (MzMBr=‘yaw’)
%Damping6 	= 0.02
%%Logarithmic decrement for main shaft horizontal bending DOF (MxMBr=‘tilt’)
%Damping7 	= 0.02
%%Logaritihmic decrement for main shaft torsion
%ND 	= 0.1


% Input handle
InputConfigRaw = textscan(fileread(DRT_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);
inputStrList = {
    {'VariantName',0}
    {'filename_torque_envelope',0}
    {'filename_drivetrain',0}
    {'filename_drivetrain_structural',0}
    {'filename_drivetrain_structural_nacelle',0}
    {'filename_powertrain_type',0}
    {'outputPath',0}
    {'header_comments',0}
    {'Damping5',0}
    {'Damping6',0}
    {'Damping7',0}
    {'ND',0}
    {'extension',0}
    {'ktors_eq_case',0}
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


% Input from nacelle.
csv_reader_drivetrain_structural_nacelle = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_drivetrain_structural_nacelle.ReadFile(InputConfigData.filename_drivetrain_structural_nacelle);

% Input parameters.
csv_reader_drivetrain = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_drivetrain.ReadFile(InputConfigData.filename_drivetrain);
igear = csv_reader_drivetrain.get_value_by_name('igear');

% Structural input.
csv_reader_drivetrain_structural = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_drivetrain_structural.ReadFile(InputConfigData.filename_drivetrain_structural);

% Create object and set data.
DRTPartsFileObj = LAC.vts.codec.DRT();
if isempty(InputConfigData.header_comments)
    DRTPartsFileObj.Header = sprintf('Drivetrain parts file for %s. Generated with: %s ', InputConfigData.VariantName, regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
else
    DRTPartsFileObj.Header = sprintf('Drivetrain parts file for %s. %s. Generated with: %s ', InputConfigData.VariantName,InputConfigData.header_comments, regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
end

% VTS experience. VTS manual: "Logarithmic decrement for main shaft rotation DOF. The value is forced to zero during the initialization. DOF 5 is special see 5.4 DOFs, p. 10"
DRTPartsFileObj.Damping5    = InputConfigData.Damping5;
DRTPartsFileObj.Damping6    = InputConfigData.Damping6;
DRTPartsFileObj.Damping7    = InputConfigData.Damping7;
DRTPartsFileObj.ND          = InputConfigData.ND;

% Drivetrain input.
DRTPartsFileObj.igear = igear;
DRTPartsFileObj.Jgear = csv_reader_drivetrain.get_value_by_name('Jgear');
DRTPartsFileObj.kgear = csv_reader_drivetrain.get_value_by_name('kGear');
DRTPartsFileObj.JbrakeHub = csv_reader_drivetrain.get_value_by_name('Jbrake hub');
DRTPartsFileObj.Jgenhub = csv_reader_drivetrain.get_value_by_name('Jgen hub');

% Structural (from nacelle guys).
DRTPartsFileObj.ktilt = csv_reader_drivetrain_structural_nacelle.get_value_by_name('ktilt');
DRTPartsFileObj.kyaw = csv_reader_drivetrain_structural_nacelle.get_value_by_name('kyaw');
DRTPartsFileObj.VerticalStiffness = csv_reader_drivetrain_structural_nacelle.get_value_by_name('kVgs');
DRTPartsFileObj.HorizontalStiffnessHigh = csv_reader_drivetrain_structural_nacelle.get_value_by_name('kHgsR');
DRTPartsFileObj.HorizontalStiffnessLow = csv_reader_drivetrain_structural_nacelle.get_value_by_name('kHgsL');
DRTPartsFileObj.DistanceGearStays = csv_reader_drivetrain_structural_nacelle.get_value_by_name('Dgs');
DRTPartsFileObj.DistanceMainBearingGearStays = csv_reader_drivetrain_structural_nacelle.get_value_by_name('Dgsmb');
kt_lss = csv_reader_drivetrain_structural_nacelle.get_value_by_name('ktors');

% Structural (from drivetrain guys).
DRTPartsFileObj.kHSS = csv_reader_drivetrain_structural.get_value_by_name('Khss'); % dummy value (no HSS in Vidar)
DRTPartsFileObj.Jhss = csv_reader_drivetrain_structural.get_value_by_name('JHSS'); % dummy value (no HSS in Vidar)

% Calculation of ktors
% The parameter ktors in vts is actually a equlivant stiffness defined by multiple compoenents
% This have been calculated differently between projects and should be treated according to the
% input given. Align with the drivetrain what formulation to use.

switch InputConfigData.ktors_eq_case
    case '1'
        DRTPartsFileObj.ktors = int64(kt_lss);
    case '2'
        kt_gbx = DRTPartsFileObj.kgear;
        keq_lss = 1/( 1/kt_lss + 1/kt_gbx);
        DRTPartsFileObj.ktors = int64(keq_lss);
    case '3'
        kt_gbx = DRTPartsFileObj.kgear;
        keq_lss = 1/( 1/kt_lss + 1/kt_gbx);
        keq_hss = igear^2 * DRTPartsFileObj.kHSS;
        kt_eq = 1/( 1/keq_lss + 1/keq_hss );
        DRTPartsFileObj.ktors = int64(kt_eq);
end

% Table. Based on experience? Is it being used?
data{1,1} = 1000;
data{1,2} = 1010;
data{1,3} = 1000;
data{1,4} = 0;
data{2,1} = 2000;
data{2,2} = 1010;
data{2,3} = 1000;
data{2,4} = -1;
data{3,1} = 3000;
data{3,2} = 1010;
data{3,3} = 1000;
data{3,4} = 0;
DRTPartsFileObj.ShaftSectionTable{1}.data = data;

% Values based on experience?
DRTPartsFileObj.R_V = 0.1;
DRTPartsFileObj.K0_Ktors = 0.1;
DRTPartsFileObj.m = 0.1;

% Misc.
DRTPartsFileObj.sectionline1 = '--------------------';
DRTPartsFileObj.sectionline2 = '--------------------';
DRTPartsFileObj.sectionline3 = '--------------------';

%%% HACK TO ADD TORQUE ENVELOPE AND POWERTRAIN TYPE IN PART FILE. SHOULD BE
%%% UPDATED IN CODEX

% Torque envelope
torque_envelope = dlmread(InputConfigData.filename_torque_envelope);
DRTPartsFileObj.comments = ['Torque-Envelope\n', sprintf('%d %d nrow ncol (Omega-[rpm] MyMBr-[kNm])', size(torque_envelope, 1), size(torque_envelope, 2))];
for i_row = 1:size(torque_envelope, 1)
    DRTPartsFileObj.comments = [DRTPartsFileObj.comments, '\n', sprintf('%g %.0f', torque_envelope(i_row, 1), torque_envelope(i_row, 2))];
end
DRTPartsFileObj.comments = sprintf(DRTPartsFileObj.comments);

% Powertrain-Type
csv_reader_powertrain_type = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_powertrain_type.ReadFile(InputConfigData.filename_powertrain_type);

switch csv_reader_powertrain_type.get_value_by_name('MBType')
    case 1
        MBType = '3-POINT';
    case 2
        MBType = '4-POINT';
    case 3
        MBType = 'MODULAR-CANTILEVER';
    otherwise
end
DRTPartsFileObj.comments = [DRTPartsFileObj.comments sprintf('\n-------------------------------\nPowertrain-Type\n')];
DRTPartsFileObj.comments = [DRTPartsFileObj.comments sprintf('%s                    # Type of Powertrain [3-POINT, 4-POINT, MODULAR-CANTILEVER ]\n',MBType)];
DRTPartsFileObj.comments = [DRTPartsFileObj.comments sprintf('MB-RegProxy-Constants\n')];
DRTPartsFileObj.comments = [DRTPartsFileObj.comments sprintf('%.2f %.2f %.2f %.2f %.2f %.2f # RegProxy-Constants for Powertrain\n',...
    csv_reader_powertrain_type.get_value_by_name('RegProxy1'),...
    csv_reader_powertrain_type.get_value_by_name('RegProxy2'),...
    csv_reader_powertrain_type.get_value_by_name('RegProxy3'),...
    csv_reader_powertrain_type.get_value_by_name('RegProxy4'),...
    csv_reader_powertrain_type.get_value_by_name('RegProxy5'),...
    csv_reader_powertrain_type.get_value_by_name('RegProxy6'))];
DRTPartsFileObj.comments = [DRTPartsFileObj.comments sprintf('MB-StaticProxy-Constants\n')];
DRTPartsFileObj.comments = [DRTPartsFileObj.comments sprintf('%.2f %.2f                             # StaticProxy-Constants for Powertrain\n',...
    csv_reader_powertrain_type.get_value_by_name('StaticProxy1'),...
    csv_reader_powertrain_type.get_value_by_name('StaticProxy2'))];
DRTPartsFileObj.comments = [DRTPartsFileObj.comments sprintf('Gearbox\n')];
for i = 1:3
    DRTPartsFileObj.comments = [DRTPartsFileObj.comments sprintf('%s    %.2f    %.0e    %.2f\n',...
        ['MyRotBend' num2str(i)],...
        csv_reader_powertrain_type.get_value_by_name('MyRotBend_m'),...
        csv_reader_powertrain_type.get_value_by_name('MyRotBend_neq'),...
        csv_reader_powertrain_type.get_value_by_name(['MyRotBend' num2str(i)]))];
end
for i = 1:3
    DRTPartsFileObj.comments = [DRTPartsFileObj.comments sprintf('%s     %.2f    %.0e    %.2f\n',...
        ['MyRotPit' num2str(i)],...
        csv_reader_powertrain_type.get_value_by_name('MyRotPit_m'),...
        csv_reader_powertrain_type.get_value_by_name('MyRotPit_neq'),...
        csv_reader_powertrain_type.get_value_by_name(['MyRotPit' num2str(i)]))];
end

% Write file.
Filename = fullfile(InputConfigData.outputPath, sprintf('DRT_%s.%s', InputConfigData.VariantName,InputConfigData.extension));
DRTPartsFileObj.encode(Filename);
end
