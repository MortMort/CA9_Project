function Step01_PrepMeasuredPrepVTSInput_PP(Inputfile, INTs_naming, WTG, bin_Vn, dat_path, vpas_path, TV_filter, TI_filter, Shear_filter)
%% Step01_PrepMeasuredPrepVTSInput(Inputfile,Dat_Path,WTG)
% Function to take in measured data, filter it, and create loadcases for
% VTS simulation.
%
% Inputs:
% Inputfile: .xlsx file with information on sensornames and filtering
%            criterias.
% Dat_Path: Path to the measured data, .dat folder e.g.
%           y:\_Data\..\03_Postprocessed data\Post04\dat\
% WTG: Structure holding turbine information like gear ratio, and power
%      rating etc.
% Prog_path: Path where some complementary scripts are
% Timenum : Contains the corresponding name of the data that have been filtered
%
% Outputs:
% MeasurementData.mat: Structure holding the measured data after filtering.
% Step01_SiteConditions.mat: .mat file hold the capture matrix and site
%                            conditionds used for the report.
% Step01_DLC.txt: .txt file with 1-to-1 loadcases corresponding to the
%                 measured data after filtering.
% Step01_data.txt: .txt file describing the loadcases for simulation.
% Sorting_LV.mat: .mat file with the filtering data
%
% Note - The function datload and datsort should be adjusted by the user
%
% Modified by RUSJE 1/2-2018
% Modified by YAYDE Sept. 2018

% Modified by MODFY to suit V117 Power Perform Verification - 06-05-2019
%
% Modified by JOPMF Oct. 2020 (V174 campaign)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

import LAC.scripts.PowerVerification.auxiliary.*
import LAC.scripts.PowerVerification.auxiliary.Step01.*

%% 1. Measured data loading
addpath(dat_path);
datloadV2;

windshear_method = 1; % Option [1] for THE average of the 3 wind shear combinations, [2] for the best fit approximation
% If empty, ask user for input after plotting differences.
% Only used if wind speed is measured in at least 3 points.

% Converting the sensorlist names into short names without description
for iConv = 1:length(data.dat1.sensorname)
    idxSpace = strfind(data.dat1.sensorname{iConv},' ');
    Fullname = data.dat1.sensorname{iConv};
    if length(idxSpace) >1
        name{iConv} = Fullname(idxSpace(1):idxSpace(2));
    else
        name{iConv} = Fullname;
    end
end
name = strrep(name,' ', ''); % Remove all spaces in the names

%% 2. T&V Filtering

%
%     TV_data = load(vpas_path, 'data');
	  date_tmp = strrep(data.dat1.filedescription, INTs_naming, '');
%     data.dat1.timenum = datenum(date_tmp, 'yyyymmdd_HHMM');
%
%     Filter_ID = ismember(data.dat1.timenum, TV_data.data.timenum);
%     dat_fnames = fieldnames(data.dat1);
%
%     for i = 1:length(dat_fnames)
%         if length(data.dat1.(dat_fnames{i})) == length(Filter_ID)
%             data.dat1.(dat_fnames{i}) = data.dat1.(dat_fnames{i})(Filter_ID, :);
%         else
%         end
%     end

%%% T&V filtering
if isempty(TV_filter)
    fprintf('\n2. No T&V filters applied \n ');
    vpas_data   = load(vpas_path);
    data.dat1.timenum = vpas_data.timenum(:, 1);
else
    
    fprintf('\n2. Applying T&V filters \n ');
    vpas_data   = load(vpas_path);
    vpas_filter = load(TV_filter);
    [Filter_ID] = FilterIndex(vpas_data, vpas_filter);
    
    dat_fnames = fieldnames(data.dat1);
    
    % collect the measurement name that are passing out the filter
    idx_filter = find(Filter_ID==1);
    for i_filter =1:length(idx_filter)
        meas_name = vpas_data.meta_info.shortnames(idx_filter(i_filter),:);
        idx_data_match(i_filter,1) = find(strcmp(data.dat1.filename,erase(meas_name,'.int'))==1);
    end
    
    for i = 1:length(dat_fnames)
        if strcmp(dat_fnames{i},'sensorname') || strcmp(dat_fnames{i},'sensorno') || strcmp(dat_fnames{i},'stat') || strcmp(dat_fnames{i},'unit') || strcmp(dat_fnames{i},'description')
            
        else
            if length(data.dat1.(dat_fnames{i})) == length(Filter_ID)
                data.dat1.(dat_fnames{i}) = data.dat1.(dat_fnames{i})(Filter_ID, :);
            else % collect the measurement name that are passing out the filter
                % find file index
                data.dat1.(dat_fnames{i}) = data.dat1.(dat_fnames{i})(idx_data_match, :);
            end
        end
    end
    
    % Read the date for each time series in timenum format
    data.dat1.timenum = vpas_data.timenum(Filter_ID, 1);
