%% Settings
run('OptiTip_Configuration.m');

% -- check that this part is to be executed
if(OTC.Steps(1)==0 || OTC.Steps(2)==0 || OTC.Steps(3)==0 )
    fprintf('Not all of 3 steps were activated in configuration. Check OTC.Steps variable.\n');
    fprintf('Configuration defines the following steps to be executed:\n');
    for i=1:length(OTC.Steps)
        fprintf('\tStep %d: ',i);
        if(OTC.Steps(i)==0)
            fprintf('skip\n');
        else
            fprintf('execute\n');
        end
    end
    error('This script is designed for all 3 steps. It seems that you have skipped some. Check OTC.Steps variable.');
end
%% ==== MAIN PART 
% ---------------------------
% --- read in Lambda Opt
% ---------------------------
fprintf('Reading LambdaOpt...\n');
fileID = fopen(OTC.Step_1.OTCfile,'r');
found = 0;
while (~feof(fileID) && found==0)
    curr_string = fgetl(fileID);
    if(~isempty(strfind(curr_string,'OptiLambda:')))
       OptiLambda=str2double(extractAfter(curr_string,':'));
       found=1;
    end
end
fclose(fileID);
if(found==0)
    error('Was not able to locate LambdaOpt');
else
   fprintf('OK\n'); 
end
% ---------------------------
% --- Extract starting OTC parameters (Step 1)
% ---------------------------
fprintf('Reading OTC settings\n');
fprintf('\tReading: %s\n',fullfile(pwd,OTC.Step_1.OTCfile));
% --- self check
if ~(exist(fullfile(pwd,OTC.Step_1.OTCfile),'file'))
    error('Failed to find OTC file. Make sure you executed optimization for step 1.')
end
fileID = fopen(fullfile(pwd,OTC.Step_1.OTCfile),'r');
OTC.Step_1.OTC={};
found=0;
while ~feof(fileID)
    curr_string = fgetl(fileID);
    if(~isempty(strfind(curr_string,'Px_OTC_TableLambdaToPitchOpt')))
        OTC.Step_1.OTC{end+1,1} = curr_string;
        found = 1;
    end
end
fclose(fileID);
if(found==0)
    error('Was not able to locate OptiTip Px_OTC_TableLambdaToPitchOpt parameters.');
end
% --- split on X and Y
fprintf('\tExtracting OTC parameters.\n');
OTC.Step_1.OTC_X={};
OTC.Step_1.OTC_Y={};
for i=1:length(OTC.Step_1.OTC)
    if(~isempty(strfind(OTC.Step_1.OTC{i,1},'Px_OTC_TableLambdaToPitchOptX')))
        OTC.Step_1.OTC_X{end+1,1} = OTC.Step_1.OTC{i,1};
    elseif(~isempty(strfind(OTC.Step_1.OTC{i,1},'Px_OTC_TableLambdaToPitchOptY')))
        OTC.Step_1.OTC_Y{end+1,1} = OTC.Step_1.OTC{i,1};
    end
end
% --- self-check
if(length(OTC.Step_1.OTC_X)~=length(OTC.Step_1.OTC_Y))
    error('Extracted OTC parameters have different length in X and Y.');
end
% --- extract values
OTC.Step_1.lambda=[];
OTC.Step_1.pitch=[];
for i=1:length(OTC.Step_1.OTC_X)
    OTC.Step_1.lambda(1,end+1)=str2double(extractAfter(OTC.Step_1.OTC_X{i,1},'='));
    OTC.Step_1.pitch(1,end+1)=str2double(extractAfter(OTC.Step_1.OTC_Y{i,1},'='));
end
% ---------------------------
% --- Extract starting OTC parameters (Step 2)
% ---------------------------
fprintf('\tReading: %s\n',fullfile(pwd,OTC.Step_2.OTCfile));
% --- self check
if ~(exist(fullfile(pwd,OTC.Step_2.OTCfile),'file'))
    error('Failed to find OTC file. Make sure you executed optimization for step 2.')
