function CompareRatiosVscVts(Rotor,Hub_radius,Extreme_loads,OutFolder,FileName,VSC_File,VTS_MainFile,NrConfigs,ModeIndex,PostloadsRef,CombineTwrFndDesign,TwrFndFlag)
%% Function to compare VSC (from LoadView) and VTS load ratios to design and compute difference (Ratio_VSC - Ratio_VTS)
% Note: Not compatible with load distiller sensors
%
% SYNTAX:
% LAC.vsc.CompareRatiosVscVts(Rotor,Hub_radius,Extreme_loads,OutFolder,FileName,VSC_File,VTS_MainFile,NrConfigs,ModeIndex,PostloadsRef,CombineTwrFndDesign)
%
% INPUTS:
% Rotor - Rotor diameter (ex: 162)
% Hub_radius - Hub radius (ex: 1.65)
% Extreme_loads - Flag to specify whether we have extreme loads module in VSC model (1 if available)
% OutFolder - Folder to save output file
% FileName - Name of the output file, should include *.txt extension (ex: 'Ratios_VSC_VTS_NTMFat.txt')
% VSC_File - File with VSC ratios from LoadView (ex: 'h:\vidar\investigations\451_VSC_V162_L10\V162_DIBT_HH169_STD_STE_HA2A9\_VSCloadview\Ratios_LoadView\Ratios_NTM_Fat_5.4MW.txt')
% VTS_MainFile - File with baseline loads comparison to design ('CompareMainLoadRatio.txt' file)
% NrConfigs - Number of references compared to design in VTS_MainFile (ex: 3 if three load/power modes considered in the comparison)
% ModeIndex - Index of the reference to compare (ex: 2 if the reference to compare is the 2nd in the VTS_MainFile)
% PostloadsRef - Path to baseline postloads folder
% CombineTwrFndDesign - Path to combine TWR/FND design loads used in VSC model
% TwrFndFlag - Flag to specify whether we want to evaluate TWR/FND loads (not needed for ES/RS models)
%
% OUTPUTS:
% Text file (location: [OutFolder]\[Filename]) with VTS and VSCloadview ratios to design and difference between these (absolute diff, in %)
% Example of output file in: 'h:\vidar\investigations\451_VSC_V162_L10\V162_DIBT_HH169_STD_STE_HA2A9\_VSCloadview\Ratios_Compare_VTS_testScript\Ratios_VSC_VTS_NTMFat_5.4MW.txt'
%
% VERSIONS:
% 25/03/2021 - AAMES: V00
% 13/01/2022 - AAMES: V01 - Update sensors to accomodate GRS system and new VSCloadview sensor naming; add flag to choose whether to run TWR/FND comparison (not needed for RS and ES)

%% Paths
FilePath = fullfile(OutFolder,FileName);
% FND loads
PostloadsRef_Fnd    = fullfile(PostloadsRef,'FND','FNDload.txt');
Design_Fnd          = fullfile(CombineTwrFndDesign,'FND','FNDload.txt');
% VSC loads - For TWR/FND fatigue
PostloadsRef_VscFat    = fullfile(PostloadsRef,'VSC','VSCload.txt');
Design_VscFat          = fullfile(CombineTwrFndDesign,'VSC','VSCload.txt');

%% Get VSC - VTS correspondence
[sensors_main_fat, sensors_main_ext, sensors_twrfnd_fat, sensors_twrfnd_ext] = getSensorsCorrespondence(Hub_radius,Rotor);

%% Read VSCLoadView output files
fid = fopen(VSC_File, 'r');
VSC_Data = textscan(fid,'%s','Delimiter','\n');
VSC_Data = VSC_Data{1,1};
fclose(fid);

