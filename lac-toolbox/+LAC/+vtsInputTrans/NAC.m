function Filename = NAC(NAC_InputConfig)
% Filename = NAC(NAC_InputConfig)
% NIWJO 2021
%
%% INPUT File for NAC.m input transformation function
%VariantName         		= Vidar_V162_HTq
%outputPath      			= w:\ToolsDevelopment\vtsInputTrans\NAC\
%filename_nacelle 			= w:\ToolsDevelopment\vtsInputTrans\NAC\NAC.csv
%filename_nacelle_dynamic 	= w:\ToolsDevelopment\vtsInputTrans\NAC\NAC_dynamic.csv
%header_comments 			= 
%extension					= 102
%
% Default parameters
%Nacelle drag coefficient front
%Cdx 	= 0.98
%Nacelle drag coefficient side
%Cdy 	= 1.09


% Input handle
InputConfigRaw = textscan(fileread(NAC_InputConfig),'%s%s%[^\n\r]', 'Delimiter', '=',  'ReturnOnError', false);
inputStrList = {
    {'VariantName',0}
    {'filename_nacelle',0}
    {'filename_nacelle_dynamic',0}
    {'Cdx',0}
    {'Cdy',0}
    {'outputPath',0}
    {'header_comments',0}
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


% Read common data.

% Structure input.
csv_reader_nacelle_common = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_nacelle_common.ReadFile(InputConfigData.filename_nacelle);


% Generate files.

% Read dynamic (i.e. mass, inertia, CoG) input.
csv_reader_nacelle = LAC.componentgroups.CsvInputFileReader.CsvInputFileReader();
csv_reader_nacelle.ReadFile(InputConfigData.filename_nacelle_dynamic);

% Create object and set data.

NACPartsFileObj = LAC.vts.codec.NAC();

% General.
if isempty(InputConfigData.header_comments)
    NACPartsFileObj.Header = sprintf('Nacelle parts file for %s. Generated with: %s',InputConfigData.VariantName,regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
else
    NACPartsFileObj.Header = sprintf('Nacelle parts file for %s. %s. Generated with: %s',InputConfigData.VariantName, InputConfigData.header_comments,regexprep([mfilename('fullpath') '.m'],'^.*(?=(\+LAC))',''));
end
% From nacelle engineering.
NACPartsFileObj.Ax = csv_reader_nacelle_common.get_value_by_name('Ax');
NACPartsFileObj.Ay = csv_reader_nacelle_common.get_value_by_name('Ay');
NACPartsFileObj.XlatK = csv_reader_nacelle_common.get_value_by_name('YlatK');
NACPartsFileObj.zkk2 = csv_reader_nacelle_common.get_value_by_name('zkk2');
NACPartsFileObj.Rtac = csv_reader_nacelle_common.get_value_by_name('Rtac');

mass = csv_reader_nacelle.get_value_by_name('Mass');
Cgy = csv_reader_nacelle.get_value_by_name('Cgy');
Cgx = csv_reader_nacelle.get_value_by_name('Cgx');
Cgz = csv_reader_nacelle.get_value_by_name('Cgz');
J2y0 = csv_reader_nacelle.get_value_by_name('J2y0');
J2x0 = csv_reader_nacelle.get_value_by_name('J2x0');
J2z0 = csv_reader_nacelle.get_value_by_name('J2z0');
NACPartsFileObj.Table{1}.data = {mass, Cgy, Cgx, Cgz, J2y0, J2x0, J2z0};
NACPartsFileObj.Table{1}.columnnames = {'Mass','Cgy','Cgx','Cgz','J2y0','J2x0','J2z0'};

% From loads.
NACPartsFileObj.Cdx = InputConfigData.Cdx;
NACPartsFileObj.Cdyz = InputConfigData.Cdy;

try
    NACPartsFileObj.DamperMass = csv_reader_nacelle.get_value_by_name('dmass');
    NACPartsFileObj.DamperXnd = csv_reader_nacelle.get_value_by_name('xnd');
    NACPartsFileObj.DamperYnd = csv_reader_nacelle.get_value_by_name('ynd');
    NACPartsFileObj.DamperZnd = csv_reader_nacelle.get_value_by_name('znd');
    NACPartsFileObj.DamperLogDX = csv_reader_nacelle.get_value_by_name('LogDx');
    NACPartsFileObj.DamperLogDY = csv_reader_nacelle.get_value_by_name('LogDy');
    NACPartsFileObj.DamperLogDZ = csv_reader_nacelle.get_value_by_name('LogDz');
    NACPartsFileObj.DamperKx = csv_reader_nacelle.get_value_by_name('Kx');
    NACPartsFileObj.DamperKy = csv_reader_nacelle.get_value_by_name('Ky');
    NACPartsFileObj.DamperKz = csv_reader_nacelle.get_value_by_name('Kz');
    NACPartsFileObj.DamperStopXmax = csv_reader_nacelle.get_value_by_name('xmax');
    NACPartsFileObj.DamperStopYmax = csv_reader_nacelle.get_value_by_name('ymax');
    NACPartsFileObj.DamperStopZmax = csv_reader_nacelle.get_value_by_name('zmax');
    NACPartsFileObj.DamperStopKratx = csv_reader_nacelle.get_value_by_name('Kratx');
    NACPartsFileObj.DamperStopKraty = csv_reader_nacelle.get_value_by_name('Kraty');
    NACPartsFileObj.DamperStopKratz = csv_reader_nacelle.get_value_by_name('Kratz');
catch
    warning(sprintf('No damper exist in nacelle %s',InputConfigData.filename_nacelle_dynamic))
    % Values based on experience?
    NACPartsFileObj.DamperMass = 0;
    NACPartsFileObj.DamperXnd = 0;
    NACPartsFileObj.DamperYnd = 0;
    NACPartsFileObj.DamperZnd = 0;
    NACPartsFileObj.DamperLogDX = 0;
    NACPartsFileObj.DamperLogDY = 0;
    NACPartsFileObj.DamperLogDZ = 0;
    NACPartsFileObj.DamperKx = 0;
    NACPartsFileObj.DamperKy = 0;
    NACPartsFileObj.DamperKz = 0;
    NACPartsFileObj.DamperStopXmax = 0;
    NACPartsFileObj.DamperStopYmax = 0;
    NACPartsFileObj.DamperStopZmax = 0;
    NACPartsFileObj.DamperStopKratx = 0;
    NACPartsFileObj.DamperStopKraty = 0;
    NACPartsFileObj.DamperStopKratz = 0;
end

NACPartsFileObj.comments = '';

% Write file.
Filename = fullfile(InputConfigData.outputPath, sprintf('NAC_%s.%s', InputConfigData.VariantName,InputConfigData.extension));
NACPartsFileObj.encode(Filename);

fclose('all');

end