end

%% 3. LaC Filtering

% Reading the input file, here it should be described what sensors to look at, and how to group them
[~,txt,raw] = xlsread(Inputfile,2);

% Loop over all sensornames in input file. Extracts the meas. sensorname and compares with the sensorlist in MeasurementData.mat to find the sensor number.
iSensorS = find(contains(txt,'START_SORTINGSENSORS'));
iSensorE = find(contains(txt,'END_SORTINGSENSORS'));

for iName=iSensorS+1:iSensorE-1
    if find(strcmpi(name,raw{iName,2}) == 1) >0
        idx.(raw{iName,1}) = find(strcmpi(name,raw{iName,2}) == 1);
    elseif isnumeric(raw{iName,2})
        idx.(raw{iName,1}) = raw{iName,2};
    else
        idx.(raw{iName,1}) = str2num(raw{iName,2});
    end
end

% Extracting the sorting table from the input file
iSortS = find(contains(txt,'Start_SortTable'));
iSortE = find(contains(txt,'End_SortTable'));
for iSort = iSortS+1:iSortE-1
    SortTable{iSort-iSortS,1} = char(txt{iSort,1});
    SortTable{iSort-iSortS,2} = char(txt{iSort,2});
    SortTable{iSort-iSortS,3} = cell2mat(raw(iSort,3));
    SortTable{iSort-iSortS,4} = cell2mat(raw(iSort,4));
end

%% 4. Calculation of additional data

% Turbulence Intensity
[data, idx] = TICalc(data, idx);

% filter based on TI (added 12-05-2021 - MODFY)
if TI_filter(1) ==1
    %     filter based on TI
    idx_TI=idx.turb;
    %idx_TI = find(strcmp(data.dat1.sensorname,'182 Turb_calc'));
    idx_fTI_lo = data.dat1.mean(:,idx_TI)>= TI_filter(2)/100;
    idx_fTI_up = data.dat1.mean(:,idx_TI)<= TI_filter(3)/100;



for i_TI = 1:length(idx_fTI_up)
    if  idx_fTI_lo(i_TI) ==1 && idx_fTI_up(i_TI) ==1
        idx_fTI(i_TI,1) = 1;
    else
        idx_fTI(i_TI,1) = 0;
    end
end
idx_fTI = logical(idx_fTI);
data_bak = data;
data_field = fieldnames(data.dat1);
clear data;
for j_TI = 1:length(data_field)
    if strcmp(data_field{j_TI,1},'sensorname') || strcmp(data_field{j_TI,1},'sensorno') || strcmp(data_field{j_TI,1},'stat') || strcmp(data_field{j_TI,1},'unit') || strcmp(data_field{j_TI,1},'description')
        data.dat1.(data_field{j_TI,1}) = data_bak.dat1.(data_field{j_TI,1});
    else
        data.dat1.(data_field{j_TI,1}) = data_bak.dat1.(data_field{j_TI,1})(idx_fTI,:);
    end
end

end

% SortTable(end+1,:) = {'TI' 'mean' 0.06 0.12};
% end filter based on TI 

% Air Density (normalised)
if isfield(idx,'pres') && idx.pres >0
    [data, idx] = AirDensityNorm(data,idx);
end

% Wind speed (normalised)
[data, idx] = WindSpeedNorm(data,idx,WTG.RhoRef);

% Wind shear
if ~isfield(idx,'wsh') || length(idx.wsh)== 1
    sprintf('Need at least 2 sensors to calculate wind shear. Set to 0.2')
    WindShear = ones(size(data.dat1.mean)).*0.2;
