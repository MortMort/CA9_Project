function PresentTurbineConcept = LastUsedTurbConfig(GenInfo, UserSettings);
% LASTUSEDTURBCONFIGS
% Internal function for VDAT:

% Applies only to V80 Turbines, 5000 series
% This function is provoked when Configuration->Files->V80TurnineConcept(*.vdf)->ALWAYS ASK
% (i)  Questions the user whether/not he want to have the 'Last used' turbine concept
% (ii) Logs the Turbine Concept, configured by User, to a text file :- '\Configuration\LastUsedTurbConfigs.txt'
%
% Inputs:
%         GenInfo      : Struct array with general information from file. 
%                        Use 'readvdf.m' to obtain this
%         UserSettings : Struct with user settings
%
%  Outputs:
%          PresentTurbineConcept : Turbine Concept for the current turbine(VCS/VRCC)
%
%  Example: PresentTurbineConcept = LastUsedTurbConfig(GenInfo, UserSettings)
%
%  See also:
%           
%
%   Vestas Wind Systems A/S
%   RABAD	24th of September 2007

PresentTurbineConcept=[];
LastUsedTurbConfigs.Type=[]; LastUsedTurbConfigs.No=[]; LastUsedTurbConfigs.Concept=[]; % Initialise the variable to NULL

file = ['private\LastUsedTurbConfigs.txt'];

% Load Last Configured Turbine Concepts from \Configuration\LastUsedTurbConfigs.txt
% Load the HEADER
fid = fopen(file, 'r');
data_header=deblank(fgets(fid));
fclose(fid);

% ISSUE ERROR WHEN NO HEADER EXISTS IN \Configuration\LastUsedTurbConfigs.txt 
if ~isempty(data_header)
    SpacesIx = find(isspace(data_header)==1);
    FirstData = data_header(1:SpacesIx(1)-1);
end
if isempty(data_header) | ~isempty(str2num(FirstData))
    s1 = ['Header info is missing in the file:- ' file];
    s2 = ' ';
    s3 = 'Please add Header info to the file and return to VDAT.';
    s = strvcat(s1,s2,s3);
    errordlg(s,'File Error','modal');
    return;
end

% ISSUE ERROR WHEN NO EXACTLY 3 DATA FIELDS EXIST IN \Configuration\LastUsedTurbConfigs.txt
NoOfFields = sum(isspace(data_header))+1; % No. of data fields identified 
if NoOfFields>3
    s1 = ['The file:- ' file ' contains more than 3 fields.'];
    s2 = ' ';
    s3 = 'Only the fields: Turbine - ''TYPE'', ''NUMBER'', ''CONCEPT'' are allowed.';
    s4 = ' ';
    s5 = 'Please REMOVE the extra fields from the file header and return to VDAT.';
    s = strvcat(s1,s2,s3,s4,s5);
    errordlg(s,'File Error','modal');
    return;
elseif NoOfFields<3
    s1 = ['The file:- ' file ' is missing some data fields.'];
    s2 = ' ';
    s3 = 'The fields: Turbine - ''TYPE'', ''NUMBER'', ''CONCEPT'' are required.';
    s4 = ' ';
    s5 = 'Please ADD the missing fields to the file header and return to VDAT.';
    s = strvcat(s1,s2,s3,s4,s5);
    errordlg(s,'File Error','modal');
    return;
end

% Load HEADER and DATA 
fid = fopen(file, 'r');
data_header = textscan(fid, '%s %s %s', 1); % header
data = textscan(fid, '%d %d %s');           % Data
fclose(fid);

% save the data in a structure
LastUsedTurbConfigs.Type = data{1};
LastUsedTurbConfigs.No = data{2};
LastUsedTurbConfigs.Concept = data{3};
clear data

if isempty( intersect(GenInfo.TurbineNo,LastUsedTurbConfigs.No) )           % if Current turbine number is NOT pre-configured
    
    % ask user to tell the turbine concept
    s1 = 'Turbine Concept : ';
    s2 = ' ';
    s = strvcat(s1,s2);
    PresentTurbineConcept = questdlg(s,'VDAT question','VCS','VRCC','VCS');    % default is 'VCS'
    
    LastUsedTurbConfigs.Type(end+1,1)=GenInfo.TurbineType;      
    LastUsedTurbConfigs.No(end+1,1)=GenInfo.TurbineNo;
    LastUsedTurbConfigs.Concept{end+1,1}=PresentTurbineConcept;   
    
    % save the turbine concept in LastUsedTurbConfigs.txt
    fid = fopen(file,'w+');  % Open file, or create new file, for reading and writing; discard existing contents, if any
    cr = char([13 10]); 	% carriage return + line feed
    fprintf(fid,'%s\t%s\t%s',char(data_header{1}),char(data_header{2}),char(data_header{3})); % Write the header info
    fprintf(fid,cr);
    % Write the Turbine Config data to file
    [Nt dummy]=size(LastUsedTurbConfigs.No);
    for i=1:Nt
        fprintf(fid,'%d\t%d\t%s',LastUsedTurbConfigs.Type(i,1),LastUsedTurbConfigs.No(i,1),LastUsedTurbConfigs.Concept{i,1}); 
        fprintf(fid,cr);
    end
    fclose(fid); 
       
