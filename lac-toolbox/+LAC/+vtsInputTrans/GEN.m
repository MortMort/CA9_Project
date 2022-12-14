function Filename = GEN(GEN_InputConfig)
% Filename = GEN(GEN_InputConfig)
% NIWJO 2021
%
% %% INPUT File for GEN.m input transformation function
% VariantName         							= Vidar_V162_HTq
% outputPath      								= w:\ToolsDevelopment\vtsInputTrans\GEN\
% filename_generator_electrical_efficiency_delta 	= w:\ToolsDevelopment\vtsInputTrans\GEN\Electrical_Efficiency_Delta.csv
% filename_generator_mechanical_efficiency_delta 	= w:\ToolsDevelopment\vtsInputTrans\GEN\Mechanical_Efficiency_Delta.csv
% filename_generator_electrical_efficiency_star 	= w:\ToolsDevelopment\vtsInputTrans\GEN\Electrical_Efficiency_Star.csv
% filename_generator_mechanical_efficiency_star 	= w:\ToolsDevelopment\vtsInputTrans\GEN\Mechanical_Efficiency_Star.csv
% filename_auxiliary_loss 						= w:\ToolsDevelopment\vtsInputTrans\GEN\Auxiliary_Efficiency.csv
% filename_generator 								= w:\ToolsDevelopment\vtsInputTrans\GEN\Generator.csv
% filename_LaPM_settings 							= w:\ToolsDevelopment\vtsInputTrans\LaPM_settings.csv
% 
% header_comments 								= Source DMS xxxx-xxxx
% extension 										= 104
%
% Input handle
InputConfigRaw = textscan(fileread(GEN_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);
inputStrList = {
    {'VariantName',0}
    {'filename_generator_electrical_efficiency_delta',0}
    {'filename_generator_mechanical_efficiency_delta',0}
    {'filename_generator_electrical_efficiency_star',0}
    {'filename_generator_mechanical_efficiency_star',0}
    {'filename_generator',0}
    {'filename_auxiliary_loss',0}
	{'filename_LaPM_settings',0}
    {'outputPath',0}
    {'header_comments',0}
    {'extension',0}
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


% Load LaPM settings.
fid = fopen(InputConfigData.filename_LaPM_settings);
data = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);
for iLine = 1:length(data{1})
    if strfind(lower(data{1}{iLine}), 'mode')
        modes = textscan(data{1}{iLine}, '%s', 'delimiter', ';');
        modes = modes{1}(2:end)';
    elseif strfind(lower(data{1}{iLine}), 'pwr')
        power = textscan(data{1}{iLine}, '%s', 'delimiter', ';');
        power = str2double(power{1}(2:end))';
    elseif strfind(lower(data{1}{iLine}), 'spd')
        speed = textscan(data{1}{iLine}, '%s', 'delimiter', ';');
        speed = str2double(speed{1}(2:end))';
    end
end

% Input parameters.
csv_reader_generator = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_generator.ReadFile(InputConfigData.filename_generator);

for iMode = 1:length(modes)
    
    % Create object and set data.
    GENPartsFileObj = LAC.vts.codec.GENv1();
    if isempty(InputConfigData.header_comments)
        GENPartsFileObj.Header = sprintf('Generator parts file for %s %.0fkW %drpm. Generated with: %s.', InputConfigData.VariantName, power(iMode), speed(iMode),regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
    else
        GENPartsFileObj.Header = sprintf('Generator parts file for %s %.0fkW %drpm. %s. Generated with: %s.', InputConfigData.VariantName, power(iMode), speed(iMode),InputConfigData.header_comments,regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
    end
    
    % Generator data.
    GENPartsFileObj.GeneratorInertia = csv_reader_generator.get_value_by_name('Igen');
    GENPartsFileObj.Polepairs = csv_reader_generator.get_value_by_name('nPole');
    GENPartsFileObj.Fnet = csv_reader_generator.get_value_by_name('fgrid');
    GENPartsFileObj.ConstLoss = csv_reader_generator.get_value_by_name('Const_loss');
    GENPartsFileObj.PelRtd = power(iMode);
    GENPartsFileObj.GenRpmRtd = speed(iMode);
    
    % From VTS manual: "Dummy parameters not used in VTS. However must be there."
    GENPartsFileObj.Psc = 9999;
    GENPartsFileObj.dtsc = 9999;
    GENPartsFileObj.TGridErr = 9999;
    GENPartsFileObj.HFTorgue = 9999;
    
    % Read tables.
    [data, columnnames, rownames] = read_and_format_table(InputConfigData.filename_generator_electrical_efficiency_delta);
    header = 'G1 Electrical efficiency table (power[kW]-RPM-efficiency) Delta';
    GENPartsFileObj.Generator1Table{1}.header{1} = header;
    GENPartsFileObj.Generator1Table{1}.data = data;
    GENPartsFileObj.Generator1Table{1}.columnnames = columnnames;
    GENPartsFileObj.Generator1Table{1}.rownames = rownames;
    
    [data, columnnames, rownames] = read_and_format_table(InputConfigData.filename_generator_mechanical_efficiency_delta);
    header = 'G1 Mechanical efficiency table (power[kW]-RPM-efficiency) Delta';
    GENPartsFileObj.Generator1Table{2}.header{1} = header;
    GENPartsFileObj.Generator1Table{2}.data = data;
    GENPartsFileObj.Generator1Table{2}.columnnames = columnnames;
    GENPartsFileObj.Generator1Table{2}.rownames = rownames;
    
    [data, columnnames, rownames] = read_and_format_table(InputConfigData.filename_generator_electrical_efficiency_star);
    header = 'G2 Electrical efficiency table (power[kW]-RPM-efficiency) Star';
    GENPartsFileObj.Generator2Table{1}.header{1} = header;
    GENPartsFileObj.Generator2Table{1}.data = data;
    GENPartsFileObj.Generator2Table{1}.columnnames = columnnames;
    GENPartsFileObj.Generator2Table{1}.rownames = rownames;
    
    [data, columnnames, rownames] = read_and_format_table(InputConfigData.filename_generator_mechanical_efficiency_star);
    header = 'G2 Mechanical efficiency table (power[kW]-RPM-efficiency) Star';
    GENPartsFileObj.Generator2Table{2}.header{1} = header;
    GENPartsFileObj.Generator2Table{2}.data = data;
    GENPartsFileObj.Generator2Table{2}.columnnames = columnnames;
    GENPartsFileObj.Generator2Table{2}.rownames = rownames;
    
    % Read table from file.
    [data, columnnames, rownames] = read_and_format_table(InputConfigData.filename_auxiliary_loss);
    header = 'AuxLossTable';
    GENPartsFileObj.AuxLossTable{1}.header{1} = header;
    GENPartsFileObj.AuxLossTable{1}.data = data;
    GENPartsFileObj.AuxLossTable{1}.columnnames = columnnames;
    GENPartsFileObj.AuxLossTable{1}.rownames = rownames;
    
    GENPartsFileObj.comments = '';
    % Write file.
    Filename = fullfile(InputConfigData.outputPath, sprintf('GEN_%s_%.0fkW.%s', InputConfigData.VariantName, power(iMode), InputConfigData.extension));
    GENPartsFileObj.encode(Filename);
end

    function [data, columnnames, rownames] = read_and_format_table(filename)
        % Read data.
        data_raw = dlmread(filename);
        nrows = size(data_raw,1);
        ncolumns = size(data_raw,2);
        
        % Loop through rows.
        for irow=1:nrows
            % Loop through columns.
            for icolumn=1:ncolumns
                % First row is "column_names". Current format require this to be string formatted.
                if irow == 1
                    if icolumn == 1
                        % Do not use this value.
                    else
                        columnnames{icolumn-1} = sprintf('%.f', data_raw(irow, icolumn));
                    end
                else
                    if icolumn == 1
                        % First row contains "rownames".
                        rownames{irow-1} = sprintf('%.f',data_raw(irow, icolumn));
                    else
                        % Format data.
                        data{irow-1, icolumn-1} = sprintf('%.4f',data_raw(irow, icolumn));
                    end
                end
            end
        end
        rownames = rownames';
    end
end