elseif length(idx.wsh)== 2
    WindShear = log(data.dat1.mean(:,idx.wsh(1))./data.dat1.mean(:,idx.wsh(2)))/log(idx.wshHeight(1)/idx.wshHeight(2));
elseif length(idx.wsh)> 2
    if length(idx.wsh)== 3
    Vexp12 = log(data.dat1.mean(:,idx.wsh(1))./data.dat1.mean(:,idx.wsh(2)))/log(idx.wshHeight(1)/idx.wshHeight(2));
    Vexp23 = log(data.dat1.mean(:,idx.wsh(2))./data.dat1.mean(:,idx.wsh(3)))/log(idx.wshHeight(2)/idx.wshHeight(3));
    Vexp13 = log(data.dat1.mean(:,idx.wsh(1))./data.dat1.mean(:,idx.wsh(3)))/log(idx.wshHeight(1)/idx.wshHeight(3));
    WindShear1 = (Vexp12 + Vexp23 + Vexp13)/3;
     wshError1  = (data.dat1.mean(:,idx.wsh(2))-(data.dat1.mean(:,idx.wsh(1)).*(idx.wshHeight(2)/idx.wshHeight(1))).^WindShear1).^2 +...
        (data.dat1.mean(:,idx.wsh(3))-(data.dat1.mean(:,idx.wsh(1)).*(idx.wshHeight(3)/idx.wshHeight(1))).^WindShear1).^2;
    
    elseif length(idx.wsh) ==4
            Vexp12 = log(data.dat1.mean(:,idx.wsh(1))./data.dat1.mean(:,idx.wsh(2)))/log(idx.wshHeight(1)/idx.wshHeight(2));
            Vexp13 = log(data.dat1.mean(:,idx.wsh(1))./data.dat1.mean(:,idx.wsh(3)))/log(idx.wshHeight(1)/idx.wshHeight(3));
            Vexp14 = log(data.dat1.mean(:,idx.wsh(1))./data.dat1.mean(:,idx.wsh(4)))/log(idx.wshHeight(1)/idx.wshHeight(4));
            Vexp23 = log(data.dat1.mean(:,idx.wsh(2))./data.dat1.mean(:,idx.wsh(3)))/log(idx.wshHeight(2)/idx.wshHeight(3));
            Vexp24 = log(data.dat1.mean(:,idx.wsh(2))./data.dat1.mean(:,idx.wsh(4)))/log(idx.wshHeight(2)/idx.wshHeight(4));
            Vexp34 = log(data.dat1.mean(:,idx.wsh(3))./data.dat1.mean(:,idx.wsh(4)))/log(idx.wshHeight(3)/idx.wshHeight(4));
            
            WindShear1 = (Vexp12 + Vexp13 + Vexp14 + Vexp23 + Vexp24 + Vexp34)/6;
             wshError1  = (data.dat1.mean(:,idx.wsh(2))-(data.dat1.mean(:,idx.wsh(1)).*(idx.wshHeight(2)/idx.wshHeight(1))).^WindShear1).^2 +...
        (data.dat1.mean(:,idx.wsh(3))-(data.dat1.mean(:,idx.wsh(1)).*(idx.wshHeight(3)/idx.wshHeight(1))).^WindShear1).^2 + ...
                (data.dat1.mean(:,idx.wsh(4))-(data.dat1.mean(:,idx.wsh(1)).*(idx.wshHeight(4)/idx.wshHeight(1))).^WindShear1).^2;
    
    end
   
    [WindShear2, wshError2] = windshear3(data.dat1.mean,idx.wsh,idx.wshHeight,1,length(data.dat1.mean));
    
    % Ask user for what type of shear calculation to be used
    if ~isempty(windshear_method)
        if windshear_method == 1
            WindShear = WindShear1;
        elseif windshear_method == 2
            WindShear = WindShear2;
        end
    else
        % Plotting shear and errors
        figure
        subplot(1,2,1)
        title('Turbulence Intensity');
        scatter(data.dat1.mean(:,idx.wsh(1)), WindShear1)
        hold on
        scatter(data.dat1.mean(:,idx.wsh(1)), WindShear2)
        xlabel('Windspeed [m/s]');
        ylabel('TI [-]');
        legend('3 combination average (old method)', 'Best fit approximation');
        
        % Error plots
        subplot(1,2,2)
        scatter(data.dat1.mean(:,idx.wsh(1)), wshError1) % shear value absolute error
        hold on
        scatter(data.dat1.mean(:,idx.wsh(1)), wshError2) % quadratic error of the approximation
        xlabel('Windspeed [m/s]');
        ylabel('Quadratic Error [-]');
        
        inp_check = 0;
        while inp_check == 0
            user = upper(input('Fitting method to use, 1 or 2?\n \t[1] - Average of the combination of 3 with shear estimations\n \t[2] - Best fit approximation (quadratic error minimization)\n', 's'));
            if user == '1'
                WindShear = WindShear1;
                inp_check = 1;
            elseif user == '2'
                WindShear = WindShear2;
                inp_check = 1;
            end
        end
    end
    