% Find fatigue
indxFatVSC = find(~cellfun(@isempty,strfind(VSC_Data,'Fatigue Loads')));
Sensors_VSC_Fat = strsplit(VSC_Data{indxFatVSC+2},'\t');
Sensors_VSC_Fat = deblank(Sensors_VSC_Fat(2:end));
Ratios_VSC_Fat = strsplit(VSC_Data{indxFatVSC+3},'\t');
indxFatVSC_ratios = find(~cellfun(@isempty,strfind(Ratios_VSC_Fat,'DirFat')))+1;
Ratios_VSC_Fat = str2double(Ratios_VSC_Fat(indxFatVSC_ratios:end));
Ratios_Analyse_Fat = find(Ratios_VSC_Fat>1);
Sensors_VSC_Fat = Sensors_VSC_Fat(Ratios_Analyse_Fat);
Ratios_VSC_Fat = Ratios_VSC_Fat(Ratios_Analyse_Fat)/100;

% Find extreme
switch Extreme_loads
    case 1
        indxExtVSC = find(~cellfun(@isempty,strfind(VSC_Data,'Extreme Loads')));
        Sensors_VSC_Ext = strsplit(VSC_Data{indxExtVSC+2},'\t');
        Sensors_VSC_Ext = deblank(Sensors_VSC_Ext(2:end));
        Ratios_VSC_Ext = strsplit(VSC_Data{indxExtVSC+3},'\t');
        indxExtVSC_ratios = find(~cellfun(@isempty,strfind(Ratios_VSC_Ext,'DirFat')))+1;
        Ratios_VSC_Ext = str2double(Ratios_VSC_Ext(indxExtVSC_ratios:end));
        Ratios_Analyse_Ext = find(Ratios_VSC_Ext>1);
        Sensors_VSC_Ext = Sensors_VSC_Ext(Ratios_Analyse_Ext);
        Ratios_VSC_Ext = Ratios_VSC_Ext(Ratios_Analyse_Ext)/100;
        
        % Find extreme LC
        indxExtLCVSC = find(~cellfun(@isempty,strfind(VSC_Data,'Extreme Load Case')));
        LCs_VSC_Ext = strsplit(VSC_Data{indxExtLCVSC+3},'\t');
        indxExtLCVSC_ratios = find(~cellfun(@isempty,strfind(LCs_VSC_Ext,'DirFat')))+1;
        LCs_VSC_Ext = deblank(LCs_VSC_Ext(indxExtLCVSC_ratios:end));
        LCs_VSC_Ext = LCs_VSC_Ext(Ratios_Analyse_Ext);
end

% Split between main load and twr/fnd sensors
% Fatigue
indtwrSens = find(~cellfun(@isempty,strfind(Sensors_VSC_Fat,'_Twr_')));
Sensors_MainVSC_Fat = Sensors_VSC_Fat(1:indtwrSens(1)-1);
Ratios_MainVSC_Fat = Ratios_VSC_Fat(1:indtwrSens(1)-1);
Sensors_TwrVSC_Fat = Sensors_VSC_Fat(indtwrSens(1):end);
Ratios_TwrVSC_Fat = Ratios_VSC_Fat(indtwrSens(1):end);
% Extreme
switch Extreme_loads
    case 1
        indtwrSensExt = find(~cellfun(@isempty,strfind(Sensors_VSC_Ext,'TwrBot')));
        Sensors_MainVSC_Ext = Sensors_VSC_Ext(1:indtwrSensExt(1)-1);
        Ratios_MainVSC_Ext = Ratios_VSC_Ext(1:indtwrSensExt(1)-1);
        LCs_MainVSC_Ext = LCs_VSC_Ext(1:indtwrSensExt(1)-1);
        Sensors_TwrVSC_Ext = Sensors_VSC_Ext(indtwrSensExt(1):end-4);
        Ratios_TwrVSC_Ext = Ratios_VSC_Ext(indtwrSensExt(1):end-4);
        LCs_TwrVSC_Ext = LCs_VSC_Ext(indtwrSensExt(1):end-4);
end

%% Read VTS Comparison File
fid = fopen(VTS_MainFile, 'r');
VTS_Data = textscan(fid,'%s','Delimiter','\n');
VTS_Data = VTS_Data{1,1};
fclose(fid);

