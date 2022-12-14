
function print_given_frequency(Input_frequnecy_fullpath,Givefrequency,Output_Folder_Directory,Output_Frequncy_Name)

% Converting frequnecy file to required format
FrqObj = LAC.vts.convert(Input_frequnecy_fullpath, 'FRQ');

% Filtering for  'Givenfrequency'
Filtered_frequnecy_names = zeros(1,length(Givefrequency));

for  ifiltered_frq =1:length(Givefrequency)
    match_frq =strcmp(FrqObj.LC,Givefrequency(ifiltered_frq));
    Filtered_frequnecy_names(ifiltered_frq) = find(match_frq ==1);
end

% Set output folder.
output_folder = fullfile(cd,Output_Folder_Directory);
if ~exist(output_folder)
    mkdir(output_folder);
end

% Set output file.
filename = fullfile(output_folder, [ Output_Frequncy_Name '.txt' ]);

% Open file.
fid = fopen(filename,'wt');

% Hardcode header lines.
lines_header = {'Prep002v05.030                                   Prep5 version number',
    'V116-2.00MW HH94.00m IECS                        Title of calculation',
    'The frequency table below is based on following 3 input values',
    ''
    '  8.50 [m/s]       Average wind speed',
    '  2.00 [-]         Weibull shape factor k',
    ' 20.00 [year]      Lifetime',
    '',
    ' File                     Time [h]    Freq [-]  Family  Method Load Factor  V [m/s]'};

% Loop through the hardcoded lines above.
for iline=1:length(lines_header)
    % Set local.
    line = lines_header{iline};
    
    % Print line.
    fprintf(fid,'%s\n',line);
end

% Print data.
for iline=1:length(Filtered_frequnecy_names)
   
   
    % Set local.
    LC = FrqObj.LC{Filtered_frequnecy_names(iline)};
    time = FrqObj.time(Filtered_frequnecy_names(iline));
    frq = FrqObj.frq(Filtered_frequnecy_names(iline));
    family = FrqObj.family(Filtered_frequnecy_names(iline));
    method = FrqObj.method(Filtered_frequnecy_names(iline));
    LF = FrqObj.LF(Filtered_frequnecy_names(iline));
    V = FrqObj.V(Filtered_frequnecy_names(iline));
    
    % Format data into string.
    line = '';
    line = [line sprintf('%-22s',LC)];
    line = [line sprintf('%13.1f',time)];
    line = [line sprintf('%12.2f',frq)];
    line = [line sprintf('%6d',family)];
    line = [line sprintf('%6d',method)];
    line = [line sprintf('%11.2f',LF)];
    line = [line sprintf('%8s','(')];
    line = [line sprintf('%4.1f',V)];
    line = [line sprintf('%s',')')];
    
    % Print line.
    fprintf(fid,'%s\n',line);
end

fprintf(fid,'\n%s\n','Total hours in  20 years:   157528, corresponding to:  18.0 year.');

% Close file.
fclose(fid);

end