end
fileID = fopen(fullfile(pwd,OTC.Step_2.OTCfile),'r');
OTC.Step_2.OTC={};
found=0;
while ~feof(fileID)
    curr_string = fgetl(fileID);
    if(~isempty(strfind(curr_string,'Px_OTC_TableLambdaToPitchOpt')))
        OTC.Step_2.OTC{end+1,1} = curr_string;
        found = 1;
    end
end
fclose(fileID);
if(found==0)
    error('Was not able to locate OptiTip Px_OTC_TableLambdaToPitchOpt parameters.');
end
% --- split on X and Y
fprintf('\tExtracting OTC parameters.\n');
OTC.Step_2.OTC_X={};
OTC.Step_2.OTC_Y={};
for i=1:length(OTC.Step_2.OTC)
    if(~isempty(strfind(OTC.Step_2.OTC{i,1},'Px_OTC_TableLambdaToPitchOptX')))
        OTC.Step_2.OTC_X{end+1,1} = OTC.Step_2.OTC{i,1};
    elseif(~isempty(strfind(OTC.Step_2.OTC{i,1},'Px_OTC_TableLambdaToPitchOptY')))
        OTC.Step_2.OTC_Y{end+1,1} = OTC.Step_2.OTC{i,1};
    end
end
% --- self-check
if(length(OTC.Step_2.OTC_X)~=length(OTC.Step_2.OTC_Y))
    error('Extracted OTC parameters have different length in X and Y.');
end
% --- extract values
OTC.Step_2.lambda=[];
OTC.Step_2.pitch=[];
for i=1:length(OTC.Step_2.OTC_X)
    OTC.Step_2.lambda(1,end+1)=str2double(extractAfter(OTC.Step_2.OTC_X{i,1},'='));
    OTC.Step_2.pitch(1,end+1)=str2double(extractAfter(OTC.Step_2.OTC_Y{i,1},'='));
end
% ---------------------------
% --- Extract starting OTC parameters (Step 3)
% ---------------------------
fprintf('\tReading: %s\n',fullfile(pwd,OTC.Step_3.OTCfile));
% --- self check
if ~(exist(fullfile(pwd,OTC.Step_3.OTCfile),'file'))
    error('Failed to find OTC file. Make sure you executed optimization for step 3.')
end
fileID = fopen(fullfile(pwd,OTC.Step_3.OTCfile),'r');
OTC.Step_3.OTC={};
found=0;
while ~feof(fileID)
    curr_string = fgetl(fileID);
    if(~isempty(strfind(curr_string,'Px_OTC_TableLambdaToPitchOpt')))
        OTC.Step_3.OTC{end+1,1} = curr_string;
        found = 1;
    end
end
fclose(fileID);
if(found==0)
    error('Was not able to locate OptiTip Px_OTC_TableLambdaToPitchOpt parameters.');
end
% --- split on X and Y
fprintf('\tExtracting OTC parameters.\n');
OTC.Step_3.OTC_X={};
OTC.Step_3.OTC_Y={};
for i=1:length(OTC.Step_3.OTC)
    if(~isempty(strfind(OTC.Step_3.OTC{i,1},'Px_OTC_TableLambdaToPitchOptX')))
        OTC.Step_3.OTC_X{end+1,1} = OTC.Step_3.OTC{i,1};
    elseif(~isempty(strfind(OTC.Step_3.OTC{i,1},'Px_OTC_TableLambdaToPitchOptY')))
        OTC.Step_3.OTC_Y{end+1,1} = OTC.Step_3.OTC{i,1};
    end
end
% --- self-check
if(length(OTC.Step_3.OTC_X)~=length(OTC.Step_3.OTC_Y))
    error('Extracted OTC parameters have different length in X and Y.');
end
% --- extract values
OTC.Step_3.lambda=[];
OTC.Step_3.pitch=[];
for i=1:length(OTC.Step_3.OTC_X)
    OTC.Step_3.lambda(1,end+1)=str2double(extractAfter(OTC.Step_3.OTC_X{i,1},'='));
    OTC.Step_3.pitch(1,end+1)=str2double(extractAfter(OTC.Step_3.OTC_Y{i,1},'='));
end
fprintf('OK\n');


