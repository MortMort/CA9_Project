%% Settings
% ---- read in settings
run('OptiTip_Configuration.m');

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


%% ==== setup results dir
Path = [fullfile(pwd,OTC.Step_2.dir),'\'];% dir with parameter study (add slash at the end)
folder_mask = '01_*';% mask to read directories

Output_file = 'pc_parameter_results.mat';% output file with extracted variables

%% ====  Read in PC data and save to mat file if not done yet
% --- check  existance of mat file
if exist(fullfile(pwd,Output_file))==2
    fprintf('Power curve file was detected\n');
    fprintf('\tLoading file: %s\n',fullfile(pwd,Output_file));
    load(Output_file);
    fprintf('OK\n');
else % file does not exists -> read folders
    % --- find all folders
    fprintf('Looking for folders in specified path:\n');
    fprintf('\t%s\n',Path);
    folders = dir([Path, folder_mask]);
    nPC=size(folders,1);
    fprintf('\tDetected: %d directories\nOK\n',nPC);
    % --- self-check
    if(nPC<1)
        error('Too few directories detected. Make sure the path is correct and has slash at the end.');
    end
    % --- load PC data one by one
    fprintf('Starting to read folders from path: %s\n',Path);
    % for n=1:1
    for n=1:nPC
        fprintf('\tFolder (%d/%d): %s\n',n,nPC,folders(n).name);
        ipath  = fullfile(Path,folders(n).name,'PC','QuickPowerCurve','Rho1.225' );
        pcpath_struct = dir([ipath,'\pc*txt']);
        pcpath = [pcpath_struct.folder,'\',pcpath_struct.name];
        % --- check that file is there
        if(strcmp(pcpath,'\') || ~exist(pcpath)==2)
            error('failed to find pc file in dir: %s\\',ipath)        
        end
    %     fprintf('\tPC: %s\n',pcpath);
        % --- read file once
        A = importdata(pcpath,' ',1000);
        % --- locate data
        iPCstart = find(strcmp(A,'#POWER'))+6;
        iPCend   = find(strcmp(A,'#NOISE_EQS'))-2;
        iCTstart = find(strcmp(A,'#CT'))+6;
        iCTend   = find(strcmp(A,'#PITCH'))-2;
        iPitstart= find(strcmp(A,'#PITCH'))+6;
        iPitend  = find(strcmp(A,'#PITCH_STD'))-2;
        iRPMstart= find(strcmp(A,'#RPM'))+6;
        iRPMend  = find(strcmp(A,'#RPM_STD'))-2; 
        % --- self-check
        if (isempty(iPCstart) || isempty(iPCend) || isempty(iCTstart) || isempty(iCTend) || isempty(iPitstart) || isempty(iPitend) || isempty(iRPMstart) || isempty(iRPMend))
            error('Failed to find location of some parameters in PC file');
        end
        % --- extract data
        % - Wind speed and Power
        B=str2num(char(A(iPCstart:iPCend,1)));
        v(:,n)  = B(:,1);
        PC(:,n) = B(:,2);
        % - CT
        B=str2num(char(A(iCTstart:iCTend,1)));
        CT(:,n) = B(:,2);
        % - Pitch
        B=str2num(char(A(iPitstart:iPitend,1)));
        PITCH(:,n) = B(:,2);
        % - RPM
        B=str2num(char(A(iRPMstart:iRPMend,1)));
        RPM(:,n) = B(:,2);
    end
    fprintf('OK\n');
    % --- save computed variables to file
    fprintf('Storing output to:\n\t%s\n',[pwd,'\',Output_file]);
    save(Output_file, 'v','PC','CT','PITCH','RPM');
    fprintf('OK\n');
    % --- clean up
    fprintf('Cleaning workspace\n');
    clearvars iRPMstart iRPMend iPitstart iPitend iCTstart iCTend iPCstart iPCend A ipath pcpath_struct pcpath folders folder_mask;
    fprintf('OK\n');
end

%% OPTIMIZATION PART
% ---------------------------
% --- read in Lambda Opt
% ---------------------------
fprintf('Reading LambdaOpt from previous step...\n');
if(OTC.Steps(1)==1)% if previous step was set in configuration
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
else% if previous step was NOT set in configuration
    OTC.Step_2.OptiLambda = Ref.OptiLambda;    
end
% ---------------------------
% --- Extract starting OTC parameters
% ---------------------------
fprintf('Reading OTC settings from CtrlParamChanges\n');
CTRLfile = fullfile(Path,'_CtrlParamChanges.txt');
fprintf('\tReading: %s\n',CTRLfile);
% --- self check
if ~(exist(CTRLfile)==2)
    error('Failed to find _CtrlParamChanges.txt file.')
end
fileID = fopen(CTRLfile,'r');
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
       OTC.Step_2. OTC_X{end+1,1} = OTC.Step_2.OTC{i,1};
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
    if(isnan(OTC.Step_2.lambda(1,end)))
       OTC.Step_2.lambda(1,end) = str2double(extractBefore(extractAfter(OTC.Step_2.OTC_X{i,1},'='),';'));
       if(isnan(OTC.Step_2.lambda(1,end)) || isempty(OTC.Step_2.lambda(1,end)))
           error('Failed to convert OTC controller to values.');
       end
    end
    OTC.Step_2.pitch(1,end+1)=str2double(extractAfter(OTC.Step_2.OTC_Y{i,1},'='));
    if(isnan(OTC.Step_2.pitch(1,end)))
       OTC.Step_2.pitch(1,end) = str2double(extractBefore(extractAfter(OTC.Step_2.OTC_Y{i,1},'='),';'));
       if(isnan(OTC.Step_2.pitch(1,end)) || isempty(OTC.Step_2.pitch(1,end)))
           error('Failed to convert OTC controller to values.');
       end
    end
end
% fprintf('\tExtracted the following OTC:\n');
% lambda
% pitch
fprintf('OK\n'); 

%%
% ---------------------------
% --- OPTIMIZATION
% ---------------------------
fprintf('Starting optimization\n'); 
% ---- SETTINGS
Lambda_Opt = 0; % Px_SC_PartLoadLambdaOpt - Lambda for below rated WS. When set =/=0 it will take results only for this LambdaOpt. Set to 0 to use all simulated LambdaOpts.
fix_low_lambda = 1; % [0/1] set 0 to disable
% lambda_max = 8.5;% max lambda below which "starting point" opti-tip to be used
% --- convert pitch and lambda range to vectors
pitch_range = eval(OTC.Step_2.pitch_range);
lambda_range = OTC.Step_2.OptiLambda;
% ---  reduce v vector
v_tmp = v;
clear v;
v=v_tmp(:,1);
% --- allocate space
[nV, nPC]=size(PC);
% --- define variables
TargRPM=[];
TargPitch=[];
TargLAM=[];
TargP=[];
TargCt=[];
choice_record=[];
% ==============================
% ==============================
% create LAMBDA mat
for i=1:nV
    for j=1:nPC
        LAMBDA(i,j)=RPM(i,j)/OTC.GBXRatio/60*2*pi()/v(i)*OTC.Radius;
    end
end

PC_max = -1000;
for i= 1:nV
    Max_PC_wind = max(PC(i,:));
    for j=1:nPC
        tmp_lambda = LAMBDA(i,j);
        otc_pitch = interp1(OTC.Step_2.lambda,OTC.Step_2.pitch,tmp_lambda);
        [~,ind] = min(abs(PITCH(i,:)' - otc_pitch));
        INDEX(i,j)=ind;
%         if(i==16)
%             fprintf('break\n');
%         end
    end
end
% ==============================
% ==============================






% --- find only max power from all
LogMsg = {};
for i= 1:nV
     PC_Temp=PC(i,:);
%      % --- Limit LambdaOpt to chosen value
%      if (Lambda_Opt ~= 0)
%          fprintf('WS=%2.1f\tLimiting LambdaOpt to %2.1f\n',v(i),Lambda_Opt);
%          Lambda_sim_tmp =repmat(lambda_range,length(pitch_range),length(pitch_range));
%          Lambda_sim = Lambda_sim_tmp(1,:);
%          clear Lambda_sim_tmp;
%          j= (Lambda_Opt~=Lambda_sim);
%          % --- zero out other LambdaOpts
%          PC_Temp(j)=0;
%      end
%      % --- reduce CT
% %      j=Ct(i,:)>0.95;
% %      PC_Temp(j)=0;
%      j
     % ---
     j=find(PC_Temp==max(PC_Temp),1,'first');
     TargRPM(i,1)=RPM(i,j);
     TargLAM(i,1)=TargRPM(i,1)/OTC.GBXRatio/60*2*pi()/v(i)*OTC.Radius;
     TargPitch(i,1)=PITCH(i,j);
     TargP(i,1)=PC(i,j);     
     TargCt(i,1)=CT(i,j);
     %--- record below or above rated WS
     STEP_2.OK(i)=1;
     STEP_2.ID(i)=j;
     if(OTC.RatedWS <= v(i) )
         STEP_2.OK(i)=0;
         STEP_2.ID(i)=-999;
         if(exist('lambda_max','var')~=1)
             lambda_max = TargLAM(i,1);
             fprintf('\t------------------------------------------------------------------------------------------\n');
             fprintf('\tYou should not have any warning before that line. Otherwise your pitch range is too small.\n');
             fprintf('\tAt this stage rated wind speed is reached.\n');
             fprintf('\tThis step only aims to optmize below rated wind speed.\n');
             fprintf('\t------------------------------------------------------------------------------------------\n');
             LogMsg{end+1} = '------------------------------------------------------------------------------------------';
             LogMsg{end+1} = 'You should not have any warning before that line. Otherwise your pitch range is too small.';
             LogMsg{end+1} = 'At this stage rated wind speed is reached.';
             LogMsg{end+1} = 'This step only aims to optmize below rated wind speed.';
             LogMsg{end+1} = '------------------------------------------------------------------------------------------';
         end
     end
     % --- check if not limited by range
     fprintf('\tOptimum choice: i=%02d, Folder=%03d, WS=%1.2f, Pitch=%2.2f, Lambda=%1.2f, RPM=%1.2f, P=%1.0f',i, j-1,v(i),TargPitch(i,1),TargLAM(i,1),TargRPM(i,1),TargP(i,1));
     LogMsg{end+1} = sprintf('Optimum choice: i=%02d, Folder=%03d, WS=%1.2f, Pitch=%2.2f, Lambda=%1.2f, RPM=%1.2f, P=%1.0f',i, j-1,v(i),TargPitch(i,1),TargLAM(i,1),TargRPM(i,1),TargP(i,1));
     choice_record(i)=j;
     if(choice_record(i)<=length(lambda_range) || choice_record(i)>(length(lambda_range)*length(pitch_range)-length(lambda_range)) )
         fprintf('\tWARNING: choice is limited by pitch range.\n');
         LogMsg{end} = strcat(LogMsg{end},' WARNING: choice is limited by pitch range.');
     else
         fprintf('\n');         
     end
     % --- debug info
%      if (v(i)==6)
%          fprintf('DEBUG:\n');
%          fprintf('\ti=%d\tj=%d\n',i,j);
%          fprintf('\tWind speed: %f\n',v(i));
%          fprintf('\tFolder: %d\n',j-1);
%          fprintf('\tRMP: %f\n',TargRPM_2(i,1));
%          fprintf('\tLambda: %f\n',TargLAM_2(i,1));
%          fprintf('\tPower: %f\n',TargP_2(i,1));
%          fprintf('\tPitch: %f\n',TargPitch_2(i,1));
%          fprintf('\tCT: %f\n',TargCt_2(i,1));   
%      end
end
% % --- plot before interpolation
% figure
% hold on
% plot(lambda,pitch,'LineWidth',1);
% plot(TargLAM,TargPitch,'LineWidth',3);
% grid on
% xlabel('Lambda')
% ylabel('Pitch')
% legend('OTC Step 1','OTC Step 2')
% hold off

% %%% ---- make unique
[TargLAM,j_uniq] = unique(TargLAM);
TargPitch = TargPitch(j_uniq,1);
v_result = v(j_uniq,1);
% --- intepolate on given lambda
TargPitch_interp = interp1(TargLAM,TargPitch,OTC.Step_2.lambda,'pchip','extrap');
% --- fix interpolation for high lambdas
j=find(OTC.Step_2.lambda>max(TargLAM));
for i=j
    TargPitch_interp(1,i)=OTC.Step_2.pitch(1,i)+TargPitch_interp(1,i-1)-OTC.Step_2.pitch(1,i-1);
end
% --- fix low lambdas pitch (power controller is used instead of pitch for high wind)
if(fix_low_lambda~=0)
    j=find(lambda_max>OTC.Step_2.lambda);
    for i=j
        TargPitch_interp(1,i)=OTC.Step_2.pitch(1,i);
    end
end
% -------------------------------------
% --- PLOT ----------------------------
% -------------------------------------
% --- define legends
% if (Lambda_Opt == 0)
%     legend_1 = {'Initial','VTS no limit','Resulting','CT<0.80','CT<0.82','CT<0.84','CT<0.86','CT<0.95'};
%     legend_2 = {'VTS no limit','CT<0.80','CT<0.82','CT<0.84','CT<0.86','CT<0.95'};
% else    
%     legend_1 = {'Initial',['VTS LambdaOpt=',num2str(Lambda_Opt,'%2.1f\n')],'Resulting','CT<0.80','CT<0.82','CT<0.84','CT<0.86','CT<0.95'};
%     legend_2 = {['VTS LambdaOpt=',num2str(Lambda_Opt,'%2.1f\n')],'CT<0.80','CT<0.82','CT<0.84','CT<0.86','CT<0.95'};
% end
% ---
figure
hold on
plot(OTC.Step_2.lambda,OTC.Step_2.pitch,'LineWidth',1);
plot(TargLAM,TargPitch,'+-','LineWidth',2);
plot(OTC.Step_2.lambda,TargPitch_interp,'LineWidth',1,'color','k','LineWidth',2);
grid on
xlabel('Lambda')
ylabel('Pitch')
legend('OTC Step 1','VTS max power (PC based)','Resulting');
hold off
print(fullfile(pwd,'Step_2_OTC.png'),'-dpng','-r300')
saveas(gcf,fullfile(pwd,'Step_2_OTC.fig'));
% % --- plot power vs wind
% figure
% title('Power')
% hold on
% grid on
% plot(v,TargP,'LineWidth',2)
% xlabel('Wind Speed (m/s)')
% ylabel('Power')
% hold off

% %--- plot lambda vs wind
% figure
% title('Lambda')
% hold on
% grid on
% plot(v_result,TargLAM,'LineWidth',2)
% xlabel('Wind speed')
% ylabel('Lambda')
% hold off

% %--- plot RPM vs wind
% figure
% title('RPM')
% hold on
% grid on
% plot(v,TargRPM,'LineWidth',2)
% xlabel('Wind speed')
% ylabel('RPM')
% hold off

%% ----- Print OTC to console and store in fiel
% -------------------------------------
% --- echo new opti-pitch
% -------------------------------------
fprintf('====================================\n');
fprintf('Optimized Opti-Tip:\n\n');
for i=1:length(OTC.Step_2.lambda)
    fprintf('Px_OTC_TableLambdaToPitchOptX%02d =\t%2.2f\n',i,OTC.Step_2.lambda(i));    
end
for i=1:length(TargPitch_interp)
    fprintf('Px_OTC_TableLambdaToPitchOptY%02d =\t%2.2f\n',i,TargPitch_interp(i));    
end
fprintf('====================================\n');
% -- Store file
fprintf('Storing OTC file\n');
fprintf('\tFile: %s\n',fullfile(pwd,OTC.Step_2.OTCfile));
fid = fopen(OTC.Step_2.OTCfile,'w');
fprintf(fid,'%s\n',date);
fprintf(fid,'Executed with OptiLambda from previous step: %2.2f\n',OTC.Step_2.OptiLambda);
fprintf(fid,'--Optimization Choices and Constraints--\n');
for i=1:length(LogMsg)
    fprintf(fid,'%s\n',LogMsg{i});   
end
fprintf(fid,'--------OptiTip CONTROLLER-------\n');
for i=1:length(OTC.Step_2.lambda)
    fprintf(fid,'Px_OTC_TableLambdaToPitchOptX%02d =\t%2.2f\n',i,OTC.Step_2.lambda(i));    
end
for i=1:length(TargPitch_interp)
    fprintf(fid,'Px_OTC_TableLambdaToPitchOptY%02d =\t%2.2f\n',i,TargPitch_interp(i));    
end
fclose(fid);
fprintf('OK\n');

%% UPSAMPING
% for i=1:nV
%     P_t = reshape(Pitch(i,:),length(L),length(P_off));
%     Pitch_col=P_t(1,:);
%     if (plot_op==1 && length(L)>1)
%         figure
%         subplot(1,2,1)
%         shapcT=reshape(Ct(i,:),length(L),length(P_off));
%         contourf(P_off,L,shapcT)
% 
%         title(sprintf('cT %.1f m/s',v(i)))
%         grid on
%         xlabel('Pitch')
%         ylabel('Lambda')
%         
%         subplot(1,2,2)
%         shapPC = reshape(PC(i,:),length(L),length(P_off));
%         contourf(P_off,L,reshape(PC(i,:),length(L),length(P_off)))
%         title(sprintf('P%.1f m/s',v(i)))
%         grid on
%         xlabel('Pitch')
%         ylabel('Lambda')   
%     end
% end


%%
% % -------------------------------------
% % --- TIME IN STALL PART
% % -------------------------------------
% % path='o:\VY\V1749600.107\IEC1B.003\Time_in_Stall\VTS\Loads\';
% % name='11';
% % output_folder='o:\VY\V1749600.107\IEC1B.003\Time_in_Stall\';
% % TimeInStall(path, name,output_folder);
% % ---------------------------
% % --- Set-up computation dirs
% % ---------------------------
% fprintf('Preparing directory for Time in Stall...\n');
% dir_2 = '3_Time_in_Stall';
% % --- main dir
% sim_dir_2 = fullfile(pwd,dir_2);
% fprintf('\tSetting up directories:\n');
% fprintf('\t\tCreating: %s\n',sim_dir_2);
% mkdir(sim_dir_2)
% % --- Loads
% sim_dir_3 = fullfile(sim_dir_2,'Loads');
% fprintf('\t\tCreating: %s\n',sim_dir_3);
% mkdir(sim_dir_3)
% % ---- INPUTS
% sim_dir_4 = fullfile(sim_dir_3,'INPUTS');
% fprintf('\t\tCreating: %s\n',sim_dir_4);
% mkdir(sim_dir_4)
% % ---- INT
% sim_dir_5 = fullfile(sim_dir_3,'INT');
% fprintf('\t\tCreating: %s\n',sim_dir_5);
% mkdir(sim_dir_5)
% fprintf('OK\n');
% % ---------------------------
% % --- Combine int files from different PC paths
% % ---------------------------
% fprintf('Preparing INT files...\n');
% for i=1:nV
%     if(STEP_2.OK(i)==1)
%         for iseed=1:6
%             % --- check wind format
%             if (mod(v(i),1)==0)
%                 int_file =fullfile(Path,['01_',sprintf('%03d',choice_record(i))],'PC','QuickPowerCurve','Rho1.225','INT',['94_QuickPowerCurve_Rho1.225_Vhfree_',sprintf('%1.0f',v(i)),'_',sprintf('%03d',iseed),'.int']);
%                 [status,msg,msgID] = copyfile(int_file,sim_dir_5,'f');
%             else
%                 int_file =fullfile(Path,['01_',sprintf('%03d',choice_record(i))],'PC','QuickPowerCurve','Rho1.225','INT',['94_QuickPowerCurve_Rho1.225_Vhfree_',sprintf('%1.1f',v(i)),'_',sprintf('%03d',iseed),'.int']);
%                 [status,msg,msgID] = copyfile(int_file,sim_dir_5,'f');
%             end
%             % --- check if copied with no errors
%             if(~status)
%                 fprintf('\tFailed to copy file:\n');
%                 fprintf('\tWS=%2.1f; File: %s\n',v(i),int_file);
%                 fprintf('\tError: %s\n',msg);
%                 return;
%             end
%         end
%     end
% end
% fprintf('OK\n');

