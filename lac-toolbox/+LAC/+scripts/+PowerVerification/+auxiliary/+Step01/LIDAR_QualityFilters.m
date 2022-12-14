function data  = LIDAR_QualityFilters(data)

% Function to check quuality of LIDAR data and apply additional filters 

%   Filter 1 - Signal availability: 
%	Removes time series with LiDAR inactivity periods longer than set threshold
%	(defaultly there has to be signal for more than 85% of the timeseries - threshold 15%)
%	Checks each sector individually
%   
%   Filter 2 - Wind shear filter:
%	Compares the wind speed measured in each LiDAR sector and removes data
%   with variations between each adjacent sectors above the set threshold  
%   (default rate 1.5)

%   Filter 2 - Turbulence intensity filter: 
%	Compares the turbulence intensity measured in each LiDAR sector and removes 
%   with variations between each adjacent sectors above the set threshold  
%   (default variation 5%)

%   SEHIK - 08/10/2021

disp('Applying quality filter on LIDAR data.')

% Input: Treshold setting for the filters

Avail_criteria=0.15;            % Criteria for availability (STsg/PIAH) signal treshold (portion of 10 min interval for which signal equal to 9999)
AvWS_criteria=1.5;              % Criteria for mean wind speed variation between LIDAR sectors treshold, rate between adjacent sectors
TI_criteria=0.05;               % Criteria for TI variation between LIDAR sectors;

fprintf('Applied filters:\n Availability criteria= %.2f \n Average Wind Speed criteria= %.2f \n Turbulence Intensity criteria= %.2f \n\n',Avail_criteria,AvWS_criteria,TI_criteria);

%% 1 Filter: filtering based on data Check 2 (discard measurement if ANY of the sector is not fulfilling the required threshold)
%% 			if STsg=9999 are above 15% of 10 min time for ANY STsg sensors

	disp('Applying Availability filter.')

	%% Sensor identification
	STsg_index=find(contains(data.dat1.sensorname, 'STsg')); %find(~cellfun(@isempty,strfind(sensor_data{7}, 'STsg')));
	SLOSflag=0;
	if isempty(STsg_index)
		STsg_index=find(contains(data.dat1.sensorname, 'SLOSR')); % only taking the right sensor to extract the sensor index, but later averaging L&R
		disp('Availability sensor name: SLOS');
		SLOSflag=1;
	else 
		disp('Availability sensor name: STsg');
	end
	
	% OPTION! to disregard peripethal sectors in case of signal unavailibility
	 STsg_index([1,2, end])=[]; % disregard the first two sectors
    
	Passing_matrix_STsg=ones(length(data.dat1.filename),1);
	%reverseStr = '';
    
	%%   Criteria check
	
    for f=1:length(data.dat1.filename)
		if SLOSflag==1
		% Averaging left and right signal
			signal_mean=(data.dat1.mean(f,STsg_index)+data.dat1.mean(f,STsg_index+1))/2;
			signal_max=data.dat1.max(f,STsg_index);
