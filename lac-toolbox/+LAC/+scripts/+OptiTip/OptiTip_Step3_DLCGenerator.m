%% Settings
run('OptiTip_Configuration.m');

% -- check that this part is to be executed
if(OTC.Steps(3)==0)
    fprintf('This step was disabled in configuration. Check OTC.Steps variable.\n');
    fprintf('Configuration defines the following steps to be executed:\n');
    for i=1:length(OTC.Steps)
        fprintf('\tStep %d: ',i);
        if(OTC.Steps(i)==0)
            fprintf('skip\n');
        else
            fprintf('execute\n');
        end
    end
    error('This step was disabled in configuration. Check OTC.Steps variable.');
end

%% ==== MAIN PART 
% ---------------------------
% --- read in Lambda Opt
% ---------------------------
fprintf('Reading LambdaOpt from previous step...\n');
found = 0;
if(OTC.Steps(1)==1)% if first step was set in configuration
    fileID = fopen(OTC.Step_1.OTCfile,'r');    
    while (~feof(fileID) && found==0)
        curr_string = fgetl(fileID);
        if(~isempty(strfind(curr_string,'OptiLambda:')))
            OTC.Step_3.OptiLambda=str2double(extractAfter(curr_string,':'));
            found=1;
        end
    end
    fclose(fileID);
else% if first step was NOT set in configuration
    OTC.Step_3.OptiLambda = Ref.OptiLambda;
    found = 1;
end
if(found==0)
    error('Was not able to locate LambdaOpt');
else
   fprintf('OK\n'); 
end
% ---------------------------
% --- Extract starting OTC parameters (Step 2)
% ---------------------------
fprintf('Reading OTC settings\n');
if(OTC.Steps(1)==1 || OTC.Steps(2)==1)% if first or second step was set in configuration
    if(OTC.Steps(1)==1)
        TimeInStall.OTCfile = fullfile(pwd,OTC.Step_1.OTCfile);
    end
    if(OTC.Steps(2)==1) % --- override
        TimeInStall.OTCfile = fullfile(pwd,OTC.Step_2.OTCfile);
    end
    fprintf('\tReading: %s\n',TimeInStall.OTCfile);
    % --- self check
    if ~(exist(TimeInStall.OTCfile)==2)
        error('Failed to find OTC file. Make sure you executed optimization for step 1 or 2.')
    end
    fileID = fopen(TimeInStall.OTCfile,'r');
    TimeInStall.OTC={};
    found=0;
    while ~feof(fileID)
        curr_string = fgetl(fileID);
        if(~isempty(strfind(curr_string,'Px_OTC_TableLambdaToPitchOpt')))
            TimeInStall.OTC{end+1,1} = curr_string;
            found = 1;
        end
    end
    fclose(fileID);
    if(found==0)
        error('Was not able to locate OptiTip Px_OTC_TableLambdaToPitchOpt parameters.');
    end
    % --- split on X and Y
    fprintf('\tExtracting OTC parameters.\n');
    TimeInStall.OTC_X={};
    TimeInStall.OTC_Y={};
    for i=1:length(TimeInStall.OTC)
        if(~isempty(strfind(TimeInStall.OTC{i,1},'Px_OTC_TableLambdaToPitchOptX')))
            TimeInStall.OTC_X{end+1,1} = TimeInStall.OTC{i,1};
        elseif(~isempty(strfind(TimeInStall.OTC{i,1},'Px_OTC_TableLambdaToPitchOptY')))
            TimeInStall.OTC_Y{end+1,1} = TimeInStall.OTC{i,1};
        end
    end
    % --- self-check
    if(length(TimeInStall.OTC_X)~=length(TimeInStall.OTC_Y))
        error('Extracted OTC parameters have different length in X and Y.');
    end
    % --- extract values
    TimeInStall.lambda=[];
    TimeInStall.pitch=[];
    for i=1:length(TimeInStall.OTC_X)
        TimeInStall.lambda(1,end+1)=str2double(extractAfter(TimeInStall.OTC_X{i,1},'='));
        TimeInStall.pitch(1,end+1)=str2double(extractAfter(TimeInStall.OTC_Y{i,1},'='));
    end
