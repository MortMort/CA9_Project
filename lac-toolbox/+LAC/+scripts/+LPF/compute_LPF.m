clear all; clc;
%% DETECT EDGEWISE SV AND COMPUTE LPF
% The scripts finds when Edgewise supervision is triggered and estimates
% LPF due to supervision
    % Shutdown due to edgewise supervision is triggered if:
        % Sx_BladeXEdgeVibration = 1; btp020 (blade A), bpt024 (blade B),
                                    % bpt028 (blade C)
        % Sx_BladeXEdgePeakLoad = 1; btp019 (blade A), bpt023 (blade B),
                                   % bpt027 (blade C)
% Rev 0: 10-09-2019 CAVMI
% Rev 1: 24-09-2019 CAVMI, breakes down LPF by wind speed

%% USER INPUT
path = ''; % path to simulations
SV_sensors = {'bpt019'; 'bpt020'; 'bpt023'; 'bpt024'; 'bpt027'; 'bpt028'}; % list of sensors that determines whether the SV is triggered
% if any of the sensors above reaches the value of 1 during the simulation, the script assumes the SV is triggered
h_in_20y = 20*365.25*24; % hours in lifetime

%% CODE STARTS
headers = {'DLC', 'is_SV_triggered?', 'Possible production [kWh]', 'Lost production [kWh]', 'LPF [%]'};
wind_speeds = {'04', '06', '08', '10', '12', '14', '16', '18', '20'};
wind_speeds_str = {'4m/s', '6m/s', '8m/s', '10m/s', '12m/s', '14m/s', '16m/s', '18m/s', '20m/s'};

directory = dir(path);
dirFlags = [directory.isdir];
subFolders = directory(dirFlags); % get subdirectories of "path"

% Loop through subdirectories and read sta data to obtain LPF
for i = 3:length(subFolders)
    % Read sta
    loadpath = [subFolders(i).folder '\' subFolders(i).name '\Loads'];
    stafiles = LAC.dir([loadpath '\STA\*.sta']); % list sta files
    staObj = LAC.vts.stapost(loadpath);
    sta = staObj.readfiles(stafiles); % read sta files
    
    % Find sensors relevant for Edgewise supervision and store idx of DLCs
    % where SV is triggered
    idx_SV_triggered = [];
    for j = 1:length(SV_sensors)
        [idx(j), ~] = staObj.findSensor(SV_sensors{j},'exact');
        idx_SV_triggered = horzcat(idx_SV_triggered,find(sta.max(idx(j),:)>0.95)); % 0.95 used instead of 1 due to 
    end
    idxU_SV_triggered = unique(idx_SV_triggered);
    DLCs_SV = sta.filenames(idxU_SV_triggered);
    
    % Read frq file and compute possible production
    frqfile = LAC.dir([loadpath '\INPUTS\*.frq']); % list frq files
    if length(frqfile)>1
        disp('Error: there is more than 1 frequency file')
    end
    [int dat] = LAC.scripts.BrakeAssessment.BrakeWork.frqread([loadpath '\INPUTS\' char(frqfile)]);
    h_dlc = dat(:,2)/sum(dat(:,2))*h_in_20y; % hours of each DLC in 20y
    
    [idx_P, ~] = staObj.findSensor('P','exact');
    for k = 1:length(int)
        pattern = strsplit_LMT(string(int(k)),'.');
        dlc = pattern{1};
        i_dlc = find(contains(sta.filenames,dlc)==1);
        P_mean(k) = sta.max(idx_P,i_dlc);
    end
    possible_prod = P_mean' .* h_dlc; %kWh
    
    % define boolean that tells if SV is triggered for each DLC
    is_SV_triggered = false(length(int),1);
    for k = 1:length(DLCs_SV)
        pattern = strsplit_LMT(string(DLCs_SV(k)),'.');
        dlc = pattern{1};
        idx_dlc = find(contains(int,dlc)==1);
        is_SV_triggered(idx_dlc) = true;
    end
    
    lost_prod = possible_prod.*is_SV_triggered;
    LPF = sum(lost_prod)/sum(possible_prod)*100
    
    % LPF analysis by wind speed
    for j=1:length(wind_speeds)
        clear idx_dlc
        idx_dlc = find(contains(int,strcat('11',wind_speeds{j},'q'))==1);
        LPF_ws(j) = sum(lost_prod(idx_dlc))/sum(possible_prod)*100;
        N_triggers(j) = length(find(is_SV_triggered(idx_dlc)==true))/length(is_SV_triggered(idx_dlc))*100;
    end
    
    % Write data
    xlswrite([loadpath '\LPF_summary.xlsx'],headers,'A1:E1');
    xlswrite([loadpath '\LPF_summary.xlsx'],int,'A2:A2702');
    xlswrite([loadpath '\LPF_summary.xlsx'],is_SV_triggered,'B2:B2702');
    xlswrite([loadpath '\LPF_summary.xlsx'],possible_prod,'C2:C2702');
    xlswrite([loadpath '\LPF_summary.xlsx'],lost_prod,'D2:D2702');
    xlswrite([loadpath '\LPF_summary.xlsx'],LPF,'E2:E2');
    clear int is_SV_triggered possible_prod lost_prod
    clear P_mean h_dlc dat sta stafiles staObj
    xlswrite([loadpath '\LPF_summary.xlsx'],wind_speeds_str,'H2:P2');
    xlswrite([loadpath '\LPF_summary.xlsx'],{'LPF_ws'},'G3:G3');
    xlswrite([loadpath '\LPF_summary.xlsx'],LPF_ws,'H3:P3');
    xlswrite([loadpath '\LPF_summary.xlsx'],{'% triggers'},'G4:G4');
    xlswrite([loadpath '\LPF_summary.xlsx'],N_triggers,'H4:P4');
    

end