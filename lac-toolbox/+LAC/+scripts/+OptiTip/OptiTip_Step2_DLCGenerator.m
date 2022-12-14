

%% Settings
run('OptiTip_Configuration.m');

%% ==== MAIN PART 
% -- check that this part is to be executed
if(OTC.Steps(2)==0)
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
% ---------------------------
% --- read in Lambda Opt
% ---------------------------
if(OTC.Steps(1)==1)% if previous step was set in configuration
    fprintf('Reading LambdaOpt from previous step...\n');
    fprintf('\tReading: %s\n',OTC.Step_1.OTCfile);
    fileID = fopen(OTC.Step_1.OTCfile,'r');
    found = 0;
    while (~feof(fileID) && found==0)
        curr_string = fgetl(fileID);
        if(~isempty(strfind(curr_string,'OptiLambda:')))
            OTC.Step_2.OptiLambda=str2double(extractAfter(curr_string,':'));
            found=1;
        end
    end
    fclose(fileID);
    if(found==0)
        error('Was not able to locate LambdaOpt');
    else
        fprintf('OK\n');
    end
end
% ---------------------------
% --- read in OTC parameters
% ---------------------------
if(OTC.Steps(1)==1)% if previous step was set in configuration
    fprintf('Reading OTC settings from previous step...\n');
    fprintf('\tReading: %s\n',OTC.Step_1.OTCfile);
    fileID = fopen(OTC.Step_1.OTCfile,'r');
    OTC.Step_2.OTC={};
    found = 0;
    while ~feof(fileID)
        curr_string = fgetl(fileID);
        if(~isempty(strfind(curr_string,'Px_OTC_TableLambdaToPitchOpt')))
            %         fprintf('\tfound: %s\n',curr_string)
            found = 1;
        end
        if(found)
            OTC.Step_2.OTC{end+1,1} =curr_string;
        end
    end
    fclose(fileID);
    if(found==0)
        error('Was not able to locate OptiTip controller strings');
    else
        fprintf('OK\n');
    end
    % --- remove last line
    tmp=OTC.Step_2.OTC;
    OTC.Step_2.OTC={};
    for i=1:(length(tmp)-1)
        OTC.Step_2.OTC{i,1}=tmp{i,1};
    end
    clear tmp;
    % --- split on X and Y
    fprintf('Extracting OTC parameters.\n');
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
end
% ---------------------------
% --- If previous step was disabled in configuration,
% --- use  Lambda and Pitch from configuration.
% ---------------------------
if(OTC.Steps(1)==0)
    OTC.Step_2.OptiLambda = Ref.OptiLambda;
    OTC.Step_2.lambda = Ref.OptiTip.TSR;
    OTC.Step_2.pitch = Ref.OptiTip.Pitch;
end
%% Prepare simulations 
fprintf('Preparing simulation...\n');
% ---------------------------
% --- Set-up computation dirs
% ---------------------------
sim_dir = fullfile(pwd,OTC.Step_2.dir);
fprintf('\tSetting up directories:\n');
fprintf('\t\tCreating: %s\n',sim_dir);
mkdir(sim_dir)
fprintf('\tOK\n');
% ---------------------------
% --- Copy over prep file
% ---------------------------
fprintf('\tPreparing prep file:\n');
[folder, prepfile, postfix] = fileparts(prepTemplate);
fprintf('\t\tCreating: %s\n',fullfile(sim_dir,[prepfile,postfix]));
status = copyfile(prepTemplate,sim_dir);
if(status == 1)
    fprintf('\tOK\n');
else
    error('Failed to copy prep file');    
end
% ---------------------------
% --- Create CtrlParamChanges
% ---------------------------
fprintf('\tGenerating CtrlParamChanges file\n');
if (exist(fullfile(folder,'_CtrlParamChanges.txt'),'file')==2)
    fprintf('\t\tCtrlParamChanges file exists\n');
    OTC.Step_2.CTRLfile = LAC.vts.convert(fullfile(folder,'_CtrlParamChanges.txt'), 'AuxParameterFile');
    % --- remove old OTC, LambdaOpt, FreewheelPosition, and VTL_enable
    nParam = length(OTC.Step_2.CTRLfile.parameters);
    remove_id=[];
    k=0;
    for i=1:nParam
        if(~isempty(strfind(OTC.Step_2.CTRLfile.parameters{i},'Px_OTC_TableLambdaToPitchOpt')))
            k=k+1;
            remove_id(k)=i;
        end
        if(~isempty(strfind(OTC.Step_2.CTRLfile.parameters{i},'Px_SC_PartLoadLambdaOpt')))
            k=k+1;
            remove_id(k)=i;
        end