end

data.dat1.sensorname{max(size(data.dat1.sensorname))+1,1} = 'WindShear_Calc';
data.dat1.sensorno{max(size(data.dat1.sensorno))+1,1} = num2str(max(size(data.dat1.sensorname)));
data.dat1.unit{max(size(data.dat1.unit))+1,1} = '-';
data.dat1.mean(:,max(size(data.dat1.sensorname))) = WindShear;
idx.WShear = max(size(data.dat1.sensorname));

% filter based on wind shear (added 12-05-2021 - MODFY)
if Shear_filter(1) ==1
    %     filter based on TI
    idx_Sh = find(strcmp(data.dat1.sensorname,'WindShear_Calc'));
    idx_fSh_lo = data.dat1.mean(:,idx_Sh)>= Shear_filter(2);
    idx_fSh_up = data.dat1.mean(:,idx_Sh)<= Shear_filter(3);

for i_Sh = 1:length(idx_fSh_up)
    if  idx_fSh_lo(i_Sh) ==1 && idx_fSh_up(i_Sh) ==1
        idx_fSh(i_Sh,1) = 1;
    else
        idx_fSh(i_Sh,1) = 0;
    end
end
idx_fSh = logical(idx_fSh);
data_bak = data;
data_field = fieldnames(data.dat1);
clear data;

for j_Sh = 1:length(data_field)
    if strcmp(data_field{j_Sh,1},'sensorname') || strcmp(data_field{j_Sh,1},'sensorno') || strcmp(data_field{j_Sh,1},'stat') || strcmp(data_field{j_Sh,1},'unit') || strcmp(data_field{j_Sh,1},'description')
        data.dat1.(data_field{j_Sh,1}) = data_bak.dat1.(data_field{j_Sh,1});
    else
        data.dat1.(data_field{j_Sh,1}) = data_bak.dat1.(data_field{j_Sh,1})(idx_fSh,:);
    end
end

end

% SortTable(end+1,:) = {'Wind shear' 'mean' 0.0 0.3};
% end filter

%% Begin sorting and create table of sorting results, i.e. no. data filtered
ReportSortTable = [num2cell(zeros(size(SortTable,1),1)), SortTable];

for nSort = 1:size(SortTable,1)
    ReportSortTable{nSort,1} = num2str(idx.(SortTable{nSort,1}));
    ReportSortTable{nSort,4} = num2str(SortTable{nSort,3});
    ReportSortTable{nSort,5} = num2str(SortTable{nSort,4});
    ReportSortTable{nSort,6} = num2str(length(data.dat1.mean(:,1)));
    if strcmp(ReportSortTable{nSort,2}, 'turb') == 1
        fprintf('\nSorting by turbulence\n');
    elseif strcmp(ReportSortTable{nSort,2}, 'rho') == 1
        fprintf('\nSorting by air density\n');
    elseif strcmp(ReportSortTable{nSort,2}, 'WShear') == 1
        fprintf('\nSorting by wind shear\n');
    else
        fprintf('\nSorting sensor: %s\n',char(data.dat1.sensorname(idx.(SortTable{nSort,1}))));
    end
    data.dat1 = datsortV2(data.dat1,idx.(SortTable{nSort,1}),SortTable{nSort,2},SortTable{nSort,3},SortTable{nSort,4});
    ReportSortTable{nSort,7} = num2str(length(data.dat1.mean(:,1)));
end

