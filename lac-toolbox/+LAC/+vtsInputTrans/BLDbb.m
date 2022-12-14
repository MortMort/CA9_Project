function Filename = BLDbb(BLDbb_InputConfig)
% Filename = BLDbb(BLDbb_InputConfig)
% NIWJO 2021
%
%% INPUT File for BLDbb.m input transformation function
% filename_blade 							= w:\ToolsDevelopment\vtsInputTrans\BLDbb\BLD_Vidar_V162_STD_STE.107, w:\ToolsDevelopment\vtsInputTrans\BLDbb\BLD_Vidar_V162_STD_STE_extended_output.107
% filename_BBinput                          = w:\ToolsDevelopment\vtsInputTrans\BLDbb\BLD_blade_bearing.csv
% extension 								= 108

% Input handle
InputConfigRaw = textscan(fileread(BLDbb_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);

% Input List is structured as
% {name, allow multiple inputs}...
inputStrList = {
    {'filename_blade',1}
    {'filename_BBinput',0}
    {'filename_bladeFixTemplate',0}
    {'extension',0}
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

% Input from blade bearing team.
csv_reader_blade_bearing = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_blade_bearing.ReadFile(InputConfigData.filename_BBinput);

% Update of blade files
for i = 1:length(InputConfigData.filename_blade)
    bbObj = LAC.vts.convert(InputConfigData.filename_blade{i},'BLD');
    bbObj.Retype = csv_reader_blade_bearing.get_value_by_name('Type');
    bbObj.MFric0 = csv_reader_blade_bearing.get_value_by_name('MFric0');
    bbObj.mu = csv_reader_blade_bearing.get_value_by_name('Mu');
    bbObj.DL = csv_reader_blade_bearing.get_value_by_name('DL');
    bbObj.c_fric = csv_reader_blade_bearing.get_value_by_name('cSlopeBB');
    
    
    if isempty(InputConfigData.extension)
        Filename{i} = InputConfigData.filename_blade{i};
    else
        [PATHSTR,NAME] = fileparts(InputConfigData.filename_blade{i});
        Filename{i} = fullfile(PATHSTR,[NAME '.' InputConfigData.extension]);
    end
    bbObj.encode(Filename{i})
end

% Update of blade fix template file
i = 0;
fid = fopen(InputConfigData.filename_bladeFixTemplate,'r');
while 1
    i = i+1;
    blade_bearing_data{i} = fgetl(fid);
    if ~ischar(blade_bearing_data{i}), break, end
end
fclose(fid);
blade_bearing_data = blade_bearing_data(1:end-1);
blade_bearing_data{cellfun(@(x) ~isempty(strfind(x,'MFric0')),blade_bearing_data)} = sprintf('%.2f	 %.2e	 %.4f	     %.2f	   %.2f	 Retype; MFric0 [Nm];mu;DL [m]',...
    csv_reader_blade_bearing.get_value_by_name('Type'),...
    csv_reader_blade_bearing.get_value_by_name('MFric0'),...
    csv_reader_blade_bearing.get_value_by_name('Mu'),...
    csv_reader_blade_bearing.get_value_by_name('DL'),...
    csv_reader_blade_bearing.get_value_by_name('cSlopeBB'));
fid = fopen(InputConfigData.filename_bladeFixTemplate,'W');
for i = 1:length(blade_bearing_data)
    fprintf(fid,'%s\n',blade_bearing_data{i});
end
fclose(fid);

Filename{end+1} = InputConfigData.filename_bladeFixTemplate;
end