%         if(~isempty(strfind(OTC.Step_2.CTRLfile.parameters{i},'Px_PSC_FreewheelPosition')))
%             k=k+1;
%             remove_id(k)=i;
%         end
        if(~isempty(strfind(OTC.Step_2.CTRLfile.parameters{i},'Px_TL_Enable')))
            k=k+1;
            remove_id(k)=i;
        end
    end
    OTC.Step_2.CTRLfile.parameters(remove_id)=[];
    OTC.Step_2.CTRLfile.values(remove_id)=[];
    OTC.Step_2.CTRLfile.units(remove_id)=[];
    OTC.Step_2.CTRLfile.scaledvalues(remove_id)=[];
    OTC.Step_2.CTRLfile.scaleexpressions(remove_id)=[];
    OTC.Step_2.CTRLfile.scaleexpressions_inv(remove_id)=[];
    OTC.Step_2.CTRLfile.unitstring(remove_id)=[];
    OTC.Step_2.CTRLfile.historyChanges(remove_id)=[];
else
    fprintf('>>> ==============================================================         <<<\n');
    fprintf('>>> ====================  W A R N I N G  =========================         <<<\n');
    fprintf('>>> ==============================================================         <<<\n');
    fprintf('>>> _CtrlParamChanges.txt was not found!!!                                 <<<\n');
    fprintf('>>> The code will generate one for you with OTC settings ONLY!!!           <<<\n');
    fprintf('>>> If you have other settings to be included, make sure that your current <<<\n');
    fprintf('>>> _CtrlParamChanges.txt file is located next to your prep template file. <<<\n');
    fprintf('>>> ==============================================================         <<<\n');
    OTC.Step_2.CTRLfile = LAC.vts.codec.AuxParameterFile;
%     error('_CtrlParamChanges.txt was not found');    
end
% --- include OTC from previous step
fprintf('\t\tInserting OTC from previous step\n');
for j=1:length(OTC.Step_2.OTC_X)
    % --- OTC X
    OTC.Step_2.CTRLfile.parameters{end+1} = sprintf('Px_OTC_TableLambdaToPitchOptX%02d',j);
    OTC.Step_2.CTRLfile.values(end+1)=OTC.Step_2.lambda(1,j);
    OTC.Step_2.CTRLfile.scaledvalues{end+1}=sprintf('%2.2f',OTC.Step_2.lambda(1,j));
    OTC.Step_2.CTRLfile.units{end+1}=[];
    OTC.Step_2.CTRLfile.scaleexpressions{end+1}=[];
    OTC.Step_2.CTRLfile.scaleexpressions_inv{end+1}=[];
    OTC.Step_2.CTRLfile.unitstring{end+1}=[];
    OTC.Step_2.CTRLfile.historyChanges{end+1}=[];
end
for j=1:length(OTC.Step_2.OTC_Y)
    % --- OTC Y
    OTC.Step_2.CTRLfile.parameters{end+1} = sprintf('Px_OTC_TableLambdaToPitchOptY%02d',j);
    OTC.Step_2.CTRLfile.values(end+1)=OTC.Step_2.pitch(1,j);
    OTC.Step_2.CTRLfile.scaledvalues{end+1}=sprintf('%2.2f',OTC.Step_2.pitch(1,j));
    OTC.Step_2.CTRLfile.units{end+1}=[];
    OTC.Step_2.CTRLfile.scaleexpressions{end+1}=[];
    OTC.Step_2.CTRLfile.scaleexpressions_inv{end+1}=[];
    OTC.Step_2.CTRLfile.unitstring{end+1}=[];
    OTC.Step_2.CTRLfile.historyChanges{end+1}=[];
