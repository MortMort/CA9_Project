function out_struct = CalculateTurnerGearExtremeLoadsGC(IntFolder, SmomBLD, GravityCorrection, varargin)
    % Calculate the LSS trq required during installation when only 1 blade, only 2 blades & all 3 blades installed.
    disp('Modified version of CalculateTurnerGearExtremeLoads using Gravity Correction')
    Parser = inputParser;
    Parser.addOptional('OutputFolder',cd);
    Parser.addOptional('NumberOfSeeds',6);
    Parser.addOptional('LoadFactor',1.35);
    Parser.addOptional('ForceIntFileRead',false);
	%Parser.addOptional('SmomBLD',2.073E+06);
    %Parser.addOptional('GravityCorrection',1.1);

    % Parse.
    Parser.parse(varargin{:});

    % Set variables.
    OutputFolder = Parser.Results.('OutputFolder');
    NumberOfSeeds = Parser.Results.('NumberOfSeeds');
    LoadFactor = Parser.Results.('LoadFactor');
    ForceIntFileRead = Parser.Results.('ForceIntFileRead');
	%SmomBLD = Parser.Results.('SmomBLD');
	%GravityCorrection = Parser.Results.('GravityCorrection');
    
    % Ensure output folder exists.
    if ~exist(OutputFolder,'dir');
        mkdir(OutputFolder);
    end
    
    % Filename for mat file.
    filepath_mat_file = fullfile(OutputFolder, 'ExtremeTurnerGearLoads.mat');
    
    % Check whether *.mat file exists.
    do_read_int_files = true;
    if exist(filepath_mat_file, 'file')
        do_read_int_files = false;
    end
    
    % Force read of INT files?
    if ForceIntFileRead
        do_read_int_files = true;
    end
    
    % Process the INT files.
    if do_read_int_files
        % Read sensor file.
        filename_sensor = fullfile(IntFolder, 'sensor');
        SensorFileObj = LAC.vts.convert(filename_sensor, 'SENSOR');

        % Set index of needed sensors.
        My11h_sens = SensorFileObj.findSensor('My11h');
        Fx11h_sens = SensorFileObj.findSensor('Fx11h');
        My21h_sens = SensorFileObj.findSensor('My21h');
        Fx21h_sens = SensorFileObj.findSensor('Fx21h');
        My31h_sens = SensorFileObj.findSensor('My31h');
        Fx31h_sens = SensorFileObj.findSensor('Fx31h');
        MyMBr_sens = SensorFileObj.findSensor('MyMSr');
        PSI_sens = SensorFileObj.findSensor('PSI');
        Wdir_sens = SensorFileObj.findSensor('Wdir');

        % Read hub radius from the blade file.
        BldFolder = fullfile(IntFolder, '..\PARTS\BLD');
        file_struct = dir(BldFolder); % Read file list.
        file_list = {file_struct.name}; % Convert to cell list.
        file_list(strcmp('.',file_list)) = []; % Remove ".".
        file_list(strcmp('..',file_list)) = []; % Remove "..".
        % Throw error if more than 1 file remains now (multiple blade files).
        if length(file_list) > 1
            error('Multiple blade files exists. Please ensure that only 1 blade file exists. Alternatively, implement support into this code for direct specification of which blade file to use.');
        end
        blade_parts_file = file_list{1}; % Set blade file.
        blade_parts_path = fullfile(BldFolder, blade_parts_file);
        BladeFileObj = LAC.vts.convert(blade_parts_path, 'BLD'); % Read blade file.
        Hub_Radius = BladeFileObj.SectionTable.R(1); % Set hub radius (used for calculating moment from force).

        % Read list of INT files from INT folder.
        if strcmp(IntFolder(end),'\'); % Remove possible backslash to make below code robust.
            IntFolder = fileparts(loads_folder); %
        end
        IntFileStruct = dir([IntFolder,'\*TG*.int']);
        nIntFiles = length(IntFileStruct);
        DataMax = zeros(nIntFiles,30);
        DataMin = zeros(nIntFiles,24);
        IntFileNames = {IntFileStruct.name};

        % Initiate wait bar.
        h = waitbar(0,['Reading 0/',num2str(nIntFiles),' files']);

        % Loop through int files.
        for iIntFile=1:nIntFiles
            % Update wait bar.
            waitbar(iIntFile/nIntFiles,h,sprintf('Reading %s/%s files',num2str(iIntFile),num2str(nIntFiles)));
            
            % Set local.
            IntFileName = IntFileNames{iIntFile}
            IntFilePath = fullfile(IntFolder, IntFileName);

            % Read int file.
            dataflag = 1;
            channels = [];
            Tmin = [];
            Tmax = [];
            [~,t,data,~] = LAC.timetrace.int.readint(IntFilePath,dataflag,channels,Tmin,Tmax);

            % Set signals.
            My11h = data(1:end,My11h_sens);
            Fx11h = data(1:end,Fx11h_sens);
            My21h = data(1:end,My21h_sens);
            Fx21h = data(1:end,Fx21h_sens);
            My31h = data(1:end,My31h_sens);
            Fx31h = data(1:end,Fx31h_sens);
            MyMBr = data(1:end,MyMBr_sens);
            PSI = data(1:end,PSI_sens);
            Wdir = data(1:end,Wdir_sens);

			% % Calculate torque on main shaft from each blade.
            % B1_trq = My11h + Hub_Radius*Fx11h;
            % B2_trq = My21h + Hub_Radius*Fx21h;
            % B3_trq = My31h + Hub_Radius*Fx31h;
            % Calculate torque on main shaft from each blade with Gravity Correction of 1.1
            B1_trq = My11h + Hub_Radius*Fx11h + (1-GravityCorrection/LoadFactor)*SmomBLD*9.80665/1000*sin(mean(PSI)*pi/180);
            B2_trq = My21h + Hub_Radius*Fx21h + (1-GravityCorrection/LoadFactor)*SmomBLD*9.80665/1000*sin((mean(PSI)-120)*pi/180);
            B3_trq = My31h + Hub_Radius*Fx31h + (1-GravityCorrection/LoadFactor)*SmomBLD*9.80665/1000*sin((mean(PSI)+120)*pi/180);            
            			
            % Calculate torque from blade 1&2, 2&3 and 3&1.
            B12_trq = B1_trq + B2_trq;
            B23_trq = B2_trq + B3_trq;
            B31_trq = B3_trq + B1_trq;

            % Calculate combined torque on main shaft from all 3 blades.
            B123_trq = B1_trq + B2_trq + B3_trq;

            % 2s average
            N2 = round(2/(t(2)-t(1)));
            B1_trq_2sf = zeros(length(B1_trq)-N2,1);
            B2_trq_2sf = zeros(length(B1_trq)-N2,1);
            B3_trq_2sf = zeros(length(B1_trq)-N2,1);
            for j=1:length(B1_trq)-N2
               B1_trq_2sf(j) = mean(B1_trq(j:j+N2));
               B2_trq_2sf(j) = mean(B2_trq(j:j+N2));
               B3_trq_2sf(j) = mean(B3_trq(j:j+N2));
            end

            B12_trq_2sf = B1_trq_2sf + B2_trq_2sf;
            B23_trq_2sf = B2_trq_2sf + B3_trq_2sf;
            B31_trq_2sf = B3_trq_2sf + B1_trq_2sf;
            B123_trq_2sf = B1_trq_2sf + B2_trq_2sf + B3_trq_2sf;

            % 60s average
            N60 = round(60/(t(2)-t(1)));
            B1_trq_60sf = zeros(length(B1_trq)-N60,1);
            B2_trq_60sf = zeros(length(B1_trq)-N60,1);
            B3_trq_60sf = zeros(length(B1_trq)-N60,1);
            for j=1:length(B1_trq)-N60
               B1_trq_60sf(j) = mean(B1_trq(j:j+N60));
               B2_trq_60sf(j) = mean(B2_trq(j:j+N60));
               B3_trq_60sf(j) = mean(B3_trq(j:j+N60));
            end
            B12_trq_60sf = B1_trq_60sf + B2_trq_60sf;
            B23_trq_60sf = B2_trq_60sf + B3_trq_60sf;
            B31_trq_60sf = B3_trq_60sf + B1_trq_60sf;
            B123_trq_60sf = B1_trq_60sf + B2_trq_60sf + B3_trq_60sf;

            % peaks to peaks, 1s
            N1 = round(1/(t(2)-t(1)));
            B1_trq_pp = zeros(length(B1_trq)-N1,1);
            B2_trq_pp = zeros(length(B1_trq)-N1,1);
            B3_trq_pp = zeros(length(B1_trq)-N1,1);
            B12_trq_pp = zeros(length(B1_trq)-N1,1);
            B23_trq_pp = zeros(length(B1_trq)-N1,1);
            B31_trq_pp = zeros(length(B1_trq)-N1,1);
            for j=1:length(B1_trq)-N1
               B1_trq_pp(j) = max(B1_trq(j:j+N1))-min(B1_trq(j:j+N1));
               B2_trq_pp(j) = max(B2_trq(j:j+N1))-min(B2_trq(j:j+N1));
               B3_trq_pp(j) = max(B3_trq(j:j+N1))-min(B3_trq(j:j+N1));
               B12_trq_pp(j) = max(B12_trq(j:j+N1))-min(B12_trq(j:j+N1));
               B23_trq_pp(j) = max(B23_trq(j:j+N1))-min(B23_trq(j:j+N1));
               B31_trq_pp(j) = max(B31_trq(j:j+N1))-min(B31_trq(j:j+N1));
            end

            % Check Mean Azim
            Wdir = Wdir;
            Azim = PSI;
            MS_trq = MyMBr;

            AzimMean = round(mean(unwrap(Azim*pi/180)*180/pi));
            if AzimMean==360
               AzimMean = 0;
            end
            AzimMeanLC = str2double(IntFileName(regexp(IntFileName,'azim')+4:end-7));
            if AzimMean~=AzimMeanLC
               disp(['Check Azimuth in file ' IntFileName]);
            end

            % Check Mean WDir
            WdirMean = round(mean(Wdir));
            WdirMeanLC = str2double(IntFileName(3:5));
            if WdirMean~=WdirMeanLC
               disp(['Check Wdir in file ' IntFileName]);
            end

            DataMaxRow  =  [WdirMean, AzimMean, max(B1_trq), max(B2_trq), max(B3_trq), max(B12_trq), max(B23_trq), max(B31_trq), max(B123_trq), max(B1_trq_2sf), max(B2_trq_2sf), max(B3_trq_2sf), max(B12_trq_2sf), max(B23_trq_2sf), max(B31_trq_2sf), max(B123_trq_2sf), max(B1_trq_60sf), max(B2_trq_60sf), max(B3_trq_60sf), max(B12_trq_60sf), max(B23_trq_60sf), max(B31_trq_60sf), max(B123_trq_60sf), max(MS_trq),max(B1_trq_pp),max(B2_trq_pp),max(B3_trq_pp),max(B12_trq_pp),max(B23_trq_pp),max(B31_trq_pp)];
            DataMinRow  =  [WdirMean, AzimMean, min(B1_trq), min(B2_trq), min(B3_trq), min(B12_trq), min(B23_trq), min(B31_trq), min(B123_trq), min(B1_trq_2sf), min(B2_trq_2sf), min(B3_trq_2sf), min(B12_trq_2sf), min(B23_trq_2sf), min(B31_trq_2sf), min(B123_trq_2sf), min(B1_trq_60sf), min(B2_trq_60sf), min(B3_trq_60sf), min(B12_trq_60sf), min(B23_trq_60sf), min(B31_trq_60sf), min(B123_trq_60sf), min(MS_trq)];
            DataMax(iIntFile,:)  = DataMaxRow;
            DataMin(iIntFile,:)  = DataMinRow;

            clear B*_trq B*_trq_pp B*_trq_2sf B*_trq_60sf MS_trq Wdir Azim t intfile *Row;
        end;

        close(h)

        sensor = {'Wdir' 'Azim' 'B1_trq' 'B2_trq' 'B3_trq' 'B12_trq' 'B23_trq' 'B31_trq' 'B123_trq' 'B1_trq_2sf' 'B2_trq_2sf' 'B3_trq_2sf' 'B12_trq_2sf' 'B23_trq_2sf' 'B31_trq_2sf' 'B123_trq_2sf' 'B1_trq_60sf' 'B2_trq_60sf' 'B3_trq_60sf' 'B12_trq_60sf' 'B23_trq_60sf' 'B31_trq_60sf' 'B123_trq_60sf' 'MS_trq' 'B1_trq_pp' 'B2_trq_pp' 'B3_trq_pp' 'B12_trq_pp' 'B23_trq_pp' 'B31_trq_pp'};

        % Save to mat file.
        save(filepath_mat_file,'DataMax','DataMin','IntFileNames','sensor');
    else
        % Load mat file.
        load(filepath_mat_file);
    end
    
    % Prepare data for writing excel sheets.
    DataMaxBin = []; DataMinBin = [];
    for i=1:size(DataMax,1)/NumberOfSeeds
        % Indicies to use.
        index_start = (i-1)*NumberOfSeeds+1;
        index_end = (i-1)*NumberOfSeeds+NumberOfSeeds;
        
        % Set the "max data" (1 row per int file and 1 column per sensor).
        DataMax_this_azimuth_and_wind_direction = DataMax(index_start:index_end,:);
        DataMin_this_azimuth_and_wind_direction = DataMin(index_start:index_end,:);
        
        % Average of the seeds.
        DataMeanOfMax_this_azimuth_and_wind_direction = mean(DataMax_this_azimuth_and_wind_direction);
        DataMeanOfMin_this_azimuth_and_wind_direction = mean(DataMin_this_azimuth_and_wind_direction);
        
        % Save.
        DataMaxBin  = [DataMaxBin;  DataMeanOfMax_this_azimuth_and_wind_direction];
        DataMinBin  = [DataMinBin;  DataMeanOfMin_this_azimuth_and_wind_direction];
    end;
    
    % Multiply with load factor.
    DataMaxBin_withPLF = DataMaxBin*LoadFactor;
    DataMinBin_withPLF = DataMinBin*LoadFactor;
    
    % Set max and min values.
    Max_withoutPLF = max(DataMaxBin);
    Min_withoutPLF = min(DataMinBin);
    Max_withPLF = max(DataMaxBin_withPLF);
    Min_withPLF = min(DataMinBin_withPLF);

    % Save to matfile.
    filepath_mat_file = fullfile(OutputFolder, 'ExtremeTurnerGearLoadsPostProcessed.mat');
    save(filepath_mat_file,'DataMax','DataMin','sensor','DataMaxBin','DataMinBin','DataMaxBin_withPLF','DataMinBin_withPLF','Max_withoutPLF','Min_withoutPLF','Max_withPLF','Min_withPLF');
    
    % Write results to excel files.
    LAC.scripts.TurnerGearLoads.TurnerGearExtremeLoadsMatrix_AllAzim(DataMaxBin,DataMinBin,'OutputFolder', OutputFolder);
%     TurnerGearExtremeLoadsMatrix_AllAzim(DataMaxBin,DataMinBin,'OutputFolder', OutputFolder);
    out_struct_clockwise = LAC.scripts.TurnerGearLoads.TurnerGearExtremeLoadsMatrix_ClockWise(DataMaxBin,DataMinBin,'OutputFolder', OutputFolder);
    out_struct_counter_clockwise = LAC.scripts.TurnerGearLoads.TurnerGearExtremeLoadsMatrix_CounterClockWise(DataMaxBin,DataMinBin,'OutputFolder', OutputFolder);
    
    % Set output.
    out_struct.out_struct_clockwise = out_struct_clockwise;
    out_struct.out_struct_counter_clockwise = out_struct_counter_clockwise;
end