%% Prepare simulations
fprintf('Preparing simulation...\n');
% ---------------------------
% --- Set-up computation dirs
% ---------------------------
dir = 'AEP';
main_dir = fullfile(pwd,dir);
sim_dir{1}= fullfile(pwd,dir,'OTC_1');
sim_dir{2}= fullfile(pwd,dir,'OTC_2');
sim_dir{3}= fullfile(pwd,dir,'OTC_3');
fprintf('\tSetting up directories:\n');
% ---- MAIN DIR
if(~exist(main_dir,'dir'))
    fprintf('\t\tCreating: %s\n',main_dir);
    mkdir(main_dir);
else
    fprintf('\t\tDirectory exists: %s\n',main_dir);
end
% --- sim dirs
for i=1:length(sim_dir)
    if(~exist(sim_dir{i},'dir'))
        fprintf('\t\tCreating: %s\n',sim_dir{i});
        mkdir(sim_dir{i});
    else
        fprintf('\t\tDirectory exists: %s\n',sim_dir{i});
    end
end
fprintf('\tOK\n');
% ---------------------------
% --- Copy over prep files
% ---------------------------
fprintf('\tPreparing prep file:\n');
[folder, prepfile, postfix] = fileparts(PC_prepTemplate);
% --- sim dirs
for i=1:length(sim_dir)
    fprintf('\t\tCreating: %s\n',fullfile(sim_dir{i},[prepfile,postfix]));
    status = copyfile(PC_prepTemplate,sim_dir{i});
    if(status == 1)
%         fprintf('\tOK\n');
    else
        error('Failed to copy prep file');
    end
end
fprintf('\tOK\n');
% ---------------------------
% --- Prepare CtrlParam files
% ---------------------------
fprintf('\tGenerating CtrlParamChanges files\n');
if (exist(fullfile(folder,'_CtrlParamChanges.txt'),'file')==2)
    fprintf('\t\tCtrlParamChanges file exists\n');
    CTRLfile = LAC.vts.convert(fullfile(folder,'_CtrlParamChanges.txt'), 'AuxParameterFile');
    % --- remove old OTC, LambdaOpt, and VTL_enable
    nParam = length(CTRLfile.parameters);
    remove_id=[];
    k=0;
    for i=1:nParam
        if(~isempty(strfind(CTRLfile.parameters{i},'Px_OTC_TableLambdaToPitchOpt')))
            k=k+1;
            remove_id(k)=i;
        end
        if(~isempty(strfind(CTRLfile.parameters{i},'Px_SC_PartLoadLambdaOpt')))
            k=k+1;
            remove_id(k)=i;
        end
        if(~isempty(strfind(CTRLfile.parameters{i},'Px_TL_Enable')))
            k=k+1;
            remove_id(k)=i;
        end
    end
    CTRLfile.parameters(remove_id)=[];
    CTRLfile.values(remove_id)=[];
    CTRLfile.units(remove_id)=[];
    CTRLfile.scaledvalues(remove_id)=[];
    CTRLfile.scaleexpressions(remove_id)=[];
    CTRLfile.scaleexpressions_inv(remove_id)=[];
    CTRLfile.unitstring(remove_id)=[];
    CTRLfile.historyChanges(remove_id)=[];
else
    fprintf('>>> ==============================================================         <<<\n');
    fprintf('>>> ====================  W A R N I N G  =========================         <<<\n');
    fprintf('>>> ==============================================================         <<<\n');
    fprintf('>>> _CtrlParamChanges.txt was not found!!!                                 <<<\n');
    fprintf('>>> The code will generate one for you with OTC settings ONLY!!!           <<<\n');
    fprintf('>>> If you have other settings to be included, make sure that your current <<<\n');
    fprintf('>>> _CtrlParamChanges.txt file is located next to your prep template file. <<<\n');
    fprintf('>>> ==============================================================         <<<\n');
    CTRLfile = LAC.vts.codec.AuxParameterFile;