end
fprintf('\t\tDisabling VTL\n');
% --- VLT disable
OTC.Step_2.CTRLfile.parameters{end+1} = 'Px_TL_Enable';
OTC.Step_2.CTRLfile.values(end+1)=0;
OTC.Step_2.CTRLfile.scaledvalues{end+1}='0';
OTC.Step_2.CTRLfile.units{end+1}=[];
OTC.Step_2.CTRLfile.scaleexpressions{end+1}=[];
OTC.Step_2.CTRLfile.scaleexpressions_inv{end+1}=[];
OTC.Step_2.CTRLfile.unitstring{end+1}=[];
OTC.Step_2.CTRLfile.historyChanges{end+1}=[];
% --- save new CTRL
CTRL_file =  fullfile(sim_dir,'_CtrlParamChanges.txt');
fprintf('\t\tSaving: %s\n',CTRL_file)
OTC.Step_2.CTRLfile.encode(CTRL_file);
fprintf('\tOK\n');
% fprintf('\tGenerating CtrlParamChanges file\n');
% if exist(fullfile(folder,'_CtrlParamChanges.txt'))==2
%     fprintf('\t\tCtrlParamChanges file exists\n');
%     fileID = fopen(fullfile(folder,'_CtrlParamChanges.txt'),'r');
%     CTRLfile={};
%     % --- read old Ctrl and remove old OTC and VTL on/off
%     fprintf('\t\tReading and removing OTC\n');
%     while ~feof(fileID)
%         curr_string = fgetl(fileID);
%         if(~isempty(strfind(curr_string,'Px_OTC_TableLambdaToPitchOpt')))
%             % - dont copy        
%         elseif(~isempty(strfind(curr_string,'Px_PSC_FreewheelPosition')))
%             % - dont copy            
%         elseif(~isempty(strfind(curr_string,'Px_SC_PartLoadLambdaOpt')))
%             % - dont copy            
%         elseif(~isempty(strfind(curr_string,'Px_TL_Enable')))
%             % - dont copy
%         else
%             CTRLfile{end+1,1} =fgetl(fileID);
%         end
%     end
%     % --- include OTC from previous step
%     fprintf('\t\tInserting OTC from previous step\n');
%     CTRLfile{end+1,1} = '';
%     CTRLfile{end+1,1} = '%% Below are modifications introduced by OTC LAC script';
%     CTRLfile{end+1,1} = ['%%Updated optilamba curve (',OTCfile,')'];
%     for i=1:length(OTC)        
%         CTRLfile{end+1,1} =OTC{i,1};
%     end
%     % --- disable VTL 
%     fprintf('\t\tDisabling VTL\n');
%     CTRLfile{end+1,1} = '';
%     CTRLfile{end+1,1} = 'Px_TL_Enable = 0;';
%     fclose(fileID);
%     fprintf('\t\tSaving: %s\n',fullfile(sim_dir,'_CtrlParamChanges.txt'))
%     fileID = fopen(fullfile(sim_dir,'_CtrlParamChanges.txt'),'w');
%     fprintf(fileID,'%s\n',CTRLfile{:});
%     fclose(fileID);
% else
%     fprintf('>>> _CtrlParamChanges.txt was not found. Make sure it is located next to your prep file! <<<\n');
%     error('_CtrlParamChanges.txt was not found');    
% end
% fprintf('\tOK\n');
% ---------------------------
% --- Create ParameterStudy
% ---------------------------
parameter_file = fullfile(sim_dir,'_ParameterStudy.txt');
fprintf('\tGenerating ParameterStudy file:\n');
fprintf('\t\tOutput: %s\n',parameter_file);
fileID = fopen(parameter_file,'w');fprintf(fileID,'%%Parameter study input file %s generated by Opti-Tip LAC script\n',datestr(now, 'yyyy-mm-dd'));

fprintf(fileID,'\n'); 
fprintf(fileID,'%%Parameter Definitions\n'); 
fprintf(fileID,['Par01->BLD:11:2= ',OTC.Step_2.pitch_range,'\n']); 
fprintf(fileID,'Par02->BLD:11:1=Par01+0.3\n'); 
fprintf(fileID,'Par03->BLD:11:3=Par01-0.3\n'); 
% fprintf(fileID,'Par05->Px_PSC_FreewheelPosition  = 10\n'); 
fprintf(fileID,['Par04->Px_SC_PartLoadLambdaOpt = ',sprintf('%2.2f',OTC.Step_2.OptiLambda),'\n']); 
fprintf(fileID,'\n'); 
fprintf(fileID,'%%Study Definitions\n'); 
% fprintf(fileID,'Study01->Par01~Par02~Par03#Par04~Par05\n');
fprintf(fileID,'Study01->Par01~Par02~Par03#Par04\n'); 
fclose(fileID);
fprintf('\tOK\n');

