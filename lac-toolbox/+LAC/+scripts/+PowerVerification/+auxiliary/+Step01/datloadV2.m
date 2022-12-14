%% Program user inputs request
fprintf('\nDefault user inputs\n   extension: txt\n   var_no:    dat1\n   meas_type: Long (xxxxxx_yyyymmdd_hhmm)\n   sensorname_type: Short (from the file "sensor")\n\n')

import LAC.scripts.PowerVerification.auxiliary.Step01.*

inp_check = 0;
% while inp_check == 0
%     user = upper(input('Modify inputs? (Y/N)\n', 's'));
%   
%     if user == 'Y'
%         extension = listinp('What is the extension of the input files ?', {'txt', 'd1', 'd2', 'd3', 'jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'}, 1);
%         fprintf('\n');
%         var_no    = listinp('Which variable should the data be saved in ?', {'dat1', 'dat2', 'dat3', 'dat4', 'dat5', 'dat6', 'dat7', 'dat8', 'dat9', 'dat10', 'dat23', 'dat24', 'dat25', 'dat26'}, 1);  
%         fprintf('\n');
%         meas_type = listinp('Which filename system is the data stored in ?', {'Long (xxxxxx_yyyymmdd_hhmm)', 'Short (yymmddxx)', 'Miscellaneous (No file number calculated)'}, 1);  
%         fprintf('\n');
%         sensorname_type = listinp('Which format should the sensor names be stored in ?', {'Short (from the file "sensor")', 'Full  (from the file "datsensorname.txt")'}, 1);
%         
%         inp_check = 1;
%         
%     elseif user == 'N'
         extension       = 'txt';
         var_no          = 'dat1';
         meas_type       = 'Long (xxxxxx_yyyymmdd_hhmm)';
         sensorname_type = 'Short (from the file "sensor")';
%         
         inp_check = 1;
%         
%     else
%         fprintf('Invalid input');
%     end    
% end

%% Read measurement sensors info and filenames from Dat_Path
fprintf('\nReading sensor info (name / number / statistic type / units) and filenames \n');

% Sensor info
if strcmp(sensorname_type, 'Short (from the file "sensor")')
    [C] = sensread('sensor');       % read sensor list file
    [xdata.dat.sensorname] = C{7};  % use sensor short names, column 7
elseif strcmp(sensorname_type, 'Full  (from the file "datsensorname.txt")')
    [xdata.dat.sensorname] = textread(['datsensorname.' extension],'%s ',-1,'headerlines',0,'delimiter',';' );
end

[xdata.dat.sensorno] = textread(['datsensorno.' extension],'%s ',-1,'headerlines',0,'delimiter',';' );
[xdata.dat.stat]     = textread(['datstat.' extension],'%s ',-1,'headerlines',0,'delimiter',';' );
[xdata.dat.unit]     = textread(['datunit.' extension],'%s ',-1,'headerlines',0,'delimiter',';' );

% Read filenames and numbers (based on measurements dates)
[xdata.dat.filename] = textread(['datfilename.' extension],'%s ',-1,'headerlines',0,'delimiter',';' );

if exist(['datfiledescription.' extension])
    [xdata.dat.filedescription] = textread(['datfiledescription.' extension],'%s ',-1,'headerlines',0,'delimiter',';' );
else
    xdata.dat.filedescription = xdata.dat.filename;
end

if length(xdata.dat.filedescription)==0
    xdata.dat.filedescription = xdata.dat.filename;
end

[r, dummy] = size(xdata.dat.filename);    % Number of files
[c, dummy] = size(xdata.dat.unit);        % Number of sensors
[s, dummy] = size(xdata.dat.stat);        % Number of statistics

fprintf('   Number of files: %i\n', r);
fprintf('   Number of sensors: %i\n', c);
fprintf('   Number of statistic types: %i\n', s);

%%
fprintf('\nReading filenumbers (based on measurements dates) \n');

if strcmp(meas_type,'Short (yymmddxx)')
    for i=1:length(xdata.dat.filename)
        xdata.dat.fileno(i)=findfileno_short(xdata.dat.filename(i))';
    end
end

if strcmp(meas_type,'Long (xxxxxx_yyyymmdd_hhmm)')
    for i=1:length(xdata.dat.filename)
        xdata.dat.fileno(i)=findfileno_long_anyde(xdata.dat.filename(i))';
    end
end

if strcmp(meas_type,'Miscellaneous (No file number calculated)')
    for i=1:length(xdata.dat.filename)
        xdata.dat.fileno(i)=now;
    end
end

xdata.dat.fileno = xdata.dat.fileno';

%% Reading datamatrix file
fprintf('\nReading databin file (formatted for each statistic type) \n');
fid        = fopen(['datbin.' extension]);
[A, count] = fread(fid,'float32');
fclose(fid);

% Create struct elements based on headerlines from the statistics files
for i = 1:size(xdata.dat.stat,1)
    structname{i} = lower(strrep(xdata.dat.stat{i},'=', ''));   % remove special characters from headerlines and make lower case
    xdata.dat.(structname{i}) = A(i:s:c*s*r);                   % insert data
end

clear A;

for j = 1:size(xdata.dat.stat,1)                                % format data
    xdata.dat.(structname{j}) = reshape(xdata.dat.(structname{j}),c,r);
    xdata.dat.(structname{j}) = transpose(xdata.dat.(structname{j}));
end

xdata.dat.description = 'Not defined';

% Assigning data to the selected variable name
switch var_no
    case 'dat1'
        data.dat1 = xdata.dat;
    case 'dat2' 
        data.dat2 = xdata.dat;
    case 'dat3' 
        data.dat3 = xdata.dat;
    case 'dat4' 
        data.dat4 = xdata.dat;
    case 'dat5' 
        data.dat5 = xdata.dat;
    case 'dat6' 
        data.dat6 = xdata.dat;
    case 'dat7' 
        data.dat7 = xdata.dat;
    case 'dat8' 
        data.dat8 = xdata.dat;
    case 'dat9' 
        data.dat9 = xdata.dat;
    case 'dat10' 
        data.dat10 = xdata.dat;
    case 'dat23' 
        data.dat23 = xdata.dat;
    case 'dat24' 
        data.dat24 = xdata.dat;
    case 'dat25' 
        data.dat25 = xdata.dat;
    case 'dat26' 
        data.dat26 = xdata.dat;
end    

fprintf('\nData from Dat_Path loaded successfully\n');

% Cleaning unnecessary variables
    clear xdata;
    clear extension;
    clear var_no;
    clear r;
    clear c;
    clear s;
    clear fi;
    clear dummy;
    clear i;
    clear j;
    clear meas_type;
    clear ans count fid;