%     error('_CtrlParamChanges.txt was not found');    
end
% ---------------------------
% --- Loop over directories and save CTRL file
% ---------------------------
CTRLlocal = LAC.vts.codec.AuxParameterFile;
for i=1:length(sim_dir)
    % --- select OTC to insert
    switch i
        case 1
            lambda_local = OTC.Step_1.lambda;
            pitch_local  = OTC.Step_1.pitch;
            OTC_X = OTC.Step_1.OTC_X;
            OTC_Y = OTC.Step_1.OTC_Y;
        case 2
            lambda_local = OTC.Step_2.lambda;
            pitch_local  = OTC.Step_2.pitch;
            OTC_X = OTC.Step_2.OTC_X;
            OTC_Y = OTC.Step_2.OTC_Y;
        case 3
            lambda_local = OTC.Step_3.lambda;
            pitch_local  = OTC.Step_3.pitch;
            OTC_X = OTC.Step_3.OTC_X;
            OTC_Y = OTC.Step_3.OTC_Y;
    end
    % --- copy over CtrlParams
    CTRLlocal.parameters =  CTRLfile.parameters;
    CTRLlocal.values = CTRLfile.values;
    CTRLlocal.units = CTRLfile.units;
    CTRLlocal.scaledvalues = CTRLfile.scaledvalues;
    CTRLlocal.scaleexpressions = CTRLfile.scaleexpressions;
    CTRLlocal.scaleexpressions_inv = CTRLfile.scaleexpressions_inv;
    CTRLlocal.unitstring = CTRLfile.unitstring;
    CTRLlocal.historyChanges = CTRLfile.historyChanges;
    % --- add OTC
    for j=1:length(OTC_X)
        % --- OTC X
        CTRLlocal.parameters{end+1} = sprintf('Px_OTC_TableLambdaToPitchOptX%02d',j);
        CTRLlocal.values(end+1)=lambda_local(1,j);
        CTRLlocal.scaledvalues{end+1}=sprintf('%2.2f',lambda_local(1,j));
        CTRLlocal.units{end+1}=[];
        CTRLlocal.scaleexpressions{end+1}=[];
        CTRLlocal.scaleexpressions_inv{end+1}=[];
        CTRLlocal.unitstring{end+1}=[];
        CTRLlocal.historyChanges{end+1}=[]';
    end
    for j=1:length(OTC_Y)
        % --- OTC Y
        CTRLlocal.parameters{end+1} = sprintf('Px_OTC_TableLambdaToPitchOptY%02d',j);
        CTRLlocal.values(end+1)=pitch_local(1,j);
        CTRLlocal.scaledvalues{end+1}=sprintf('%2.2f',pitch_local(1,j));
        CTRLlocal.units{end+1}=[];
        CTRLlocal.scaleexpressions{end+1}=[];
        CTRLlocal.scaleexpressions_inv{end+1}=[];
        CTRLlocal.unitstring{end+1}=[];
        CTRLlocal.historyChanges{end+1}=[];
    end
    % --- OptiLambda
    CTRLlocal.parameters{end+1} = 'Px_SC_PartLoadLambdaOpt';
    CTRLlocal.values(end+1)=OptiLambda;
    CTRLlocal.scaledvalues{end+1}=sprintf('%2.2f',OptiLambda);
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
    CTRL_file =  fullfile(sim_dir{i},'_CtrlParamChanges.txt');
    fprintf('\t\tSaving: %s\n',CTRL_file)
    CTRLlocal.encode(CTRL_file);       
end
fprintf('\tOK\n');
fprintf('OK\n');% report end of preparing simulation files
%%
% ---------------------------
% --- Create FAT1 bat file
% ---------------------------
fprintf('Writing Quickstart for FAT1\n');
fat1 = fullfile(main_dir,'Quickstart_FAT1.bat');
fid = fopen(fat1,'w');
% FAT1 -priority 5 -pc -u -p 
% FAT1 -priority -1 -loads -u -p 
fprintf(fid,'%s','FAT1 -priority 5 -pc -u -p ');
for i=1:length(sim_dir)
    prep_local = fullfile(sim_dir{i},[prepfile,postfix]);
    fprintf(fid,'%s ',prep_local);
end
fclose(fid);
fprintf('OK\n');
fprintf('\nSetup done, doubleclick the Quickstart_FAT1.bat file\n')