% 			if any(data.dat1.max(f,STsg_index)~=data.dat1.max(f,STsg_index+1)) 
% 				disp('Error occured due the maximum value of SLOS signal. LIDAR filteres not applied.');
% 				return;
% 			end
		else 
			signal_mean=data.dat1.mean(f,STsg_index);
			signal_max=data.dat1.max(f,STsg_index);
		end
		
        if any(signal_mean./signal_max>=Avail_criteria)
            Passing_matrix_STsg(f)=0;
        end

    end
	
		% 	for f=1:length(data.dat1.filename)
		%         
		% 		datfile = [DatPath char(data.dat1.filename(f)) '.dat'];
		% 		fid = fopen(datfile,'r');
		% 		[data_raw] = textscan(fid, repmat('%s', 1, 38), 'HeaderLines',9, 'CollectOutput',1);
		% 		Dat_input.Header={data_raw{1,1}{1,:}};
		% 		%Dat_input.SensNum=cellfun( @str2num, {data_raw{1,1}{2:end,1}}' );
		% 		%Dat_input.SensName={data_raw{1,1}{2:end,2}}';
		% 		Dat_input.Data=reshape(cellfun(@str2num, {data_raw{1,1}{2:end,4:end}}), size(data_raw{1,1},1)-1,size(data_raw{1,1},2)-3);
		% 		
		% 		max_idx=find(strcmp(Dat_input.Header, 'Max'))-3;
		% 		mean_idx=find(strcmp(Dat_input.Header, 'Mean'))-3;
		% 		
		% 		if any(Dat_input.Data(STsg_index, mean_idx)./Dat_input.Data(STsg_index, max_idx)>=Avail_criteria)
		% 			Passing_matrix_STsg(f)=0;
		% 		end
		% 		
		% 		fclose(fid);
		%         
		%         % Display the progress
		%            
		%            percentDone = 100 * f/ length(data.dat1.filename);
		%            msg = sprintf('Percent done: %3.1f %', percentDone); 
		%            fprintf([reverseStr, msg]);
		%            reverseStr = repmat(sprintf('\b'), 1, length(msg));
		% 	end

	fprintf('Number of samples that pass the availability criteria: %d out of %d\n\n',sum(Passing_matrix_STsg),length(Passing_matrix_STsg));

	%% Reduction of the dataset 

		fields = fieldnames(data.dat1);
		for i = 1:length(fields)
			if size(data.dat1.(fields{i}),1) == (length(Passing_matrix_STsg))
            data.dat1.(fields{i})=data.dat1.(fields{i})(find(Passing_matrix_STsg==1),:);   
			end
		end
		clearvars fields

%% 2 Filter: WS variation across sectors (PHWS)

	disp('Applying PHWS filter.')
	
	%% Sensor identification
	WS_index=find(contains(data.dat1.sensorname, 'PHWS')); 
	
	%%Extract sector height from sensor description
	
	sector_heigt=zeros(length(WS_index),1);
	for j=1:length(WS_index)
			
			sensor_full_name=char(data.dat1.sensorname(WS_index(j)));
			index=find(isstrprop(sensor_full_name,'digit'));
			sector_heigt(j)=str2double(sensor_full_name(index));
	end
	
	Passing_matrix_WS=ones(length(data.dat1.filename),1);
	WS_sectors=zeros(length(WS_index),1);
	
	%%   Criteria check
	for f=1:length(data.dat1.filename)
			WS_sectors=data.dat1.mean(f,WS_index); % as using .INT as input, calculating mean PHWS for each sector                   
			for ii=2:length(WS_sectors)
				if WS_sectors(ii)/WS_sectors(ii-1)>=AvWS_criteria || WS_sectors(ii)/WS_sectors(ii-1)<=1/AvWS_criteria
					
					Passing_matrix_WS(f)=0;
					break;
				end
			end
	end
	
	fprintf('Number of samples that pass the Average Wind Speed criteria: %d out of %d\n\n',sum(Passing_matrix_WS),length(Passing_matrix_WS));
	
	%% Reduction of the dataset 

		fields = fieldnames(data.dat1);
		for i = 1:length(fields)
			if size(data.dat1.(fields{i}),1) == (length(Passing_matrix_WS))
            data.dat1.(fields{i})=data.dat1.(fields{i})(find(Passing_matrix_WS==1),:);   
			end
		end
	
%% 3 Filter: TI difference across rotor (SATI)

	disp('Applying SATI filter.')

	%% Sensor identification
	SATI_index=find(~cellfun(@isempty,strfind(data.dat1.sensorname, 'SATI'))); % in sensore name

	% SATI sensor height the same as PDAC WS (sensor_height)

	SATI_sectors=zeros(length(SATI_index),1);
	Passing_matrix_SATI=ones(length(data.dat1.filename),1);
	
	for f=1:length(data.dat1.filename)
		SATI_sectors=data.dat1.mean(f,SATI_index); 
		for ii=2:length(SATI_sectors)
			if abs(SATI_sectors(ii)-SATI_sectors(ii-1))>TI_criteria
				%disp([INT_files(f).name ' exceeded 5% allowance of TI difference across rotor.'])
				
				Passing_matrix_SATI(f)=0;
				break;
			end
		end
	end
	
	fprintf('Number of samples that pass the Turbulence Intensity criteria: %d out of %d\n\n',sum(Passing_matrix_SATI),length(Passing_matrix_SATI));
	
	%% Reduction of the dataset 

		fields = fieldnames(data.dat1);
		for i = 1:length(fields)
			if size(data.dat1.(fields{i}),1) == (length(Passing_matrix_SATI))
            data.dat1.(fields{i})=data.dat1.(fields{i})(find(Passing_matrix_SATI==1),:);   
			end
		end

%% Output

    data.sensornameshort=data.sensornameshort; 
    
end
   