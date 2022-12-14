function EditPowerCurveSetFile(prepfilePath)
%--------------------------------------------------------------------------
% This script will append ' Vhub XX -2000 -1800 Vhub YY -1300 -1000' to the
% end of the load case definition in the .set file, where XX is Vrat -2 and YY is the
% load case wind speed.
% First, prep the power curve runs and then run this function to update the .set files.
% Do not then reprep.

%INPUTS
% prepfilePath: path to the relevant prepfile 
% PCSettings: specify whether the power curve is normal or climate. If
% climate provide also Iref, Slope and Rho information. E.g.
% Normal\Rho1.325 or Climate\Iref0.14_Vexp0.2_Slope8_Rho1.325
%OUTPUTS
% renamed set file to _original
% updated set file with increased initialization time

% James Lamyman 2021
%--------------------------------------------------------------------------

%CALC START
last_slash = find(prepfilePath == '\', 1, 'last');
folder = prepfilePath(1:last_slash); %folder of prep file and runs
CCOEnFolders = dir([folder,'*CCOEn*']); %selecting subfolders where set file is to be altered
append_anyway = 'Y';

% Find PC settings
D = dir([CCOEnFolders(1).folder,'\',CCOEnFolders(1).name,'\PC\']);

% Normal or Climate?
for aa = 1:length(D)
    if startsWith(D(aa).name, 'Normal')
        PCSettings = 'Normal\';
        Dd = dir([CCOEnFolders(1).folder,'\',CCOEnFolders(1).name,'\PC\',PCSettings]);
        for bb = 1:length(Dd)
           if startsWith(Dd(bb).name,'Rho')
               PCSettings = [PCSettings Dd(bb).name];
           end
        end
    elseif startsWith(D(aa).name, 'Climate')
        PCSettings = 'Climate\';
        Dd = dir([CCOEnFolders(1).folder,'\',CCOEnFolders(1).name,'\PC\',PCSettings]);
        for bb = 1:length(Dd)
           if startsWith(Dd(bb).name,'Iref')
               PCSettings = [PCSettings Dd(bb).name];
           end
        end
    end
end
for Folder=1:length(CCOEnFolders)
%Getting name of set file
Prep_name = char(extractBefore(prepfilePath(last_slash+1:length(prepfilePath)),'.txt'));
New_Set_Name = [Prep_name,'.set'];   
% setfile=[CCOEnFolders(Folder).folder,'\',CCOEnFolders(Folder).name,'\PC\Normal\Rho1.325\INPUTS\',New_Set_Name]; %setfile
setfile=[CCOEnFolders(Folder).folder,'\',CCOEnFolders(Folder).name,'\PC\',PCSettings,'\INPUTS\',New_Set_Name]; %setfile


LoadCases = {'94'};    %List specific Load Cases or 'All', 94 for set file.
Row = 1; %How many rows down from first row of load case, 0 is the first row, use 1 for set file.

%CALCS

fileID = fopen(prepfilePath,'r');
PrepText = textscan(fileID,'%s','delimiter','\n');
PrepText = PrepText{:};
fclose(fileID);
n = size(PrepText);

fileID_Set = fopen(setfile,'r');
SetText = textscan(fileID_Set,'%s','delimiter','\n');
SetText = SetText{:};
fclose(fileID_Set);
n_Set = size(SetText);

%saving copy of orignal
orig = extractBefore(setfile,'.set');
original_set = strcat(orig,'_original.set');
fid = fopen(original_set, 'w');
fprintf(fid,'%s\r\n',SetText{:});

%Applying to load cases (always 94 for set file)
All_LoadCases = {'11', '12', '13', '14', '15', '21', '22', '23', '24', '31', '32', '33', '34','41', '42', '43', '51', '61', '62', '63', '64', '71', '82', '98', '99'}; 

if strcmp(LoadCases,'All')
    LoadCases = All_LoadCases;
end

%Find Vrat
for ii = 1:n(1)
    if contains(PrepText(ii),'Vr-2')
        Vrat_2_text = PrepText(ii);
        Vrat_2 = extractAfter(Vrat_2_text, 'Vr-2');
        if ~isempty(strfind(Vrat_2,'Rated'))
            Vrat_2 = extractBefore(Vrat_2, 'Rated');
        end
        Vrat_2 = strip(Vrat_2);
        fprintf('\nIn Prepfile, Vrat-2 = %s m/s\n', Vrat_2);
        break
    elseif ii>100
        disp('Could not find Vrated in prep file text')
        break
    end
end

%Find start point for load cases
linenumber = 1;
for ii = 1:n_Set(1)
    if startsWith(SetText(ii),'LC file')
        linenumber = ii+1;
        break
    end
end

%Check if text has already been altered
%Counter so that warning only appears once
Vhub_present = 0;

for ii = linenumber:n_Set(1)
    if startsWith(SetText(ii),LoadCases)
        % check if text has already been altered
        if contains(SetText(ii+Row),'Vhub') && Vhub_present < 1
            Vhub_present = Vhub_present + 1;
            fprintf('\nWarning, some lines in set file in: %s, already have Vhub text appended.\n', CCOEnFolders(Folder).name)
            fprintf('Row %d contains: %s. \n It is recommended you check the whole set file for other occourances.', ii, string(SetText(ii+Row)))
            append_anyway = input('\n\nDo you want to append next Vhub text anyway? (Y/N):','s');
            if append_anyway == 'N'
                break
            end
        end
    end
end

if append_anyway == 'N'
    %do nothing
else
   %Applying changes to lines
    Text_to_append = ' Vhub XX -2000 -1800 Vhub YY -1300 -1000';
    for ii = linenumber:n_Set(1)
        if startsWith(SetText(ii),LoadCases)
            % add section checking if its above v rated (above Vrat_2+1)
            Vhub = extractAfter(SetText(ii),'Vhfree_');
            %Vhub = extractAfter(Vhub,' ');
            Vhub = extractBefore(Vhub,'_');

            Vhub_num = str2double(Vhub);
            Vrat_2_num = str2double(Vrat_2);
            Vrat_1_num = Vrat_2_num + 1;
            if Vhub_num > Vrat_1_num


            disp('Editing Load Case')
            disp(string(SetText(ii)))
            Text_to_append_now = strrep(Text_to_append,'XX',Vrat_2);
            Text_to_append_now = strrep(Text_to_append_now,'YY',Vhub);
            disp(Text_to_append_now)
            SetText(ii+Row) = strcat(SetText(ii+Row), Text_to_append_now);
            end
        end
    end

    %saving set file in the folder it came from with the same name

    fid = fopen(setfile,'w');           % Open the new file
    Set = SetText.';
    fprintf(fid,'%s\r\n',Set{:});
    fclose(fid); 
end

end
