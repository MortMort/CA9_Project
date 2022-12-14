function Step02_ProcessSimuSta_CreateSensorListInput_PP(Inputfile,StaPath,WTG)
%% Purpose of this script: ------------------------------------------------------------
%  First perform the VTS simulation with the loadcase txt file created in Step01
% (i) This .m file is for creating the sensor list which will be
%     refered in the later stages of the varification process. i.e. for
%     plotting & comparing the results & generating report.
% (ii)Reading of simulation ".sta" files by using 'stareadTL.m' file from "W:\source\TLtoolbox\"
%     and converting postprocessed data in data.dat1 format like measurement.
%% Given below are the few points to follow -
%  1. Please, change the inputs in following section as per requirement
%  2. Change the main code only if needed.
%  3. Remember that everything is been cleared from work  space at the end of this script.

%% Revision history
%%      Revision     Date        Author    Description of update
%       Rev0      3-Dec-2010     PRZIN       Initial script
%       Rev1      14-03-2011     JAVES     added compatibility with pitch loads
%       Rev2     25-Apr-2018     RUSJE    Moved input, and added VTS sensornumbers
%       Rev3     16/05/2019      MODFY    Modification to fit the power
%                                         performance verification. The 
%                                         original script is name as 
%                                         Step02_ProcessSimuSta_CreateSensorListInput
%                                         The output '*.mat' contains the
%                                         measurement data limited to the
%                                         number of the sensor to
%                                         investigate.