% Get relevant sensors
Sensors_MainVTS_Fat = cell(length(Sensors_MainVSC_Fat),1);
sensorsVscFat_ForCorr = sensors_main_fat.vsc;
for s = 1:length(Sensors_MainVSC_Fat)
    Sensors_MainVTS_Fat{s} = sensors_main_fat.vts{strcmp(sensorsVscFat_ForCorr,Sensors_MainVSC_Fat{s})};
end

switch Extreme_loads
    case 1
        Sensors_MainVTS_Ext = cell(length(Sensors_MainVSC_Ext),1);
        sensorsVscExt_ForCorr = sensors_main_ext.vsc;
        for s = 1:length(Sensors_MainVSC_Ext)
            Sensors_MainVTS_Ext{s} = sensors_main_ext.vts{strcmp(sensorsVscExt_ForCorr,Sensors_MainVSC_Ext{s})};
        end
end

%% Look for ratios
% Fatigue
Ratios_MainVTS_Fat = cell(length(Sensors_MainVTS_Fat),1);
for k = 1:length(Sensors_MainVTS_Fat)
    ind = strfind(VTS_Data,Sensors_MainVTS_Fat{k});
    indx = find(~cellfun(@isempty,ind));
    Data_Sensor = regexp(VTS_Data{indx},'\d+\.\d*','match');
    Ratios_MainVTS_Fat(k) = Data_Sensor(end-(NrConfigs-ModeIndex));
    Design_MainVTS_Fat(k) = Data_Sensor(2);
end

% Extreme
switch Extreme_loads
    case 1
        Ratios_MainVTS_Ext = cell(length(Sensors_MainVTS_Ext),1);
        LCs_MainVTS_Ext = cell(length(Sensors_MainVTS_Ext),1);
        for k = 1:length(Sensors_MainVTS_Ext)
            ind = strfind(VTS_Data,Sensors_MainVTS_Ext{k});
            indx = find(~cellfun(@isempty,ind));
            indxLoad = indx(1);
            Data_Sensor = regexp(VTS_Data{indxLoad},'\d+\.\d*','match');
            Ratios_MainVTS_Ext(k) = Data_Sensor(end-(NrConfigs-ModeIndex));
            indxLC = indx(2);
            Data_Sensor = regexp(VTS_Data{indxLC},'\d+[a-zA-Z]\w*','match');
            LCs_MainVTS_Ext(k) = Data_Sensor(end-(NrConfigs-ModeIndex));
        end
end

%% Calculate difference - Fat
Ratios_VTS_Fat = str2double(Ratios_MainVTS_Fat)';
DiffFat = 100*(Ratios_MainVSC_Fat-Ratios_VTS_Fat);
for k = 1:length(DiffFat)
    DiffFatCell{k,1} = sprintf('%.2f %%',DiffFat(k));
end

%% Read VSCload data - Twr/Fnd fat
if TwrFndFlag
    fid = fopen(PostloadsRef_VscFat,'r');
    VscFat_Ref_Data = textscan(fid,'%s','Delimiter','\n');
    VscFat_Ref_Data = VscFat_Ref_Data{1,1};
    fclose(fid);
    fid = fopen(Design_VscFat,'r');
    VscFat_Design_Data = textscan(fid,'%s','Delimiter','\n');
    VscFat_Design_Data = VscFat_Design_Data{1,1};
    fclose(fid);
    
    % Get relevant sensors
    Sensors_TwrVTS_Fat = cell(length(Sensors_TwrVSC_Fat),1);
    sensorsTwrVscFat_ForCorr = sensors_twrfnd_fat.vsc;
    for s = 1:length(Sensors_TwrVSC_Fat)
        Sensors_TwrVTS_Fat{s} = sensors_twrfnd_fat.vts{strcmp(sensorsTwrVscFat_ForCorr,Sensors_TwrVSC_Fat{s})};
    end
    
    % Get relevant ratios
    RatiosVscLoad = zeros(1,length(Sensors_TwrVTS_Fat));
    for st = 1:length(Sensors_TwrVTS_Fat)
        VscLoad_Design(st) = getVscLoadData(VscFat_Design_Data, Sensors_TwrVTS_Fat{st});
        VscLoad_Ref(st) = getVscLoadData(VscFat_Ref_Data, Sensors_TwrVTS_Fat{st});
        RatiosVscLoad(st) = VscLoad_Ref(st)/VscLoad_Design(st);
    end
    
    DiffFatTwrFnd = 100*(Ratios_TwrVSC_Fat - RatiosVscLoad);
    for k = 1:length(DiffFatTwrFnd)
        DiffFatTwrFndCell{k,1} = sprintf('%.2f %%',DiffFatTwrFnd(k));
    end
