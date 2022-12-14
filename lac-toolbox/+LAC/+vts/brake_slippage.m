function [Wdir_Average,Maximum_Single_Slip_Wdir,Maximum_Single_Slip_Wdir_frqinfo,TotalRevolutions_Wdir,TotalRevolutions_Wdir_frqinfo] = brake_slippage(InputsFolder)

%brake_slippage - Determines the brake slippage [Maximum single slip and
%Total Slip in 10 min]. Also gives corresponding  frequnecy and wind
%direction. 
%Hard coded : 24 cases for each wind dir - 4 Azimuths with 6 different seeds.
%
% Syntax:  [Wdir_Average,Maximum_Single_Slip_Wdir,Maximum_Single_Slip_Wdir_frqinfo,TotalRevolutions_Wdir,TotalRevolutions_Wdir_frqinfo] = brake_slippage(InputsFolder)
%
% Inputs:
%    InputsFolder - Full path of inputs folder on investigation folder. 
%
% Outputs:
%    Wdir_Average                       - Average wind speed of 24 load
%    cases (4 Azimuths with 6 different seeds).
%    Maximum_Single_Slip_Wdir           - Maximum single slip in 10 min for
%    a specific wind direction (Wdir_Average)
%    Maximum_Single_Slip_Wdir_frqinfo   - Corresponding frequency name of Maximum_Single_Slip_Wdir 
%    TotalRevolutions_Wdir              - Total slip in 10 min for a specific wind direction (Wdir_Average)
%    TotalRevolutions_Wdir_frqinfo      - Corresponding frequency name of TotalRevolutions_Wdir 
%
% Author: ASKNE, Ashok Kumar Nedumaran
% November 2016; Last revision: 18-Dec-2016

%------------- BEGIN CODE --------------
% Read frequeny file.
dirfrq = FileInDir(InputsFolder,'*.frq');
frqinfo = readfrq(dirfrq);

% Sensor file and INT dir is defined.
sensorfile=FindFileTL(InputsFolder);
[INTdir sensorname ext]=fileparts(sensorfile);
if isempty(sensorfile)
    error('Cannot find sensor file')
else
    Sensor=sensreadTL(sensorfile);
end
Channels={'Vhub' 'Wdir' 'OmGen'};

for j=1:length(Channels)
    ChannelNumbers(j)=sensNoTL(Sensor,Channels{1,j});
end

% Reading simulations
FileNames=frqinfo.name;
NoOfFiles=length(FileNames);
TotalRevolutions=zeros(NoOfFiles,1);
Maximum_Single_Slip=zeros(NoOfFiles,1);