else% if first or second step was NOT set in configuration
    TimeInStall.lambda = Ref.OptiTip.TSR;
    TimeInStall.pitch = Ref.OptiTip.Pitch;
end
% fprintf('\tExtracted the following OTC:\n');
% TimeInStall.lambda
% TimeInStall.pitch
fprintf('OK\n'); 

% %% Set up pitch variation range
% pitch_range = eval(TimeInStall.pitch_range);


%% Prepare simulations part (VLLEB)
fprintf('Preparing simulation...\n');
% ---------------------------
% --- Set-up computation dirs
% ---------------------------
% TimeInStall.dir{1} = '3_Time_in_Stall_TEST';
% sim_dir = fullfile(pwd,TimeInStall.dir{1});
% TimeInStall.dir{1}=sim_dir;
fprintf('\tSetting up directories:\n');
TimeInStall.dir{1}=fullfile(pwd,OTC.Step_3.dir);
fprintf('\t\tCreating: %s\n',TimeInStall.dir{1});
mkdir(TimeInStall.dir{1})
for i=1:length(OTC.Step_3.pitch_range)
%     TimeInStall.sim_dir{i} = fullfile(TimeInStall.dir{1},sprintf('%03d',i));
    fprintf('\t\tCreating: %s\n',TimeInStall.sim_dir{i});
    mkdir(TimeInStall.sim_dir{i})
end
fprintf('\tOK\n');
% ---------------------------
% --- Initialize prep creation (DLC 11 only)
% ---------------------------
prep=LAC.vts.convert(prepTemplate, 'REFMODEL');
[folder, prepfile, postfix] = fileparts(prepTemplate);
% ---------------------------
% --- Read in BLD and add AoA sensors
% ---------------------------
fprintf('\tGenerating blade file\n');
if exist(prep.Files('BLD'), 'file')
    bld_read = prep.Files('BLD');
    [filepath,name,ext] = fileparts(prep.Files('BLD'));
    bld_file = fullfile(TimeInStall.dir{1}, [name,ext]);
elseif exist(fullfile(prep.PartsFolder,'BLD',prep.Files('BLD')), 'file')
    bld_read = fullfile(prep.PartsFolder,'BLD',prep.Files('BLD'));
    bld_file = fullfile(TimeInStall.dir{1}, prep.Files('BLD'));
else
    error('Was not able to localize BLD file.');
end
bld=LAC.vts.convert(bld_read, 'BLD');
% -- remove all out and insert AoA instead
for i=1:length(bld.SectionTable.Out)
    bld.SectionTable.Out{i} = '0 aoa';
end
fprintf('\t\tSaving: %s\n',bld_file)
bld.encode(bld_file);
fprintf('\tOK\n');
% ---------------------------
% --- Continue prep creation 
% ---------------------------
fprintf('\tPreparing prep file:\n');
% - change BLD
prep.Files('BLD') = bld_file;
% - find DLCs 11
start_LC= -99;
end_LC = -99;
for i=1:length(prep.LoadCaseNames)
    if(prep.LoadCaseNames{i}(1:2)=='11')
        if(start_LC==-99)
            start_LC=i;
        end
        end_LC=i;
    end
end
if (start_LC==-99 || end_LC==-99 )
    error('Failed to find DLC 11 in prep template');
end
% - replace DLCs
loadcases={};
for i=start_LC:1:end_LC
    loadcases{(i-1)*3+1} = sprintf('\n%s',prep.LoadCases{1,i}{1,1});
    loadcases{(i-1)*3+2} = sprintf('%s',prep.LoadCases{1,i}{1,2});
    loadcases{(i-1)*3+3} = sprintf('%s',prep.LoadCases{1,i}{1,3});