else  % if the Turbine concept for Current turbine number IS ALREADY pre-configured
    
    [dummy1 dummy2 Ix] = intersect(GenInfo.TurbineNo,LastUsedTurbConfigs.No(:,1));   % Index of Turbine in LastUsedTurbConfigs.mat
    LastTurbConcept = char(LastUsedTurbConfigs.Concept(Ix,1));
    
    % ISSUE AN ERROR WHEN TURBINE CONCEPT IS NEITHER 'VCS' NOR 'VRCC'
    if isempty(strmatch(lower(LastTurbConcept),'vcs','exact')) & isempty(strmatch(lower(LastTurbConcept),'vrcc','exact'))
        s1 = ['LastUsed turbine Concept for this turbine is NEITHER ''VCS'' NOR ''VRCC''.'];
        s2 = ' ';
        s3 = ['Only ''VCS'' or ''VRCC'' could be the appropriate turbine concepts.'];
        s4 = ' ';
        s5 = ['Please open the file:- ' file ' and log on the right turbine concept.'];
        s = strvcat(s1,s2,s3,s4,s5);
        errordlg(s,'File Error','modal');
        return;
    end
    
    if strmatch('Always Ask',UserSettings.TurbineConfig,'exact')
        
        % Ask user Whether/Not to use the Last configured turbine concept
        s1 = 'Choose the turbine concept :';
        s2 = ' ';
        s3 = ['The concept specified last-time, for this turbine is: ' LastTurbConcept];
        s4 = ' ';
        s5 = 'IMPORTANT: Pressing the ENTER key always selects the default answer (in this case Last used), ';
        s6 = 'SPACEBAR selects the selected button, so ALWAYS USE SPACEBAR (or the mouse) to select buttons in VDAT. ';
        s7 = ' ';
        s8 = 'You can disable this warning in the GUIs Configuration menu Files=>V80 Turbine .... ';
        %s = strvcat(s1,s2,s3,s4,s5);
        s = strvcat(s1,s2,s3,s4,s5,s6,s7,s8);
        PresentTurbineConcept = questdlg(s,'VDAT question','Last used','VCS','VRCC','Last used');  % default is 'Last used'
        
        if isempty(strmatch(PresentTurbineConcept,'Last used'))  % User don't want Last configured turbine concept. He makes a new configuration.
            % Update the last used turbine concept with the new turbine concept in LastUsedTurbConfigs.mat
            LastUsedTurbConfigs.Type(Ix,1)=GenInfo.TurbineType;      
            LastUsedTurbConfigs.No(Ix,1)=GenInfo.TurbineNo;
            LastUsedTurbConfigs.Concept{Ix,1}=PresentTurbineConcept;
            
            % Update the Newly configured turbine concept in \private\LastUsedTurbConfigs.txt 
            fid = fopen(file,'w+');  % create a new file and open it
            cr = char([13 10]); 	% carriage return + line feed
            fprintf(fid,'%s\t%s\t%s',char(data_header{1}),char(data_header{2}),char(data_header{3})); % Write the header info
            fprintf(fid,cr);
            % Write the Configuration data in file
            [Nt dummy]=size(LastUsedTurbConfigs.No);
            for i=1:Nt
                fprintf(fid,'%d\t%d\t%s',LastUsedTurbConfigs.Type(i,1),LastUsedTurbConfigs.No(i,1),LastUsedTurbConfigs.Concept{i,1}); 
                fprintf(fid,cr);
            end
            fclose(fid); 
            else  % User responds with 'Last used' or shuts the question dlg box down using the x. So, get the Turbine concept from LastUsedTurbConfigs.mat          
                PresentTurbineConcept = LastTurbConcept;
        end
        
        elseif strmatch('Only ask if not pre-configured',UserSettings.TurbineConfig,'exact')
            PresentTurbineConcept = LastTurbConcept;
    end
    
end
