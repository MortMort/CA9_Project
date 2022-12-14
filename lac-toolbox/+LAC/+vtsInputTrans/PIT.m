function Filenames = PIT(PIT_InputConfig)
% Filename = PIT(PIT_InputConfig)
% NIWJO 2021
%
% Example of PIT_InputConfig.txt file.
%% INPUT File for PIT_InputTrans.m function
% The PL file is optional, but if given then the pitch geometry parameters will be updated
% VariantName			= Vidar_V162
% outputpath			= w:\ToolsDevelopment\vtsInputTrans\PIT\
% pitch_geometry_file	= w:\ToolsDevelopment\vtsInputTrans\PIT\Pitch Geometry Parameters.xlsx
% pitch_table_file	= w:\ToolsDevelopment\vtsInputTrans\PIT\Pitch_Table_VidarF3_Eaton.txt
% extension 			= 101
% 
% The PL file will just be updated and no new file created
% PL_file				= w:\ToolsDevelopment\vtsInputTrans\PIT\_PL_Vidar_V162_IEC_LTq_pdot_GC.101

% Input handle
InputConfigRaw = textscan(fileread(PIT_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);
inputStrList = {
    {'VariantName',0}
    {'PL_file',1}
    {'pitch_geometry_file',0}
    {'pitch_table_file',0}
    {'outputpath',0}
    {'extension',0}
    {'header_comments',0}
    {'PL_header_comments',0}
	{'PL_inp_version',0}
    {'pitch_geometry_file_Selection1',0}
    {'pitch_geometry_file_Selection2',0}
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
        winopen(PIT_InputConfig)
        error([inputStrList{i}{1} ' not found in input config file'])
    end
end

% Creat object and set data.
Filename = fullfile(InputConfigData.outputpath,['PIT_' InputConfigData.VariantName '.' InputConfigData.extension]);
PitchPartsFileObj = LAC.vts.codec.PIT();
if isempty(InputConfigData.header_comments)
    PitchPartsFileObj.Header = sprintf('Pitch parts file for %s.', InputConfigData.VariantName);
else
    PitchPartsFileObj.Header = sprintf('Pitch parts file for %s. %s. ', InputConfigData.VariantName,InputConfigData.header_comments);
end
PitchPartsFileObj.Header = [PitchPartsFileObj.Header 'Generated with: "' regexprep(mfilename('fullpath'),'^.*(?=(\+LAC))','') '.m".'];

% Read pitch tables.
pitch_table = LAC.componentgroups.HUB();
pitch_table.ReadFile_000_pitch_table(InputConfigData.pitch_table_file);

% "Hub Engineering" parameters.
Hydr = LAC.componentgroups.PIT.collectPitchParameters(InputConfigData.pitch_geometry_file,'Selection1',InputConfigData.pitch_geometry_file_Selection1,'Selection2',InputConfigData.pitch_geometry_file_Selection2);

% Non project specific inputs
PitchPartsFileObj.order = 1; % Order of filter
PitchPartsFileObj.timeconst = 0.01; % timeconst[s]/f0[Hz]
PitchPartsFileObj.Ksi  = 0; % -/Ksi
PitchPartsFileObj.tpsdelay = 0; % tpsdelay[s]
PitchPartsFileObj.Deadband = 0; % Deadband [deg]
PitchPartsFileObj.EMCpitchspeedresp = 0; %2nd order pitch speed response 0=off, 1=only EMS, 2=only normal prod, 3=EMS and normal prod
PitchPartsFileObj.Frequency = 4;%Centre frequency of 2nd order filter
PitchPartsFileObj.DampingRatio = 0.3;%-;Damping ration of 2nd order filter

% Hub engineering input.
PitchPartsFileObj.PistonPosxMin1 = 0;
PitchPartsFileObj.PistonPosxMin2 = 0;
PitchPartsFileObj.PistonPosxMin3 = 0;
PitchPartsFileObj.PistonPosxMax1 = Hydr.x_stroke*1e3;
PitchPartsFileObj.PistonPosxMax2 = Hydr.x_stroke*1e3;
PitchPartsFileObj.PistonPosxMax3 = Hydr.x_stroke*1e3;
PitchPartsFileObj.PiMinG1 = rad2deg(Hydr.Pdz);
PitchPartsFileObj.PiMinG2 = rad2deg(Hydr.Pdz);
PitchPartsFileObj.PiMinG3 = rad2deg(Hydr.Pdz);
PitchPartsFileObj.PiMaxG1 = Hydr.PiMax;
PitchPartsFileObj.PiMaxG2 = Hydr.PiMax;
PitchPartsFileObj.PiMaxG3 = Hydr.PiMax;
PitchPartsFileObj.tupd0 = 0.2;
PitchPartsFileObj.tupd1 = 0.2;
PitchPartsFileObj.tupd2 = 0.2;
PitchPartsFileObj.Tables{1}.rownames = cellfun(@(x) num2str(x),num2cell(pitch_table.ControlVoltages),'UniformOutput',0)';
PitchPartsFileObj.Tables{1}.columnnames = cellfun(@(x) num2str(x),num2cell(pitch_table.PitchMoments),'UniformOutput',0);
PitchPartsFileObj.Tables{1}.data = num2cell(pitch_table.PitchRates);

PitchPartsFileObj.Tables{2}.rownames = cellfun(@(x) num2str(x),num2cell(pitch_table.ControlVoltages),'UniformOutput',0)';
PitchPartsFileObj.Tables{2}.columnnames = cellfun(@(x) num2str(x),num2cell(pitch_table.PitchMoments),'UniformOutput',0);
PitchPartsFileObj.Tables{2}.data = num2cell(pitch_table.PitchRates);

PitchPartsFileObj.a_0 = Hydr.pcell(5);
PitchPartsFileObj.a_1 = Hydr.pcell(4);
PitchPartsFileObj.a_2 = Hydr.pcell(3);
PitchPartsFileObj.a_3 = Hydr.pcell(2);
PitchPartsFileObj.a_4 = Hydr.pcell(1);


% VTS legacy parameters. Discussed with STEFW. VTSmanual = "unused". STEFW agrees with manual and concluded that vts code shows that values are not being read.
% Set dummy values.
dummy_value = 9999;
PitchPartsFileObj.PosVgain = dummy_value;
PitchPartsFileObj.PosOffset = dummy_value;
PitchPartsFileObj.Theta_k = dummy_value;
PitchPartsFileObj.c_pitch_1 = dummy_value;
PitchPartsFileObj.c_pitch_2 = dummy_value;
PitchPartsFileObj.c_pitch_3 = dummy_value;
PitchPartsFileObj.c_pitch_4 = dummy_value;

% Apparently not in use, but seems to be set to limits from pitch table.
PitchPartsFileObj.TBD1 = min(pitch_table.ControlVoltages);
PitchPartsFileObj.TBD2 = max(pitch_table.ControlVoltages);

% Comments.
PitchPartsFileObj.comments = '';

% Write file.
PitchPartsFileObj.encode(Filename);

fclose('all');

% Create file with safety pitch parameters
PitchParam2CtrlAndVTSparamFilename = LAC.componentgroups.PIT.PitchParam2CtrlAndVTSparam(Hydr,'outputfolder',InputConfigData.outputpath);

% Update PL table
if ~isempty(InputConfigData.PL_file{1})
    for i = 1:length(InputConfigData.PL_file)
        PLobj               = LAC.vts.convert(InputConfigData.PL_file{i},'PL');
        if ~isempty(InputConfigData.PL_header_comments)
            PLobj.Header1        = sprintf('IntPostD Postloads.inp %s. %s. Updated using %s.m',InputConfigData.PL_inp_version, InputConfigData.PL_header_comments, regexprep(mfilename('fullpath'),'^.*(?=(\+LAC))',''));
        end
        PLobj.PIT_R         = {num2str(Hydr.R*1e3)};
        PLobj.PIT_alfa_0    = {num2str(rad2deg(Hydr.alpha0_vts))};
        PLobj.PIT_A         = {num2str(Hydr.Xa*1e3)};
        PLobj.PIT_L         = {num2str(Hydr.Ya*1e3)};
        PLobj.encode(InputConfigData.PL_file{i});
    end
end
Filenames{1} = Filename;
Filenames{2} = InputConfigData.PL_file;
Filenames{3} = PitchParam2CtrlAndVTSparamFilename;
end