end
prep.comments = sprintf('%s \n',loadcases{:});
% --- store prep file
prep_file =  fullfile(TimeInStall.dir{1},[prepfile,'_DLC11',postfix]);
fprintf('\t\tSaving: %s\n',prep_file)
prep.encode(prep_file);
fprintf('\tOK\n');
% ---------------------------
% --- Copy over prep files
% ---------------------------
for i=1:length(TimeInStall.sim_dir)
    status = copyfile(prep_file,TimeInStall.sim_dir{i});
    if(status == 1)
%         fprintf('\tOK\n');
    else
        error('Failed to copy prep file');
    end
end
% ---------------------------
% --- Create CtrlParamChanges
% ---------------------------
fprintf('\tGenerating CtrlParamChanges files\n');
if (exist(fullfile(folder,'_CtrlParamChanges.txt'),'file')==2)
    fprintf('\t\tCtrlParamChanges file exists\n');
    TimeInStall.CTRLfile = LAC.vts.convert(fullfile(folder,'_CtrlParamChanges.txt'), 'AuxParameterFile');
    % --- remove old OTC, LambdaOpt, and VTL_enable
    nParam = length(TimeInStall.CTRLfile.parameters);
    remove_id=[];
    k=0;
    for i=1:nParam
        if(~isempty(strfind(TimeInStall.CTRLfile.parameters{i},'Px_OTC_TableLambdaToPitchOpt')))
            k=k+1;
            remove_id(k)=i;
        end
        if(~isempty(strfind(TimeInStall.CTRLfile.parameters{i},'Px_SC_PartLoadLambdaOpt')))
            k=k+1;
            remove_id(k)=i;
        end
        if(~isempty(strfind(TimeInStall.CTRLfile.parameters{i},'Px_TL_Enable')))
            k=k+1;
            remove_id(k)=i;
        end
    end
    TimeInStall.CTRLfile.parameters(remove_id)=[];
    TimeInStall.CTRLfile.values(remove_id)=[];
    TimeInStall.CTRLfile.units(remove_id)=[];
    TimeInStall.CTRLfile.scaledvalues(remove_id)=[];
    TimeInStall.CTRLfile.scaleexpressions(remove_id)=[];
    TimeInStall.CTRLfile.scaleexpressions_inv(remove_id)=[];
    TimeInStall.CTRLfile.unitstring(remove_id)=[];
    TimeInStall.CTRLfile.historyChanges(remove_id)=[];
else
    fprintf('>>> ==============================================================         <<<\n');
    fprintf('>>> ====================  W A R N I N G  =========================         <<<\n');
    fprintf('>>> ==============================================================         <<<\n');
    fprintf('>>> _CtrlParamChanges.txt was not found!!!                                 <<<\n');
    fprintf('>>> The code will generate one for you with OTC settings ONLY!!!           <<<\n');
    fprintf('>>> If you have other settings to be included, make sure that your current <<<\n');
    fprintf('>>> _CtrlParamChanges.txt file is located next to your prep template file. <<<\n');
    fprintf('>>> ==============================================================         <<<\n');
    TimeInStall.CTRLfile = LAC.vts.codec.AuxParameterFile;