% Loop through INT files.
for iIntFile=1:NoOfFiles
    h=waitbar(0,'Please Wait...');
    waitbar(iIntFile/NoOfFiles,h,['Sensor file found, reading int file: ',num2str(iIntFile) ' out of ',num2str(NoOfFiles)]);
    
    % Read INT file.
    [time Ydata] = intreadTL([INTdir '\' FileNames{iIntFile}]);
    
    % Set data.
    dat=zeros(length(time),length(Channels));
    
    % Loop through sensors.
    for j = 1:length(Channels)
        dat(:,j) = Ydata(:,ChannelNumbers(j));
    end
    
    % Set separate variables.
    Vhub = dat(:,1);
    Wdir = dat(:,2);
    OmGen = dat(:,3);
    
    % Convert generator speed from RPM to degrees per second.
    GeneratorSpeed_degrees_per_seconds_index(:,iIntFile) = abs((OmGen/60)*360);     % Variable is a index, if slip occurs or not.  
    GeneratorSpeed_degrees_per_seconds_value(:,iIntFile) = max(0,(OmGen/60)*360);   % Replaces the negative values of OmGen with zeros
    
    % Accumulate generator speed (degrees per second).
    GeneratorSpeedAccumulated(:,iIntFile)= cumtrapz(time,GeneratorSpeed_degrees_per_seconds_value(:,iIntFile));
    
    % Save total number of revolutions in the entire time series.
    TotalRevolutions(iIntFile) = GeneratorSpeedAccumulated(end,iIntFile);
    
    % Save average wind direction and wind speed.
    WindDirections(iIntFile) = mean(Wdir);
    WindSpeeds(iIntFile) = mean(Vhub); % Not used any where, As maintenance wind speed is used.
    
    % Returns non zero values 'GeneratorSpeed_degrees_per_seconds'. Give values for where brake slippage has occured.
    GeneratorSpeed_degrees_per_seconds_non_zero = find(GeneratorSpeed_degrees_per_seconds_index(:,iIntFile));
    
    % Returns non zero values 'GeneratorSpeed_degrees_per_seconds_non_zero'.  Gives cummulative value where brake slippage has occured. +1 included to due to defintion of MATLAB function 'cumtrapz'.
    %If -else ladder introducted. To take into account for the cases
    %where slippage occurs at the end of 600 secs.
    if isempty(GeneratorSpeed_degrees_per_seconds_non_zero) ~= 1;           %Checks if slip happens or not
        if (  GeneratorSpeed_degrees_per_seconds_non_zero(end) < length(time))      % Checks if slip  ends before 600 secs
            GeneratorSpeedAccumulated_non_zero = GeneratorSpeedAccumulated(GeneratorSpeed_degrees_per_seconds_non_zero+1,iIntFile);
        else                                                                         % Else, Indicates slip occurs at the end of 600 secs
            GeneratorSpeedAccumulated_non_zero = GeneratorSpeedAccumulated(GeneratorSpeed_degrees_per_seconds_non_zero(1:end-1)+1,iIntFile);
        end
        
    else
        GeneratorSpeedAccumulated_non_zero = GeneratorSpeedAccumulated(GeneratorSpeed_degrees_per_seconds_non_zero+1,iIntFile);
    end
    
    % Uses MATLAB function diff on 'GeneratorSpeed_degrees_per_seconds_non_zero'. It will be used to determine number of single slips. Array is transposed and padded with zero at start.
    GeneratorSpeed_degrees_per_seconds_non_zero_difference = diff([0 transpose(GeneratorSpeed_degrees_per_seconds_non_zero)]);
    
    % Gives number of single Slip.
    Number_of_Single_Slip = find(GeneratorSpeed_degrees_per_seconds_non_zero_difference~=1);
    
    % Uses MATLAB function diff on 'GeneratorSpeedAccumulated_non_zero'. It gives slippage at each time step. Array is transposed and padded with zero at start.
    GeneratorSpeedAccumulated_non_zero_difference = diff([0 transpose(GeneratorSpeedAccumulated_non_zero)]);
    
    % To initialise and reset
    Instantaneous_Maximum_Single_Slip = 0;
    
    % Below if-else ladder to determine 'Maximum_Single_Slip_Current_IntFile'
    if length(Number_of_Single_Slip) == 1
        % If number of single slip is 1. Then, it sum of 'GeneratorSpeedAccumulated_non_zero_difference'.
        Instantaneous_Maximum_Single_Slip = sum(GeneratorSpeedAccumulated_non_zero_difference);
    else
        % Else, number of single slip is greater than one. Calcutes for each singles slip and returns the maximum.
        % Determine each single slip and stores in variable 'Instantaneous_Maximum_Single_Slip'
        nSingleSlips = length(Number_of_Single_Slip);
        for iSingleSlip=1:nSingleSlips
            % If-else ladder introduced. To include the last single slip.
            if iSingleSlip < nSingleSlips
                % Set indices for this current single slip.
                SingleSlipIndices = Number_of_Single_Slip(iSingleSlip):Number_of_Single_Slip(iSingleSlip+1)-1;
            else
                % Set indices for this current single slip (remaining part of signal).
                SingleSlipIndices = Number_of_Single_Slip(iSingleSlip):length(GeneratorSpeedAccumulated_non_zero_difference);
            end
            % Set signal for single slip.
            SlipSignal = GeneratorSpeedAccumulated_non_zero_difference(SingleSlipIndices);
            % Sum degrees of slip.
            Instantaneous_Maximum_Single_Slip(iSingleSlip) = sum(SlipSignal);
        end
    end
    % Set the maximum single slip.
    Maximum_Single_Slip(iIntFile) = max(Instantaneous_Maximum_Single_Slip);
    
    close(h)  % To close the waitbar
end

% 24 cases for each wind dir : 4 Azimuths with 6 different seeds.
nFiles = length(frqinfo.name);
nAzimuthSeeds = 4*6;
nWindDirections = nFiles/nAzimuthSeeds;
% Loop through wind directions.
for iWindDirection=1:nWindDirections
    % Set indices to use.
    IndicesCurrentWindDirection = (iWindDirection-1)*nAzimuthSeeds+1:nAzimuthSeeds*iWindDirection;
    
    % Set average wind direction.
    Wdir_Average(iWindDirection) = mean(WindDirections((IndicesCurrentWindDirection)));
    
    % Family method = Maximmum of all.
    [TotalRevolutions_Wdir(iWindDirection),TotalRevolutions_Wdir_frqinfo_index]= max(TotalRevolutions(IndicesCurrentWindDirection));
    [Maximum_Single_Slip_Wdir(iWindDirection),Maximum_Single_Slip_Wdir_index] = max(Maximum_Single_Slip(IndicesCurrentWindDirection));
    TotalRevolutions_Wdir_frqinfo(iWindDirection)  = frqinfo.name(IndicesCurrentWindDirection(TotalRevolutions_Wdir_frqinfo_index));
    Maximum_Single_Slip_Wdir_frqinfo(iWindDirection) =  frqinfo.name(IndicesCurrentWindDirection(Maximum_Single_Slip_Wdir_index));
end
end