% Auxiliary calculations
if isfield(idx,'pres') && idx.pres >0
    AirDensity = data.dat1.mean(:,idx.rho);
else
    sprintf('Airdensity sensor not specified, set to 1.225')
    AirDensity = zeros(size(data.dat1.mean));
    AirDensity(:,:) = 1.225;
end

if isfield(idx,'Yerr') && idx.Yerr > 0
    YawError = data.dat1.meancir(:,idx.Yerr);
elseif Wdir_YawPos_available == 0
    sprintf('Yaw error not speficied, set to 0 degrees')
    YawError = zeros(size(data.dat1.mean));
    YawError(:,:) = 0;
end

for i=1:length(YawError)
    if YawError(i) > 180
        YawError(i) = YawError(i)-360;
    end
end

if isfield(idx,'WShear') && idx.WShear > 0
    WindShear = data.dat1.mean(:,idx.WShear);
else
    sprintf('Wind shear not speficied, set to 0.2')
    WindShear = zeros(size(data.dat1.mean));
    WindShear(:,:) = 0.2;
end


[CapturMatrx,CapturMatrx_table,TI,MeanWindSpeed_vec] = CreateCaptureMatrix_PP(idx, data, WTG, bin_Vn);
MeanWindSpeed = MeanWindSpeed_vec(:,1); % (:,1) = raw mean wind speed; (:,2) = normalised mean wind speed;


SiteConditionsFig(data,idx,TI,MeanWindSpeed,WTG.TIClass, AirDensity, YawError, WindShear);
%plot(MeanWindSpeed,YawError,'ob','MarkerSize',5);

%% Preparing simulation input
fprintf('\n4. Preparing simulation input \n');

filename = data.dat1.filename;
seed_set={'1','2','3','4','5','6','7','8'};
for i=1:length(filename)
    sets=randperm(8);
    seed{i}=seed_set{sets(1)};
end
curr = pwd;
cd([pwd '\Output'])

% VTS input data preperation
filename_char_length=size(filename{1,1},2);
fid=fopen('Step01_data.txt','wt');
fprintf(fid,'%s\t %22s %12s %12s %12s %12s %12s\n','Name','Wind','turb','vdir','Vexp','rho','seed');
for i=1:length(filename)
    fprintf(fid,strcat('%',num2str(filename_char_length),'s\t %6.2f %12.4f %12.2f %12.2f %12.3f %12s\n'),filename{i},MeanWindSpeed(i),TI(i)/100,YawError(i),WindShear(i),AirDensity(i),seed{i});
end
fclose(fid);

% Sorting VTS-input data to write load cases
fid_read=fopen('Step01_data.txt','r');
fgetl(fid_read);
fid_sorted=fopen('Step01_DLC.txt','wt');

for i=1:length(filename)
    c = fread(fid_read, filename_char_length, 'uint8=>char');
    t_line=fgetl(fid_read);
    line_data=strread(t_line,'%s');
    filedescription=c';
    wsp=(line_data{1,1});
    turb_TI=(line_data{2,1});
    w_dir=(line_data{3,1});
    seed=line_data{6,1};
    wshear=(line_data{4,1});
    rho=(line_data{5,1});
    fprintf(fid_sorted,[filedescription ' wsp= ',wsp,' wdir= ' w_dir,' rho= ' rho,'\n']);
    fprintf(fid_sorted,['ntm ',seed,' Freq 1',' LF 1.00','\n']);
    fprintf(fid_sorted,[num2str(0.1),' ',num2str(2),' ', wsp,' ',w_dir,' turb ',turb_TI,' vexp ',wshear,' rho ',rho,'\n']);
    fprintf(fid_sorted,'\n');
end

fclose(fid);
fclose(fid_sorted);

cd(curr)

%% Saving data
fprintf('\n5. Saving data\n');

CreateBatFiles(dat_path,idx,data);

data.sensornameshort = name; % Saving the names for use in step02

save ([pwd '\Output\MeasurementData'], 'data');
save ([pwd '\Output\Step01_SiteConditions.mat'], 'CapturMatrx','CapturMatrx_table','MeanWindSpeed','TI','AirDensity','WindShear','YawError','filename');
save ([pwd '\Output_Figures\Sorting_LV'],'ReportSortTable')

fclose all;
cd(curr)