%% Input starts: ------------------------------------------------------------
    
	import LAC.scripts.PowerVerification.auxiliary.*
	import LAC.scripts.PowerVerification.auxiliary.Step02.*
	
	addpath([pwd '\Output\'])
    load MeasurementData.mat; 

    name = data.sensornameshort; % Short version of sensornames in meas. data
% Reading the input file, here it should be described what sensors to look
% at, and how to group them
[~,txt,raw2] = xlsread(Inputfile,3);

iSensornameS = find(contains(txt,'START_SENSORLIST'));
iSensornameE = find(contains(txt,'END_SENSORLIST'));
% Loop over all sensornames in input file. Extracts the meas. sensorname
% and compares with the sensorlist in MeasurementData.mat to find the
% sensor number. 
for iName=iSensornameS+1:iSensornameE-1
    Description{iName-iSensornameS} = raw2{iName,1};
    SimSens{iName-iSensornameS}     = raw2{iName,2};
    MeasSens{iName-iSensornameS}    = raw2{iName,3};
    SensorList.sens(iName-iSensornameS,1) = raw2{iName,4};
    SensorList.sens(iName-iSensornameS,2) = find(strcmpi(name,raw2{iName,3}) == 1);
end

% Create the sensorlist.sensorname, Description is used in report to
% describe the sensors, SimSens is used to find the sensor in simulations
SensorList.sensorname = [Description'  SimSens'];

% Start the grouping of sensors
iGroupingS = find(contains(txt,'START_GROUPING'));
iGroupingE = find(contains(txt,'END_GROUPING'));

for iGrp = iGroupingS+1:iGroupingE-1
    if isnan(raw2{iGrp,2})
        continue
    else
        if isa(raw2{iGrp,2},'double')
            SensorList.(raw2{iGrp,1}) = raw2{iGrp,2};
        else
            SensorList.(raw2{iGrp,1}) = str2num(raw2{iGrp,2});
        end
    end
end

%% Inputs end here -----------------------------------------------------


%% ****** Main code starts here *********************************
%% 0. Rearranging 

%% 1. Getting simulation data in data.dat1 format like measurement
    for i = 1:length(SensorList.sensorname(:,2))

        fprintf('Sensor %d of %d\n', i, length(SensorList.sensorname(:,2)));
        
        [simstat] = stareadTL({(SensorList.sensorname{i,2})},StaPath,'*.sta',false,true);
        
        myfield  = fieldnames(simstat);
        Simdata.dat1.max(:,i)  = simstat.(myfield{1}).max;
        Simdata.dat1.mean(:,i) = simstat.(myfield{1}).mean;
        Simdata.dat1.min(:,i)  = simstat.(myfield{1}).min;
        Simdata.dat1.std(:,i)  = simstat.(myfield{1}).std;
        Simdata.dat1.sensorname{i,1} = (SensorList.sensorname{i,1});
        Simdata.dat1.sensorno{i,1} = i;
    end
    Simdata.dat1.filedescription  = simstat.DLC;
    

    
    %% Find sensornumbers for vts sensors
    curr = pwd;
    cd(StaPath)          % go to the sta-files
    files=dir('*.sta');  % Captures all sta-files
    fatigueoption = true;
    [StaDat]=ReadStaCore(files(1,1).name,0);
    ChDesc = StaDat(1,2);
      
    for iVTS = 1:length({(SensorList.sensorname{:,2})})
        if strcmp(SensorList.sensorname(iVTS,2),'Fpi11') || strcmp(SensorList.sensorname(iVTS,2),'Fpi21') || strcmp(SensorList.sensorname(iVTS,2),'Fpi31')
            continue
            VTSsens(iVTS) = find(strcmpi(ChDescPi{:},{(SensorList.sensorname{iVTS,2})}) == 1);
        else
            VTSsens(iVTS) = find(strcmpi(ChDesc{:},{(SensorList.sensorname{iVTS,2})}) == 1);
        end
    end
    SensorList.VTSsens = VTSsens;
    
%% 2. Reducing the number of sensor in data to the ones of interest
% aim: similar structure than Simdata + air density, shear exponent,
% turbulence, normalised ws

    Meas_sens = SensorList.sens(:,2)';
    
    % Site Conditions Sensors (TI, Air Density, Shear) and Normalised WSP
    sensors_added_no = size(data.dat1.min,2)+1:size(data.dat1.mean,2); % changed from  min(size(data.dat1.min))+1:min(size(data.dat1.mean)) which provides faulse results when number of measurements close to number of sensors
    %sensors_added_no = [431 432 433 434];
   
    % Measurements - store the data
    mydata.dat1.max  = data.dat1.max(:,Meas_sens);
    mydata.dat1.mean = data.dat1.mean(:,[Meas_sens, sensors_added_no]);
    mydata.dat1.min  = data.dat1.min(:,Meas_sens);
    mydata.dat1.std  = data.dat1.std(:,Meas_sens);
    
    % Simulations - store and update the data 
    if length(Simdata.dat1.filedescription) > length(data.dat1.filedescription)
    idx_data = (contains(Simdata.dat1.filedescription,data.dat1.filedescription));
    field_Sdata = fieldnames(Simdata.dat1);
    for i_field = 1:length(field_Sdata)
       if strcmp(field_Sdata{i_field} ,'sensorname') || strcmp(field_Sdata{i_field} ,'sensorno')
           mySimdata.dat1.(field_Sdata{i_field}) = Simdata.dat1.(field_Sdata{i_field});
       else
           mySimdata.dat1.(field_Sdata{i_field}) = Simdata.dat1.(field_Sdata{i_field})(idx_data,:);
       end
    end
    else         
    mySimdata = Simdata;
    end
            % adding the data from site conditions to sensor except from
            % the normalize wind speed
            idx_WSPnorm = find(contains(data.dat1.sensorname,'WSP norm')==1);
            initial_length_1 = size(mySimdata.dat1.mean);
            initial_length_2 = initial_length_1(2);
            for i = 1:length(sensors_added_no)
                if sensors_added_no(i) ~= idx_WSPnorm
                    mySimdata.dat1.mean = [mySimdata.dat1.mean data.dat1.mean(:,sensors_added_no(i))];
                else
                    % Compute normalize wind speed
                    idx_wsp_1 = find(contains(SensorList.sensorname(:,1),'Wind speed (m/s)')==1);
                    idx_wsp_2 = SensorList.sens(idx_wsp_1);
                    idx_rho_1 = find(contains(data.dat1.sensorname,'AirDensity_calc')==1);
                    idx_rho_2 = find(sensors_added_no == idx_rho_1);
                    WSPnorm_array = mySimdata.dat1.mean(:,idx_wsp_2).*(mySimdata.dat1.mean(:,idx_rho_2+initial_length_2)/WTG.RhoRef).^(1/3);
                    mySimdata.dat1.mean = [mySimdata.dat1.mean WSPnorm_array];
                end
            end
            
    % Measurements - sensor name, number and file description
    mydata.dat1.sensorname = Simdata.dat1.sensorname;
    length_sensorname_init = length(mydata.dat1.sensorname);
    mydata.dat1.sensorname(length_sensorname_init+1:length_sensorname_init+length(sensors_added_no),1) = data.dat1.sensorname(sensors_added_no,1);
    
    % Measurements - update sensor list name
    index = find(contains(mydata.dat1.sensorname, 'Turb')==1);
    if isempty(index)==0
        mydata.dat1.sensorname(index,1)={'Turb calc (%)'};
    end
    
    index = find(contains(mydata.dat1.sensorname, 'Shear')==1);
    if isempty(index)==0
        mydata.dat1.sensorname(index,1)={'Wind shear (-)'};
    end
    
    index = find(contains(mydata.dat1.sensorname, 'Air')==1);
    if isempty(index)==0
        mydata.dat1.sensorname(index,1)={'Air density (kg/m3)'};
    end
    
    index = find(contains(mydata.dat1.sensorname, 'norm')==1);
    if isempty(index)==0
        mydata.dat1.sensorname(index,1)={'Wind speed normalised (m/s)'};
    end

    % Measurement - update sensor list number
    mydata.dat1.sensorno = Simdata.dat1.sensorno;
    for i=length_sensorname_init+1:length_sensorname_init+length(sensors_added_no)
        mydata.dat1.sensorno(i,1) = {i};   
    end
    
    mydata.dat1.filedescription = data.dat1.filedescription;
    
    % Simulations
    mySimdata.dat1.sensorname = mydata.dat1.sensorname;
    mySimdata.dat1.sensorno = mydata.dat1.sensorno;
    
%% 3. Update sensor List
    
    sens_length_old = length(SensorList.sens(:,1));
    sens_length_new = length(mydata.dat1.sensorname);
    
    j =1;
    for i = sens_length_old+1:sens_length_new
        SensorList.sens(i,1) = i;
        SensorList.sens(i,2) = sensors_added_no(j);
        SensorList.sensorname(i,1) = mydata.dat1.sensorname(i,1);
        if contains(mydata.dat1.sensorname(i,1), 'norm')
            SensorList.sensorname(i,2) = {'Vn'};
        elseif contains(mydata.dat1.sensorname(i,1), 'shear')
            SensorList.sensorname(i,2) = {'WShear'};
        elseif contains(mydata.dat1.sensorname(i,1), 'Turb')
            SensorList.sensorname(i,2) = {'TI'};
        elseif contains(mydata.dat1.sensorname(i,1), 'Air')
            SensorList.sensorname(i,2) = {'rho'};
        end
        j=j+1;
    end
    
    SensorList.toplot = SensorList.Control_PwRpmPiAll;
    SensorList.toplot =  [SensorList.toplot sens_length_old+1:sens_length_new];
    
%% 4. Save mydata/mySimdata in data/Simdata
    
    clear sensors_added_no length_sensorname_init index
    clear data Simdata
    
    data = mydata;
    Simdata = mySimdata;
%% 4. saving the simdata & sensor list
    cd([curr '\Output\'])
save ('Step02_SensorlistInput', 'SensorList');
save ('Step02_VTS_simulation', 'Simdata', 'data');
cd([pwd '\..\'])

%% clearing the work space

clear all;