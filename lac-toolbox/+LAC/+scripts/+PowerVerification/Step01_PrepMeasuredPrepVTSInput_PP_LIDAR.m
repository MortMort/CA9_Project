function Step01_PrepMeasuredPrepVTSInput_PP_LIDAR(InputInfo, WTG, bin_Vn, LIDAR_WindShear, LIDAR_Turb, LIDAR_WindVeer, dat_path, vpas_path, TV_filter, LIDAR_quality_filters)

%% Step01_PrepMeasuredPrepVTSInput(Inputfile,Dat_Path,WTG)
% Function to take in measured data, filter it, and create loadcases for
% VTS simulation.
%
% Inputs:
% InputInfo: .xlsx file with information on sensornames and filtering
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
% Modified by YAYDE to add the possibility to use LIDAR data - 19/07/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

import LAC.scripts.PowerVerification.auxiliary.*
import LAC.scripts.PowerVerification.auxiliary.Step01.*

addpath('\\rifile\Group\Group_Technology_RD\Technology Rd Support\Verifikation\Programs\matlab\dat8\');
addpath(dat_path);

% datload_PP
datloadV2;

% Hit Enter-key 3 times
% warndlg('Check that Whöeler slopes are given as m=1,3,4,6,8,10,12 and 25 in .dat files.')

% Converting the sensorlist names into short names without description
for iConv = 1:length(data.dat1.sensorname)
    idxSpace = strfind(data.dat1.sensorname{iConv},' ');
    Fullname = data.dat1.sensorname{iConv};
    if length(idxSpace) >1
        name{iConv} = Fullname(idxSpace(1):idxSpace(2));
    elseif length(idxSpace) == 1
        name{iConv} = Fullname(idxSpace(1):end);
    else
        name{iConv} = Fullname;
    end
end
name = strrep(name,' ', ''); % Remove all spaces in the names

% Save the sensor name
data.sensornameshort = name; % Saving the names for use in step02

%% 2. T&V Filtering
fprintf('\n2. Applying T&V filters \n ');
%
%     TV_data = load(vpas_path, 'data');
%     date_tmp = strrep(data.dat1.filedescription, 'V150Ost2_', '');
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
[~,txt,raw] = xlsread(InputInfo,2);

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

% Calculating turbulence intensity

if LIDAR_Turb == 0
    [data, idx] = TICalc(data,idx);
else
    
    % based on middle height SATI sensor
    %%%%%%%%%%%%%%%%%%%%%%% SATI Signals
    LidarSg=strfind(data.sensornameshort,'SATI');
    iLidSg=not(cellfun('isempty',LidarSg));
    
    %%%%%%%%%%%%%%%%%%%%%% Retrieve heights of signals
    SATIsensors=data.sensornameshort(iLidSg);
    SATIheights=cellfun( @(x) str2double(x(5:end)), SATIsensors,'UniformOutput', false) ;
    [~,iord]=sort([SATIheights{:}]);
    SATIsensorsOrd=SATIsensors(iord);
    
    if mod(length(SATIheights),2)==1
        SATIturbref=SATIsensorsOrd((1+length(SATIheights))/2);
    else
        SATIturbref=SATIsensorsOrd((length(SATIheights))/2);
    end
    
    fprintf('Using %s to calculate the turbulence intensity from Lidar measurements\n',SATIturbref{1});
    iTurbRef=ismember(data.sensornameshort,SATIturbref);
    
    %     turb=data.dat1.mean(:,idx.SATI137);
    turb=data.dat1.mean(:,iTurbRef);
    
    idx.WSP = idx.Lidar_WSP; %other functions e.g. CreateCaptureMatrix, uses idx.WSP to define MeanWindSpeed, so it needs to be changed to Lidar mean wind speed
    data.dat1.sensorname{max(size(data.dat1.sensorname))+1,1}=strcat(num2str(max(size(data.dat1.sensorname))),' Turb_calc');
    data.dat1.sensorno{max(size(data.dat1.sensorno))+1,1}=num2str(max(size(data.dat1.sensorname)));
    data.dat1.unit{max(size(data.dat1.unit))+1,1}='-';
    data.dat1.mean(:,max(size(data.dat1.sensorname)))=turb(:,1);
    idx.turb=max(size(data.dat1.sensorname));
    
    LiDAR_turbdata = data.dat1.mean(:,idx.SATI)./data.dat1.mean(:,iTurbRef);

end

% Calculating air density
if isfield(idx,'pres') && idx.pres >0
    [data, idx] = AirDensityCalc(data,idx);
end % End calc rho


% Calculating normalised wind speed
[data, idx] = WindSpeedNorm(data,idx,WTG.RhoRef);
% End calc wsp norm

%% Begin sorting and create table of sorting results, i.e. no. data filtered
ReportSortTable = [num2cell(zeros(size(SortTable,1),1)), SortTable];


if cell2mat(strfind(SortTable(:,1),'Wshear'))
    sortingNo = size(SortTable,1)-1;
    SortWShear = 1;
else
    sortingNo =size(SortTable,1);
    SortWShear = 0;
end

for nSort = 1:sortingNo % -1 as wind shear is sorted later
    ReportSortTable{nSort,1} = num2str(idx.(SortTable{nSort,1}));
    ReportSortTable{nSort,4} = num2str(SortTable{nSort,3});
    ReportSortTable{nSort,5} = num2str(SortTable{nSort,4});
    ReportSortTable{nSort,6} = num2str(length(data.dat1.mean(:,1)));
    sprintf('Sorting sensor: %s',char(data.dat1.sensorname(idx.(SortTable{nSort,1}))))
    if strcmp(SortTable{nSort,2},'icing')
        data.dat1=datsortV2(data.dat1,[idx.hum idx.temp],SortTable{nSort,2},SortTable{nSort,3},SortTable{nSort,4});
    else
        data.dat1=datsortV2(data.dat1,idx.(SortTable{nSort,1}),SortTable{nSort,2},SortTable{nSort,3},SortTable{nSort,4}); %% Changed from datsort_PP to datsort_nihpe
    end
    ReportSortTable{nSort,7} = num2str(length(data.dat1.mean(:,1)));
end



%% Create .bat files to copy sta and int-files
CreateBatFiles_PP(dat_path,idx,data)

mydata=data;
clear data;
data.dat1=mydata.dat1;
data.sensornameshort = name;

%% Remove '.int' from filedescription strings
data.dat1.filedescription(:)=strrep(data.dat1.filedescription(:),'.int','');

%% 3. calculating wind shear (-)
[data, idx] = WindShearFunction(data,idx);

if SortWShear
    sprintf('Sorting sensor: %s',char(data.dat1.sensorname(idx.WShear)))
    data.dat1 = datsort_wshear(data.dat1,idx.WShear,'mean',SortTable{end,3},SortTable{end,4});
    ReportSortTable{end,1}   = num2str(idx.WShear);
    ReportSortTable{end,4}   = num2str(SortTable{end,3});
    ReportSortTable{end,5}   = num2str(SortTable{end,4});
    ReportSortTable{end,6}   = ReportSortTable{end-1,7};
    ReportSortTable{end,7}   = num2str(length(data.dat1.mean(:,1)));
end

% Save data for samples that passed the first filtering (from vpas and excel file)
save ([pwd '\Output\MeasurementData_all'], 'data');

%% INSERT ADDITIONAL FILTERS FOR LIDAR DQC HERE

if LIDAR_quality_filters
	data = LIDAR_QualityFilters( data );
end

% data = LIDAR_extraFilters_noFilters( data , Dat_Path );
% data = LIDAR_discardNonPhysicalCp( data , WTG);

% Save data for samples that passed the additional requirements (will be used later on to compute the VTS simulations)
save ([pwd '\Output\MeasurementData'], 'data');

%% 3.1 calculating LiDAR wind shear and saving as sheardata.txt (STFRR added 21-05-2019)
if LIDAR_WindShear == 1
    LiDAR_sheardata = data.dat1.mean(:,idx.PHWS)./data.dat1.mean(:,idx.Lidar_WSP);
    
    idx.WSP = idx.Lidar_WSP; %other functions e.g. CreateCaptureMatrix, uses idx.WSP to define MeanWindSpeed, so it needs to be changed to Lidar mean wind speed
    
    curr = pwd;
    cd([pwd '\Output\01_LiDAR_ShearData'])
    mes_length=0;
    for i=1:length(data.dat1.filename)
        disp([repmat(char(8), 1, mes_length+2)]);
        mes = ['Shear file ' num2str(i) ' of ' num2str(length(data.dat1.filename))];
        mes_length = length(mes);
        disp(mes);
        fname = ['sheardata_' num2str(data.dat1.fileno(i)) '.txt'];
        fid=fopen(fname,'wt');
        fprintf(fid,'%d\n',length(LiDAR_sheardata(1,:)));
        for j=1:length(LiDAR_sheardata(1,:))
            fprintf(fid,'%d %12.4f\n',idx.PHWS_Height(1,j),LiDAR_sheardata(i,j));
        end
        fclose(fid);
    end
    
    cd(curr)
end

%% 3.2 Calculating LiDAR Wind Veer
if LIDAR_WindVeer == 1
    
    % based on middle height PWYM sensor
    %%%%%%%%%%%%%%%%%%%%%%% PWYM Signals
    LidarSg=strfind(data.sensornameshort,'PWYM');
    iLidSg=not(cellfun('isempty',LidarSg));
    
    %%%%%%%%%%%%%%%%%%%%%% Retrieve heights of signals
    PWYMsensors=data.sensornameshort(iLidSg);
    PWYMheights=cellfun( @(x) str2double(x(5:end)), PWYMsensors,'UniformOutput', false) ;
    [~,iord]=sort([PWYMheights{:}]);
    PWYMsensorsOrd=PWYMsensors(iord);
    
    if mod(length(PWYMheights),2)==1
        PWYMveerref=PWYMsensorsOrd((1+length(PWYMheights))/2);
    else
        PWYMveerref=PWYMsensorsOrd((length(PWYMheights))/2);
    end
    
    fprintf('Using %s to calculate the wind veer from Lidar measurements\n',PWYMveerref{1});
    iVeerRef=ismember(data.sensornameshort,PWYMveerref);
    
    temp = data.dat1.mean(:,idx.PWYM);
    LiDAR_veerdata = data.dat1.mean(:,idx.PWYM)-data.dat1.mean(:,iVeerRef);
    
    curr = pwd;
    cd([pwd '\Output\03_LiDAR_VeerData'])
    mes_length=0;
    for i=1:length(data.dat1.filename)
        disp([repmat(char(8), 1, mes_length+2)]);
        mes = ['Veer file ' num2str(i) ' of ' num2str(length(data.dat1.filename))];
        mes_length = length(mes);
        disp(mes);
        fname = ['veerdata_' num2str(data.dat1.fileno(i)) '.txt'];
        fid=fopen(fname,'wt');
        fprintf(fid,'%d\n',length(LiDAR_veerdata(1,:)));
        for j=1:length(LiDAR_veerdata(1,:))
            fprintf(fid,'%d %12.4f\n',idx.PWYM_Height(1,j),LiDAR_veerdata(i,j));
        end
        fclose(fid);
    end
    
    cd(curr)
end

% 3.3 writing the turbulence into respective folder for later use
if LIDAR_Turb == 1
    
    % re-calculate LiDAR turbdata becasue its size was not updated when
    % data was filtered out
    LiDAR_turbdata = data.dat1.mean(:,idx.SATI)./data.dat1.mean(:,iTurbRef);
    
    curr = pwd;
    cd([pwd '\Output\02_LiDAR_TurbData'])
    mes_length=0;
    for i=1:length(data.dat1.filename)
        disp([repmat(char(8), 1, mes_length+2)]);
        mes = ['Turb file ' num2str(i) ' of ' num2str(length(data.dat1.filename))];
        mes_length = length(mes);
        disp(mes);
        fname = ['turbdata_' num2str(data.dat1.fileno(i)) '.txt'];
        fid=fopen(fname,'wt');
        fprintf(fid,'%d\n',length(LiDAR_turbdata(1,:)));
        for j=1:length(LiDAR_turbdata(1,:))
            fprintf(fid,'%d %12.4f\n',idx.SATI_Height(1,j),LiDAR_turbdata(i,j));
        end
        fclose(fid);
    end
    
    cd(curr)    
end


%% 4. a-  Saving yaw error (deg) for Site Conditions overview
if isfield(idx,'Yerr') && idx.Yerr > 0
    YawError = data.dat1.mean(:,idx.Yerr);
elseif Wdir_YawPos_available == 0
    sprintf('Yaw error not speficied, set to 0 degrees')
    YawError = zeros(size(data.dat1.mean));
    YawError(:,:) = 0;
end

%% 4. b- calculating air density (kg/m^3) for Site Conditions overview
if isfield(idx,'pres') && idx.pres >0
    AirDensity = data.dat1.mean(:,idx.rho);
else
    sprintf('Airdensity sensor not specified, set to 1.225')
    AirDensity = zeros(size(data.dat1.mean));
    AirDensity(:,:) = 1.225;
end

%% 4. c- Calculating wind shear for Site Conditions overview
WindShear = data.dat1.mean(:,max(size(data.dat1.sensorname)));

%% 4. d- creating capture matrix for normal operation
% Created the capture matrix used for the word report, saved further down
% in Step01_SiteConditions.mat
[CapturMatrx,CapturMatrx_table,TI,MeanWindSpeed] = CreateCaptureMatrix_PP(idx,data,WTG, bin_Vn);


%% 5. plotting site wind condition Versus design conditions
% Creates the figure containing TI, wind shear, air density and yaw error
% and save in \Output_Figures\ folder
SiteConditionsFig(data,idx,TI,MeanWindSpeed,WTG.TIClass, AirDensity, YawError, WindShear)


%% 6. saving the results
filename = data.dat1.filename;
save ([pwd '\Output\Step01_SiteConditions.mat'], 'CapturMatrx','CapturMatrx_table','MeanWindSpeed','TI','AirDensity','WindShear','YawError','filename');

%% 7. Prepare simulation prep input .txt file ... only loadcase writing
% - randomization of seeds
seed_set={'1','2','3','4','5','6','7','8'};
for i=1:length(filename)
    sets=randperm(8);
    seed{i}=seed_set{sets(1)};
end;

curr = pwd;
cd([pwd '\Output'])

% VTS input data preperation
filename_char_length=size(filename{1,1},2);
fid=fopen('Step01_data.txt','wt');
fprintf(fid,'%s\t %22s %12s %12s %12s %12s %12s\n','Name','Wind','turb','vdir','Vexp','rho','seed');
for i=1:length(filename)
    fprintf(fid,strcat('%',num2str(filename_char_length),'s\t %6.2f %12.4f %12.2f %12.2f %12.3f %12s\n'),filename{i},MeanWindSpeed(i),TI(i)/100,YawError(i),WindShear(i),AirDensity(i),seed{i});
end;

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
    % #####STFRR
    line1 = [num2str(0.1),' ',num2str(2),' ', wsp,' ',w_dir,' turb ',turb_TI,' vexp ',wshear,' rho ',rho];
    line2 = '';
    line3 = '';
    line4 = '';
    if LIDAR_WindShear == 1
        line2 = [' Sheardat ',curr,'\Output\01_LiDAR_ShearData\sheardata_',num2str(data.dat1.fileno(i)),'.txt'];
    end
    if LIDAR_Turb == 1
        line3 = [' TurbHeightScale ',curr,'\Output\02_LiDAR_TurbData\turbdata_',num2str(data.dat1.fileno(i)),'.txt'];
    end
    if LIDAR_WindVeer == 1
        line4 = [' WDirHeightOffset ',curr,'\Output\03_LiDAR_VeerData\veerdata_',num2str(data.dat1.fileno(i)),'.txt'];
    end
    fprintf(fid_sorted, '%s',[line1, line2, line3, line4]);
    fprintf(fid_sorted,'\n');
    fprintf(fid_sorted,'\n');
    save([pwd '\Sorting_LV'],'ReportSortTable')
end

fclose(fid);
fclose(fid_sorted);

cd(curr)