%     error('_CtrlParamChanges.txt was not found');    
end
%%
% ---------------------------
% --- Loop over directories and save CTRL file
% ---------------------------
% TEST = LAC.vts.convert(fullfile(pwd,'_CtrlParamChanges.txt'), 'AuxParameterFile');
CTRLlocal = LAC.vts.codec.AuxParameterFile;
for i=1:length(TimeInStall.sim_dir)
    CTRLlocal.parameters =  TimeInStall.CTRLfile.parameters;
    CTRLlocal.values = TimeInStall.CTRLfile.values;
    CTRLlocal.units = TimeInStall.CTRLfile.units;
    CTRLlocal.scaledvalues = TimeInStall.CTRLfile.scaledvalues;
    CTRLlocal.scaleexpressions = TimeInStall.CTRLfile.scaleexpressions;
    CTRLlocal.scaleexpressions_inv = TimeInStall.CTRLfile.scaleexpressions_inv;
    CTRLlocal.unitstring = TimeInStall.CTRLfile.unitstring;
    CTRLlocal.historyChanges = TimeInStall.CTRLfile.historyChanges;
    % --- add OTC
    for j=1:length(TimeInStall.OTC_X)
        % --- OTC X
        CTRLlocal.parameters{end+1} = sprintf('Px_OTC_TableLambdaToPitchOptX%02d',j);
        CTRLlocal.values(end+1)=TimeInStall.lambda(1,j);
        CTRLlocal.scaledvalues{end+1}=sprintf('%2.2f',TimeInStall.lambda(1,j));
        CTRLlocal.units{end+1}=[];
        CTRLlocal.scaleexpressions{end+1}=[];
        CTRLlocal.scaleexpressions_inv{end+1}=[];
        CTRLlocal.unitstring{end+1}=[];
        CTRLlocal.historyChanges{end+1}=[]';
    end
    for j=1:length(TimeInStall.OTC_Y)
        % --- OTC Y
        CTRLlocal.parameters{end+1} = sprintf('Px_OTC_TableLambdaToPitchOptY%02d',j);
        CTRLlocal.values(end+1)=TimeInStall.pitch(1,j) + OTC.Step_3.pitch_range(i);
        CTRLlocal.scaledvalues{end+1}=sprintf('%2.2f',TimeInStall.pitch(1,j) + OTC.Step_3.pitch_range(i));
        CTRLlocal.units{end+1}=[];
        CTRLlocal.scaleexpressions{end+1}=[];
        CTRLlocal.scaleexpressions_inv{end+1}=[];
        CTRLlocal.unitstring{end+1}=[];
        CTRLlocal.historyChanges{end+1}=[];        
    end
    % --- OptiLambda
    CTRLlocal.parameters{end+1} = 'Px_SC_PartLoadLambdaOpt';
    CTRLlocal.values(end+1)=OTC.Step_3.OptiLambda;
    CTRLlocal.scaledvalues{end+1}=sprintf('%2.2f',OTC.Step_3.OptiLambda);
    CTRLlocal.units{end+1}=[];
    CTRLlocal.scaleexpressions{end+1}=[];
    CTRLlocal.scaleexpressions_inv{end+1}=[];
    CTRLlocal.unitstring{end+1}=[];
    CTRLlocal.historyChanges{end+1}=[];
    % --- VLT disable
    CTRLlocal.parameters{end+1} = 'Px_TL_Enable';
    CTRLlocal.values(end+1)=0;
    CTRLlocal.scaledvalues{end+1}='0';
    CTRLlocal.units{end+1}=[];
    CTRLlocal.scaleexpressions{end+1}=[];
    CTRLlocal.scaleexpressions_inv{end+1}=[];
    CTRLlocal.unitstring{end+1}=[];
    CTRLlocal.historyChanges{end+1}=[];
    % --- save new CTRL
    CTRL_file =  fullfile(TimeInStall.sim_dir{i},'_CtrlParamChanges.txt');
    fprintf('\t\tSaving: %s\n',CTRL_file)
    CTRLlocal.encode(CTRL_file);       
end
fprintf('\tOK\n');
fprintf('OK\n');
% ---------------------------
% --- Create FAT1 bat file
% ---------------------------
%%
fprintf('Writing Quickstart for FAT1\n');
fat1 = fullfile(TimeInStall.dir{1},'Quickstart_FAT1.bat');
fid = fopen(fat1,'w');
fprintf(fid,'%s','FAT1 -priority 5 -loads -u -p ');
for i=1:length(TimeInStall.sim_dir)
    prep_local = fullfile(TimeInStall.sim_dir{i},[prepfile,'_DLC11',postfix]);
    fprintf(fid,'%s ',prep_local);
end
fclose(fid);
fprintf('OK\n');
fprintf('\nSetup done, doubleclick the Quickstart_FAT1.bat file\n')