end

%% Calculate difference -  Extreme

switch Extreme_loads
    case 1
        Ratios_VTS_Ext = str2double(Ratios_MainVTS_Ext)';
        DiffExt = 100*(Ratios_MainVSC_Ext-Ratios_VTS_Ext);
        for k = 1:length(DiffExt)
            DiffExtCell{k,1} = sprintf('%.2f %%',DiffExt(k));
        end
        
        if TwrFndFlag
            % Read FNDload data
            FND_Design_Data = LAC.intpostd.convert(Design_Fnd,'FND');
            FND_Ref_Data = LAC.intpostd.convert(PostloadsRef_Fnd,'FND');
            FND_Design_Loads = FND_Design_Data.ExtremeLoads_ExclPLF_SortedwithPLF;
            FND_Ref_Loads = FND_Ref_Data.ExtremeLoads_ExclPLF_SortedwithPLF;
            
            % Get relevant sensors
            Sensors_TwrVTS_Ext = cell(length(Sensors_TwrVSC_Ext),1);
            sensorsTwrVscExt_ForCorr = sensors_twrfnd_ext.vsc;
            for s = 1:length(Sensors_TwrVSC_Ext)
                Sensors_TwrVTS_Ext{s} = sensors_twrfnd_ext.vts{strcmp(sensorsTwrVscExt_ForCorr,Sensors_TwrVSC_Ext{s})};
            end
            
            % Get relevant ratios
            RatiosFnd = zeros(length(Sensors_TwrVTS_Ext),1);
            LoadsFnd_DLC = cell(length(Sensors_TwrVTS_Ext),1);
            for st = 1:length(Sensors_TwrVTS_Ext)
                FndLoad_Design = [FND_Design_Loads(1).(Sensors_TwrVTS_Ext{st})].*[FND_Design_Loads(1).PLF];
                FndLoad_Ref = [FND_Ref_Loads(1).(Sensors_TwrVTS_Ext{st})].*[FND_Ref_Loads(1).PLF];
                LoadsFnd_DLC{st} = FND_Ref_Loads(1).LC;
                RatiosFnd(st) = FndLoad_Ref/FndLoad_Design;
            end
            
            % Compare VTS ratios to VSC
            DiffExtFnd = 100*(Ratios_TwrVSC_Ext-RatiosFnd);
            for k = 1:length(DiffExtFnd)
                DiffExtFndCell{k,1} = sprintf('%.2f %%',DiffExtFnd(k));
            end
        end
end


