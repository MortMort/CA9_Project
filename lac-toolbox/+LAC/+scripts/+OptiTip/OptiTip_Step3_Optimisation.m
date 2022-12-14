%% Configuration
run('OptiTip_Configuration.m');
% --- redirect variables
Outputs.TimeInStall = TimeInStall.WS;

% --- include Time In Stall scripts
if (exist(fullfile(pwd,'TimeInStall_Scripts'),'dir'))
    addpath(fullfile(pwd,'TimeInStall_Scripts'))
else
    error('Make sure to place TimeInStall_Scripts direcotry in the same directory as the script you are running.');
end

WSPrecision = 0.5; % make the code consistent with TimeInStall scripts

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

%%  
% --- Loop over sim direcotries and run time in stall
fprintf('Creating Time In Stall curves\n')
for i=1:length(TimeInStall.sim_dir)
    fprintf('\tDir: %s\n',TimeInStall.sim_dir{i});
    path=fullfile(TimeInStall.sim_dir{i},'Loads\');    
    output_folder=TimeInStall.sim_dir{i};
    TimeInStall_main(path, OTC.Step_3.name, output_folder, Outputs);
end
fprintf('OK\n');

%%  
% --- Collect results
fprintf('Loading Time In Stall curves\n')
for i=1:length(TimeInStall.sim_dir)
    dir = fullfile(TimeInStall.sim_dir{i},OTC.Step_3.name);
    for j=1:length(Outputs.TimeInStall)
        FileName = [dir,'\TimeInStall_WS_',num2str(round(Outputs.TimeInStall(j)/WSPrecision)*WSPrecision),'_DLC_11.txt'];
        data = load(FileName, '-ascii');
        TimeInStall.Output{i}.R{j} = data(:,1);
        TimeInStall.Output{i}.pveStall{j} = data(:,2);
        TimeInStall.Output{i}.nveStall{j} = data(:,3);
    end
end
fprintf('OK\n');
%%  
% --- find for each wind speed and OTC paramters limits are not exceeded
fprintf('Processing Time In Stall curves\n')
% - reduce number of radii points
index = find(TimeInStall.Output{1}.R{1}>=0.5);
R = TimeInStall.Output{1}.R{1}(index);
% - interpolate Limits to points
PositiveLimit = interp1(TimeInStall.R,TimeInStall.PositiveLimit,R);
% - find elements that satisfy limits
OK = zeros(length(TimeInStall.sim_dir),length(Outputs.TimeInStall));
for i=1:length(TimeInStall.sim_dir)
    % --- locate output direcotry
    dir = fullfile(TimeInStall.sim_dir{i},OTC.Step_3.name);
    % --- loop over WS
    for j=1:length(Outputs.TimeInStall)
        pveStall = TimeInStall.Output{i}.pveStall{j}(index);
        diffStall = PositiveLimit - pveStall;
        exceeds = find(diffStall < 0);
        if(isempty(exceeds))
            OK(i,j) = 1;
        end
    end
    % -- create and store figures
    figure('name','DLC11 - Negative Stall')
    hold on;
    plot([0.5 1],[0.05 0.05],'--');
    ylim([0 0.5]);
    xlabel('Normalised radius [-]')
    ylabel('Ratio of time in negative stall [-]')
    legendInfoNeg{1}='Limit';
    n=2;
    for j=1:length(Outputs.TimeInStall)
        plot(TimeInStall.Output{i}.R{j},TimeInStall.Output{i}.nveStall{j})       
        legendInfoNeg{n} = [num2str(Outputs.TimeInStall(j)) 'm/s'];
        n=n+1;
    end
    legend(legendInfoNeg)
    
    SaveFileNameFigNegStall = [dir,'\TimeInStall_DLC_11_NegStall.jpg'];
    SaveFileNameFigNegStall_fig = [dir,'\TimeInStall_DLC_11_NegStall.fig'];
    saveas(gcf,SaveFileNameFigNegStall)
    saveas(gcf,SaveFileNameFigNegStall_fig)
    close(gcf)
    
    figure('name','DLC11 - Positive Stall')
    hold on
    plot(R,PositiveLimit,'--');
    ylim([0 0.5])
    xlabel('Normalised radius [-]')
    ylabel('Ratio of time in positive stall [-]')
    legendInfoPos{1}='Limit';
    n=2;
    for j=1:length(Outputs.TimeInStall)        
        plot(TimeInStall.Output{i}.R{j},TimeInStall.Output{i}.pveStall{j})     
        legendInfoPos{n} = [num2str(Outputs.TimeInStall(j)) 'm/s'];
        n=n+1;        
    end
    legend(legendInfoPos)
    
    SaveFileNameFigPosStall = [dir,'\TimeInStall_DLC_11_PosStall.jpg'];
    SaveFileNameFigPosStall_fig = [dir,'\TimeInStall_DLC_11_PosStall.fig'];
    saveas(gcf,SaveFileNameFigPosStall)
    saveas(gcf,SaveFileNameFigPosStall_fig)
    close(gcf)
end
% -- find for each WS which OTC should be used
% -- loop over WS
for j=1:length(Outputs.TimeInStall)
    best = find(OK(:,j)==1, 1, 'first');
    if(isempty(best))
        fprintf('\tWas not able to find simulation with no limit exceedance for WS=%2.2f\n',Outputs.TimeInStall(j));
        fprintf('\tWill try to use the best\n');
        % --- BEST CAN BE IMPROVED BASED ON ACTUAL DISTANCE TO LIMITS
        best = size(OK,1);
    end
    TimeInStall.Optimum(j)=best;
end
fprintf('OK\n');

%% Read-in starting OTC
% ---------------------------
% --- Extract starting OTC parameters
% ---------------------------
if(OTC.Steps(1)==1)
    TimeInStall.OTCfile = fullfile(pwd,OTC.Step_1.OTCfile);
elseif(OTC.Steps(2)==1)
    TimeInStall.OTCfile = fullfile(pwd,OTC.Step_2.OTCfile);
end
fprintf('Reading OTC settings\n');
% TimeInStall.OTCfile = fullfile(pwd,OTC.Step_2.OTCfile);
if(OTC.Steps(1)==1 || OTC.Steps(2)==1)% if first or second step was set in configuration
    fprintf('\tReading: %s\n',TimeInStall.OTCfile);
    % --- self check
    if ~(exist(TimeInStall.OTCfile)==2)
        error('Failed to find OTC file.')
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
fprintf('OK\n');
%% Find relation between lambda and WS
% -- loop over WS
fprintf('Extracting Lambda and Pitch from STA files\n');
for j=1:length(Outputs.TimeInStall)    
    STA = LAC.vts.stapost([TimeInStall.sim_dir{j},'\Loads\']);
    STA.read();
    LoadCase = ['11',sprintf('%02d',Outputs.TimeInStall(j))];
    RPM = STA.getLoad('Omega','mean',{LoadCase});
    % --- store Lambda
    TimeInStall.LambdaSim(j)=RPM/60*2*pi()/Outputs.TimeInStall(j)*OTC.Radius;
    % --- Get Pitch
    TimeInStall.PitchSim(j)=interp1(TimeInStall.lambda,TimeInStall.pitch,TimeInStall.LambdaSim(j));
    % - correct pitch for Time in Stall
    TimeInStall.PitchSim(j) = TimeInStall.PitchSim(j) + OTC.Step_3.pitch_range(TimeInStall.Optimum(j));    
end
fprintf('OK\n');
%% Interpolate to new OTC
% --- intepolate on given lambda
Pitch_interp = interp1(TimeInStall.LambdaSim,TimeInStall.PitchSim,TimeInStall.lambda,'pchip','extrap');
% --- fix interpolation for high lambdas
j=find(TimeInStall.lambda>max(TimeInStall.LambdaSim));
Pitch_interp(1,j)=TimeInStall.pitch(1,j);
% --- fix low lambdas pitch 
j=find(TimeInStall.lambda<min(TimeInStall.LambdaSim));
Pitch_interp(1,j)=TimeInStall.pitch(1,j);
%%
% --- Plot results
figure
hold on
grid on
plot(TimeInStall.lambda,TimeInStall.pitch,'LineWidth',1)
plot(TimeInStall.LambdaSim,TimeInStall.PitchSim,'+-','LineWidth',2)
plot(TimeInStall.lambda,Pitch_interp,'color','k','LineWidth',2)
xlabel('Lambda')
ylabel('Pitch')
legend('VTS Step 2','VTS with TimeInStall limit','Resulting');
hold off
print(fullfile(pwd,'Step_3_OTC.png'),'-dpng','-r300')
saveas(gcf,fullfile(pwd,'Step_3_OTC.fig'));
%% Store results
% -- Store file
fprintf('Storing OTC file\n');
fprintf('\t %s\n',fullfile(pwd,OTC.Step_3.OTCfile));
fid = fopen(fullfile(pwd,OTC.Step_3.OTCfile),'w');
fprintf(fid,'%s\n',date);
fprintf(fid,'--Optimization Choices and Constraints--\n');
for i=1:length(TimeInStall.Optimum)
    fprintf(fid,'Optimum choice: WS=%1.2f, Folder=%03d, Pitch=%2.2f, Lambda=%1.2f',TimeInStall.WS(i),TimeInStall.Optimum(i),TimeInStall.PitchSim(i),TimeInStall.LambdaSim(i));
    if(TimeInStall.Optimum(i)==length(TimeInStall.sim_dir))
        fprintf(fid,'\tWARNING: choice is limited by pitch range.\n');
    else
        fprintf(fid,'\n');
    end
end
fprintf(fid,'--------OptiTip CONTROLLER-------\n');
for i=1:length(TimeInStall.lambda)
    fprintf(fid,'Px_OTC_TableLambdaToPitchOptX%02d =\t%2.2f\n',i,TimeInStall.lambda(i));    
end
for i=1:length(Pitch_interp)
    fprintf(fid,'Px_OTC_TableLambdaToPitchOptY%02d =\t%2.2f\n',i,Pitch_interp(i));    
end
fclose(fid);
fprintf('OK\n');




