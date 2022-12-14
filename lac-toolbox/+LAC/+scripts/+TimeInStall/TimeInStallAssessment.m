function TimeInStallAssessment(path_timestall)
% Function to plot positive and negative TiS and do the verification of TiS criteria (according to 0077-3331.V01)
% More info can be found in the Noise Modes Guideline (0073-8946.V03), section 9.2
%
% Script "TimeInStall_script.m" (located in LAC Matlab toolbox, develop branch) must be run previously 
% c:\repo\lac-matlab-toolbox\+LAC\+scripts\+TimeInStall\TimeInStall_script.m
%
% SYNTAX:
% 	LAC.scripts.TimeInStall.TimeInStallAssessment(path_timestall)
%
% INPUTS:
%   'path_timestall': Path to Time in stall output folder (..\output\1\)
%
% OUTPUTS:
% 	Both located in the folder given as input (path_timestall):
% 	- Plots for positive and negative time in stall for the outer 50% of rotor, with plotted acceptable limits
%	- File 'Summary_TIS.txt', with the summary of the fall-back approach evaluation
%
% VERSIONS:
%   2021/09/04 - AAMES: V00

%% Get data from files with time in stall
flist = findfiles('TimeInStall_WS*',path_timestall);
data = cell(2,length(flist));
for i=1:length(flist)
    fid = fopen(flist{i,1});
    filename = cellstr(flist{i,1});
    filename = strsplit(filename{1,1},'\');
    data{1,i} = filename{1,end};
    data{2,i} = transpose(fscanf(fid,'%f %f %f',[3 Inf])); 
    % Columns for data{2,i}: Blade radial position[%] | Positive stall[%] - time | Negative stall[%] - time
    fclose(fid);
end

% Get Wind speeds
wspeed=zeros(1,length(data));
for j=1:length(data)
    str_wsp = cellstr(data{1,j});
    wsp=strsplit(str_wsp{1,1},'_');
    wspeed(j)=str2double(wsp{1,3});
    data{3,j}=wspeed(j);
end
wsd=string(strcat(num2str(wspeed(:)),' m/s'));
lgd_entries=cellstr(wsd);

%% Time in stall plots

% Positive Stall: Allowable time[%] should be 1% for the outer 50% of rotor
fig1=figure('Name','Positive Stall');
for ii=1:length(data)
    info=data{2,ii};
    radial_index=find(info(:,1)>0.5, 1, 'first'); % Radial position of rotor (in %) - from 50% to end
    plot(100*info(radial_index:end,1),100*info(radial_index:end,2),'LineWidth',2);
    hold on
end
grid on
legend(lgd_entries)
xlabel('Radial position [%]')
ylabel('Time in Stall [%]')
title('Positive Stall (limit=1%)')
limitP = ones(length(info(radial_index:end,1)),1);
plot(100*info(radial_index:end,1),limitP,'k-','LineWidth',1.5)
saveas(fig1,fullfile(path_timestall,'Positive_Stall_50_Outer'),'meta');

% Negative Stall: Allowable time[%] should be 5% for the outer 50% of rotor
fig2=figure('Name','Negative Stall');
for ii=1:length(data)
    info=data{2,ii};
    radial_index=find(info(:,1)>0.5, 1, 'first'); % Radial position of rotor (in %) - from 50% to end
    plot(100*info(radial_index:end,1),100*info(radial_index:end,3),'LineWidth',2);
    hold on
end
grid on
legend(lgd_entries)
xlabel('Radial position [%]')
ylabel('Time in Stall [%]')
title('Negative Stall (limit=5%)')
limitN = 5*ones(length(info(radial_index:end,1)),1);
plot(100*info(radial_index:end,1),limitN,'k-','LineWidth',1.5)
saveas(fig2,fullfile(path_timestall,'Negative_Stall_50_Outer'),'meta');


%% Fall-back approach (Chapter 4 of 0077-3331.V01)
e_ts=5.5; % tip speed exponent
s=7; % stall jump size (in dB)

% Check positive /negative stall
lwa_R=cell(1,size(data,2));
lwa_R_stall_pos=cell(1,size(data,2));
lwa_R_stall_neg=cell(1,size(data,2));
lwa_R_10=cell(1,size(data,2));
lwa_R_stall_10_pos=cell(1,size(data,2));
lwa_R_stall_10_neg=cell(1,size(data,2));
for ii=1:size(data,2)
    radial_pos=100*data{2,ii}(:,1);
    time_pos=100*data{2,ii}(:,2);
    time_neg=100*data{2,ii}(:,3);
    lwa_R{1,ii}=e_ts*10*log10(radial_pos); % contribution from each radial position
    lwa_R_stall_pos{1,ii}=10.*log10(((100-time_pos)./100).*10.^(lwa_R{1,ii}(:)./10)+(time_pos./100).*10.^((lwa_R{1,ii}(:)+s)./10)); % stalled contribution for each radial position 
    lwa_R_10{1,ii}=10.^(lwa_R{1,ii}(:)./10); % for the sum
    lwa_R_stall_10_pos{1,ii}=10.^(lwa_R_stall_pos{1,ii}(:)./10); %for the sum
    lwa_R_stall_neg{1,ii}=10.*log10(((100-time_neg)./100).*10.^(lwa_R{1,ii}(:)./10)+(time_neg./100).*10.^((lwa_R{1,ii}(:)+s)./10)); % stalled contribution for each radial position 
    lwa_R_stall_10_neg{1,ii}=10.^(lwa_R_stall_neg{1,ii}(:)./10); %for the sum
end
sum_lwa_R = zeros(1,size(data,2));
sum_lwa_R_stall_pos = zeros(1,size(data,2));
sum_lwa_R_stall_neg = zeros(1,size(data,2));
for jj=1:size(data,2)
    sum_lwa_R(1,jj)=10*log10(sum(lwa_R_10{1,jj}(:)));
    sum_lwa_R_stall_pos(1,jj)=10*log10(sum(lwa_R_stall_10_pos{1,jj}(:)));
    sum_lwa_R_stall_neg(1,jj)=10*log10(sum(lwa_R_stall_10_neg{1,jj}(:)));
end
% delta = exceedance in defined noise level due to the time in stall
delta_pos = sum_lwa_R_stall_pos-sum_lwa_R; % in order to accept the time in stall above 1%, the delta should not be above 0.2dB (well below uncertainty of 0.7dB)
delta_neg = sum_lwa_R_stall_neg-sum_lwa_R; % in order to accept the time in stall above 5%, the delta should not be above 0.8dB (well below uncertainty of 2dB)


summaryfile = fullfile(path_timestall,'Summary_TIS.txt');
fid=fopen(summaryfile,'w+');

fprintf(fid,'Evaluation based on Chapter 4 - 0077-3331.V01:\n');
fprintf(fid,'Positive stall limit: 0.2 dB (should be well below test uncertainty of 0.7 dB)\n');
fprintf(fid,'Negative stall limit: 0.8 dB (should be well below test uncertainty of 2.0 dB)\n\n');

fprintf(fid,'Positive stall - Increase in noise level: \n');
fprintf(fid,'-------------------------------------------------------------------------------------- \n');
str_check=string;
delta_db=string(strcat(num2str(delta_pos(:),'%1.1f'),' dB'));
for k=1:length(wsd)
    if round(delta_pos(k),1)>=0.7
        str_check(k)='Above limit and test measurement uncertainty';
    elseif round(delta_pos(k),1)>0.2
        str_check(k)='Above simulation limit, below test measurement uncertainty';
    else
        str_check(k)='OK';
    end
end
str_check=transpose(str_check);
fprintf(fid,'%11s %11s %60s \n','Wind speed','Delta','Check');
fprintf(fid,'-------------------------------------------------------------------------------------- \n');
fprintf(fid,'%11s %11s %60s \n', [wsd, delta_db, str_check]');
fprintf(fid,'-------------------------------------------------------------------------------------- \n');

fprintf(fid,'\nNegative stall - Increase in noise level: \n');
fprintf(fid,'-------------------------------------------------------------------------------------- \n');
str_check=string;
delta_db=string(strcat(num2str(delta_neg(:),'%1.1f'),' dB'));
for k=1:length(wsd)
    if round(delta_neg(k),1)>=2
        str_check(k)='Above limit and test measurement uncertainty';
    elseif round(delta_neg(k),1)>0.8
        str_check(k)='Above simulation limit, below test measurement uncertainty';
    else
        str_check(k)='OK';
    end
end
str_check=transpose(str_check);
fprintf(fid,'%11s %11s %60s \n','Wind speed','Delta','Check');
fprintf(fid,'-------------------------------------------------------------------------------------- \n');
fprintf(fid,'%11s %11s %60s \n', [wsd, delta_db, str_check]');
fprintf(fid,'-------------------------------------------------------------------------------------- \n\n');

fprintf(fid,'Note: If any of the results appear as "Above simulation limit, below test measurement uncertainty", you should check with the acoustics team for validation (POC: ERSLO).\n');

fclose(fid);

fprintf('\nSummary in:\n%s\n',summaryfile);

end

%% Function findfiles
function flist = findfiles(pattern,basedir)

if nargin < 2
    basedir = pwd;
end
if ~ischar(pattern) || ~ischar(basedir)
    error('File name pattern and base folder must be specified as strings')
end
if ~isdir(basedir)
    error(['Invalid folder "',basedir,'"'])
end


% Get full-file specification of search pattern
fullpatt = [basedir,filesep,pattern];

% Get list of all folders in BASEDIR
d = cellstr(ls(basedir));
d(1:2) = [];
d(~cellfun(@isdir,strcat(basedir,filesep,d))) = [];

% Check for a direct match in BASEDIR
% (Covers the possibility of a folder with the name of PATTERN in BASEDIR)
if any(strcmp(d,pattern))
    % If so, that's our match
    flist = {fullpatt};
else
    % If not, do a directory listing
    f = ls(fullpatt);
    if isempty(f)
        flist = {};
    else
        flist = strcat(basedir,filesep,cellstr(f));
    end
end

% Recursively go through folders in BASEDIR
for k = 1:length(d)
    flist = [flist;findfiles(pattern,[basedir,filesep,d{k}])]; 
end
end