%% Save data in txtfile
cellDataFat = [Sensors_MainVSC_Fat' cellstr(num2str((Ratios_MainVSC_Fat.*str2double(Design_MainVTS_Fat))','%.2f')) cellstr(num2str(Ratios_MainVSC_Fat','%.3f'))...
    Sensors_MainVTS_Fat Design_MainVTS_Fat' Ratios_MainVTS_Fat DiffFatCell]';
fid = fopen(FilePath,'w');
fprintf(fid,'---------------------------------------- Fatigue loads ----------------------------------------\n\n');
fprintf(fid,'%20s\t\t%10s\t\t%10s\t\t%35s\t\t%10s\t\t%10s\t\t%10s\n\n','Sensor VSC','Design VSC','Ratio VSC','Sensor VTS','Design VTS', 'Ratio VTS','Diff between ratios');
fprintf(fid,'%20s\t\t%10s\t\t%10s\t\t%35s\t\t%10s\t\t%10s\t\t%10s\n',cellDataFat{:,:});

if TwrFndFlag
    cellDataFatTwrFnd = [Sensors_TwrVSC_Fat' ...
        cellstr(num2str((Ratios_TwrVSC_Fat.*VscLoad_Design)','%.2f')) ...
        cellstr(num2str(Ratios_TwrVSC_Fat')) ...
        Sensors_TwrVTS_Fat cellstr(num2str(VscLoad_Design')) cellstr(num2str(RatiosVscLoad')) DiffFatTwrFndCell]';
    
    fprintf(fid,'\n------------------------------------- Fatigue TWR/FND loads ------------------------------------\n\n');
    fprintf(fid,'%20s\t\t%10s\t\t%10s\t\t%35s\t\t%10s\t\t%10s\t\t%10s\n\n','Sensor VSC','Design VSC','Ratio VSC','Sensor VTS','Design VTS','Ratio VTS','Diff between ratios');
    fprintf(fid,'%20s\t\t%10s\t\t%10s\t\t%35s\t\t%10s\t\t%10s\t\t%10s\n',cellDataFatTwrFnd{:,:});
end


switch Extreme_loads
    case 1
        cellDataExt = [Sensors_MainVSC_Ext' cellstr(num2str(Ratios_MainVSC_Ext'))...
            Sensors_MainVTS_Ext Ratios_MainVTS_Ext DiffExtCell LCs_MainVSC_Ext' LCs_MainVTS_Ext]';
        if TwrFndFlag
            cellDataFndExt = [ Sensors_TwrVSC_Ext' ...
                cellstr(num2str(Ratios_TwrVSC_Ext')) ...
                Sensors_TwrVTS_Ext cellstr(num2str(RatiosFnd)) DiffExtFndCell LCs_TwrVSC_Ext' LoadsFnd_DLC ]';
        end
        fprintf(fid,'\n-------------------------------------- Extreme loads ----------------------------------------\n\n');
        fprintf(fid,'%20s\t\t%10s\t\t%35s\t\t%10s\t\t%10s\t\t%10s\t\t%20s\n\n','Sensor VSC','Ratio VSC','Sensor VTS','Ratio VTS','Diff between ratios', 'DLC VSC', 'DLC VTS');
        fprintf(fid,'%20s\t\t%10s\t\t%35s\t\t%10s\t\t%10s\t\t%20s\t\t%20s\n',cellDataExt{:,:});
        if TwrFndFlag
            fprintf(fid,'\n----------------------------------- Extreme FND loads -------------------------------------\n\n');
            fprintf(fid,'%20s\t\t%10s\t\t%35s\t\t%10s\t\t%10s\t\t%10s\t\t%20s\n\n','Sensor VSC','Ratio VSC','Sensor VTS','Ratio VTS','Diff between ratios','DLC VSC', 'DLC VTS');
            fprintf(fid,'%20s\t\t%10s\t\t%35s\t\t%10s\t\t%10s\t\t%20s\t\t%20s\n',cellDataFndExt{:,:});
        end
end

fclose(fid);

%% Print results
fprintf('Results in:\n%s\n',FilePath);

end

function [sensor_val] = getVscLoadData(txtData, sensor)
%% Auxiliary function to get loads from 'VSCload.txt' file
ind_s = find(~cellfun(@isempty,strfind(txtData,'@rfc_d@')));
ind_e = find(~cellfun(@isempty,strfind(txtData,'@#rfc_d@')));
rfc_data = txtData(ind_s:ind_e);
sensorvscload = strsplit(sensor,'_'); sensorvscload = sensorvscload{1};
sensor_ind = find(~cellfun(@isempty,strfind(rfc_data,sensorvscload)));
% wholers = 4, 8, 10
data_sensor = strsplit(rfc_data{sensor_ind});
if contains(sensor,'Rfc_m=4')
    sensor_val = str2double(data_sensor{2});
elseif contains(sensor,'Rfc_m=8')
    sensor_val = str2double(data_sensor{3});
elseif contains(sensor,'Rfc_m=10')
    sensor_val = str2double(data_sensor{4});
end
end

function [sensors_main_fat, sensors_main_ext, sensors_twrfnd_fat, sensors_twrfnd_ext] = getSensorsCorrespondence(Hub_radius, Rotor)
%% Function to get correspondence between VSC and VTS (from MainLoad) sensors
% Values are hardcoded based on the sensors name from:
% VSC - Sensor names in XML, updated VSCXMLgenerator version in 13/01/2021
% VTS - RNA sensors correpond to the format in 'CompareMainLoadRatio' files; TWR/FND sensors are similar to the format in 'VSCload' file (for fatigue, 'Rfc_m=X' has been added) and 'FNDload' file (for extreme)
sensors_main_fat.vts = {
    sprintf('B?Mx%05d    [kNm]   Rfc,m=10.00', Hub_radius*100);  % To get correct name for BLD sensor at BLD root, corresponding to VSC sensor MxBldRoot
    sprintf('B?My%05d    [kNm]   Rfc,m=10.00', Hub_radius*100);
    sprintf('B?Mx%05d    [kNm]   Rfc,m=10.00',Rotor/4*100);      % To get correct name for BLD sensor at middle of the blade (50% of BLD length), corresponding to VSC sensor MxBldMid
    sprintf('B?My%05d    [kNm]   Rfc,m=10.00',Rotor/4*100);
    'Mr?          [kNm]    Lrd,m=3.33';
    'Mr?          [kNm]    Lrd,m=3.00';
    'Mr?          [kNm]    Lrd,m=3.33';
    'Mr?          [kNm]    Lrd,m=3.00';
    '-Mx?1h       [kNm]    Rfc,m=4.00';
    '-Mx?1h       [kNm]    Rfc,m=8.00';
    'My?1h        [kNm]    Rfc,m=4.00';
    'My?1h        [kNm]    Rfc,m=8.00';
    'MxMBr        [kNm]    Rfc,m=4.00';
    'MxMBr        [kNm]    Rfc,m=8.00';
    'MyMBr        [kNm]    Rfc,m=4.00';
    'MyMBr        [kNm]    Rfc,m=8.00';
    'MzMBr        [kNm]    Rfc,m=4.00';
    'MzMBr        [kNm]    Rfc,m=8.00';
    'MyMBr        [kNm]    Lrd,m=3.30';
    'MyMBr        [kNm]    Lrd,m=5.70';
    'MyMBr        [kNm]    Lrd,m=8.70';
    'MxMBf        [kNm]    Rfc,m=4.00';
    'MxMBf        [kNm]    Rfc,m=8.00';
    'MzMBf        [kNm]    Rfc,m=4.00';
    'MzMBf        [kNm]    Rfc,m=8.00';
    'MxMSr        [kNm]    Rfc,m=4.00';
    'MxMSr        [kNm]    Rfc,m=8.00';
    'MyMSr        [kNm]    Rfc,m=4.00';
    'MyMSr        [kNm]    Rfc,m=8.00';
    'MzMSr        [kNm]    Rfc,m=4.00';
    'MzMSr        [kNm]    Rfc,m=8.00';
    'MyMSr        [kNm]    Lrd,m=3.30';
    'MyMSr        [kNm]    Lrd,m=5.70';
    'MyMSr        [kNm]    Lrd,m=8.70';
    'MxMSf        [kNm]    Rfc,m=4.00';
    'MxMSf        [kNm]    Rfc,m=8.00';
    'MzMSf        [kNm]    Rfc,m=4.00';
    'MzMSf        [kNm]    Rfc,m=8.00';
    'Mxtt         [kNm]    Rfc,m=4.00';
    'Mxtt         [kNm]    Rfc,m=8.00';
    'Mztt         [kNm]    Rfc,m=4.00';
    'Mztt         [kNm]    Rfc,m=8.00'};

sensors_main_fat.vsc = {
    'MxBldRoot_m=10';
    'MyBldRoot_m=10';
    'MxBldMid_m=10';
    'MyBldMid_m=10';
    'MxHub_LDD_m=3.3';
    'MxHub_LDD_m=3';
    'MrHub_LDD_m=3.3';
    'MrHub_LDD_m=3';
    'MxHub_m=4';
    'MxHub_m=8';
    'MyHub_m=4';
    'MyHub_m=8';
    'MxMbRot_m=4';
    'MxMbRot_m=8';
    'MyMbRot_m=4';
    'MyMbRot_m=8';
    'MzMbRot_m=4';
    'MzMbRot_m=8';
    'MyMbRot_LRD_m=3.3';
    'MyMbRot_LRD_m=5.7';
    'MyMbRot_LRD_m=8.7';
    'MxMbFix_m=4';
    'MxMbFix_m=8';
    'MzMbFix_m=4';
    'MzMbFix_m=8';
    'MxMSRot_m=4';
    'MxMSRot_m=8';
    'MyMSRot_m=4';
    'MyMSRot_m=8';
    'MzMSRot_m=4';
    'MzMSRot_m=8';
    'MyMSRot_LRD_m=3.3';
    'MyMSRot_LRD_m=5.7';
    'MyMSRot_LRD_m=8.7';
    'MxMSFix_m=4';
    'MxMSFix_m=8';
    'MzMSFix_m=4';
    'MzMSFix_m=8';
    'MxTwrTop_Nac_m=4';
    'MxTwrTop_Nac_m=8';
    'MzTwrTop_Nac_m=4';
    'MzTwrTop_Nac_m=8'};

sensors_twrfnd_fat.vts = {
    'Mxtt_latScaled_Rfc_m=4';
    'Mxtt_latScaled_Rfc_m=8';
    'Mxtt_latScaled_Rfc_m=10';
    'Mztt_Rfc_m=4';
    'Mztt_Rfc_m=8';
    'Mztt_Rfc_m=10';
    'Mxt1_latScaled_Rfc_m=4';
    'Mxt1_latScaled_Rfc_m=8';
    'Mxt1_latScaled_Rfc_m=10';
    'Mxt1_latScaled_Rfc_m=4';
    'Mxt1_latScaled_Rfc_m=8';
    'Mxt1_latScaled_Rfc_m=10';
    };

sensors_twrfnd_fat.vsc = {
    'MxTwrTop_Twr_m=4';
    'MxTwrTop_Twr_m=8';
    'MxTwrTop_Twr_m=10';
    %     'MrTwrTop_Twr_m=4';
    %     'MrTwrTop_Twr_m=8';
    %     'MrTwrTop_Twr_m=10';
    'MzTwrTop_Twr_m=4';
    'MzTwrTop_Twr_m=8';
    'MzTwrTop_Twr_m=10';
    'MxTwrBot_Twr_m=4';
    'MxTwrBot_Twr_m=8';
    'MxTwrBot_Twr_m=10';
    %     'MrTwrBot_Twr_m=4';
    %     'MrTwrBot_Twr_m=8';
    %     'MrTwrBot_Twr_m=10';
    'MxTwrBot_Fnd_m=4';
    'MxTwrBot_Fnd_m=8';
    'MxTwrBot_Fnd_m=10';
    %     'MrTwrBot_Fnd_m=4';
    %     'MrTwrBot_Fnd_m=8';
    %     'MrTwrBot_Fnd_m=10'
    };

sensors_main_ext.vts = {
    sprintf('B?Mx%05d    [kNm]           Max', Hub_radius*100);    % To get correct name for BLD sensor at BLD root, corresponding to VSC sensor MxBld_0000
    sprintf('B?Mx%05d    [kNm]           Min', Hub_radius*100);
    sprintf('B?Mx%05d    [kNm]           Max',Rotor/8*100);        % To get correct name for BLD sensor at 1/4 of the blade (25% of BLD length), corresponding to VSC sensor MxBld_0250
    sprintf('B?Mx%05d    [kNm]           Min',Rotor/8*100);
    sprintf('B?Mx%05d    [kNm]           Max',Rotor/4*100);        % To get correct name for BLD sensor at middle of the blade (50% of BLD length), corresponding to VSC sensor MxBld_0500
    sprintf('B?Mx%05d    [kNm]           Min',Rotor/4*100);
    sprintf('B?Mx%05d    [kNm]           Max',Rotor*3/8*100);      % To get correct name for BLD sensor at 3/4 of the blade (75% of BLD length), corresponding to VSC sensor MxBld_0750
    sprintf('B?Mx%05d    [kNm]           Min',Rotor*3/8*100);
    sprintf('B?My%05d    [kNm]           Max', Hub_radius*100);
    sprintf('B?My%05d    [kNm]           Min', Hub_radius*100);
    sprintf('B?My%05d    [kNm]           Max',Rotor/8*100);
    sprintf('B?My%05d    [kNm]           Min',Rotor/8*100);
    sprintf('B?My%05d    [kNm]           Max',Rotor/4*100);
    sprintf('B?My%05d    [kNm]           Min',Rotor/4*100);
    sprintf('B?My%05d    [kNm]           Max',Rotor*3/8*100);
    sprintf('B?My%05d    [kNm]           Min',Rotor*3/8*100);
    'My?1h        [kNm]           Abs';
    '-Mx?1h       [kNm]           Abs';
    'Mpi?1        [kNm]           Max';
    'Mpi?1        [kNm]           Min';
    'MxMBf        [kNm]           Abs';
    'MxMBr        [kNm]           Abs';
    'MyMBr        [kNm]           Max';
    'MyMBr        [kNm]           Min';
    'MzMBf        [kNm]           Abs';
    'MzMBr        [kNm]           Abs';
    'FyMBr         [kN]           Max';
    'FyMBr         [kN]           Min';
    'MrMB         [kNm]           Max';
    'MxMSf        [kNm]           Abs';
    'MxMSr        [kNm]           Abs';
    'MyMSr        [kNm]           Max';
    'MyMSr        [kNm]           Min';
    'MzMSf        [kNm]           Abs';
    'MzMSr        [kNm]           Abs';
    'FyMSr         [kN]           Max';
    'FyMSr         [kN]           Min';
    'MrMS         [kNm]           Max';
    'Mxtt         [kNm]           Abs';
    'Mztt         [kNm]           Abs';
    'Mbtt         [kNm]           Abs'
    };

sensors_main_ext.vsc = {
    'MxBld_0000_Max';
    'MxBld_0000_Min';
    'MxBld_0250_Max';
    'MxBld_0250_Min';
    'MxBld_0500_Max';
    'MxBld_0500_Min';
    'MxBld_0750_Max';
    'MxBld_0750_Min';
    'MyBld_0000_Max';
    'MyBld_0000_Min';
    'MyBld_0250_Max';
    'MyBld_0250_Min';
    'MyBld_0500_Max';
    'MyBld_0500_Min';
    'MyBld_0750_Max';
    'MyBld_0750_Min';
    'MyHub_Abs';
    'MxHub_Abs';
    'MPitch_Max';
    'MPitch_Min';
    'MxMBFix_Abs';
    'MxMBRot_Abs';
    'MyMBRot_Max';
    'MyMBRot_Min';
    'MzMBFix_Abs';
    'MzMBRot_Abs';
    'FyMBRot_Max';
    'FyMBRot_Min';
    'MrMB_Max';
    'MxMSFix_Abs';
    'MxMSRot_Abs';
    'MyMSRot_Max';
    'MyMSRot_Min';
    'MzMSFix_Abs';
    'MzMSRot_Abs';
    'FyMSRot_Max';
    'FyMSRot_Min';
    'MrMS_Max';
    'MxTwrTop_Abs';
    'MzTwrTop_Abs';
    'MrTwrTop_Abs'
    };

sensors_twrfnd_ext.vts = {
    'Mbt1';
    'Mbt1'
    };

sensors_twrfnd_ext.vsc = {
    'MrTwrBot_Max';
    'MrTwrBot_Fnd_Max';
    };

end