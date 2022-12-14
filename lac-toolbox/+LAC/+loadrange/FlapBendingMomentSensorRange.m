function [FlapMomentProposedRangeSurvivalMode,FlapMomentProposedRangeOperationalMode] = FlapBendingMomentSensorRange(path,n,margin,MinRotorSpdRPM,MaxPitchAngleDeg)
%% FUNCTION DESCRIPTION 

% The script is used to compute the range of the FLAP BENDING MOMENT sensor 


% The script computes the highest and lowest measurements over given INT 
% files, meaning for each loadcase the maximum and minimum of the sensor 
% is computed as a function of the free wind speed average. Afterwards, 
% maximum over all maximum and minimum all over minimum will be 
% calculated. This range is considered as a desired range for Flap 
% Moment, whereas for sake of safety, an extra margin is added to the 
% obtained values. The scripts outputs the calculated max. and min. 
% with safety margin and plots the sensor range over operational mode 
% where the turbine is in the production state and also it plots the 
% sensor range over survival range for all given loadcases.


% Function inputs
% path(string) : path for the VTS loads simulations.
% n(integer) : total number of significant load cases (seeds) to visualize 
% for highest and lowest loads.
% margin(float,percent) : represents the margin that is needed to add to the
% max. and min. load. 
% MinRotorSpdRPM(integer) : represents the minimum static speed of the 
% generator after which the turbine enters the production state.
% MaxPitchAngleDeg : the maximum pitch angle of the blade, up to which we 
% expect the turbine to remain in the operational mode.

% Function outputs
% FlapMomentProposedRangeSurvivalMode : represents a vector contains min
% and max of the sensor range by considering the safty margin in
% survival mode. It should be  mentioned that if a user only desires to 
% compute the actual range the margin should be set to zero.
% FlapMomentProposedRangeOperationalMode : represents a vector contains min
% and max of the sensor range by considering the safty margin in
% operational mode. It should be mentioned that if a user only desires to 
% compute the actual range the margin should be set to zero.


%% Initialization 

clc
%clear all
%close all


%% Optional: Change Flap Load Sensor

% change this sensor only if required. Find the description of the sensor
% in the sensors file inside INT folder. 
flapSensors = {'Moment about angle axis B1-Pos1, 2.500m'; 'Moment about angle axis B3-Pos1, 2.500m'; 'Moment about angle axis B2-Pos1, 2.500m'};


%% Determine the input string is a directory path or a filename

if  (~isempty(path(path == ':')) || ~isempty(path(path == '\')))
    
    dirpath = path;
    
    RetrieveData = false;  % Determines the available data should not used
    GenerateData = true;   % Determines the new data should generate

else
    filename = path;
    
    RetrieveData = true;  % Determines the available data should not used
    GenerateData = false; % Determines the new data should generate

end


%% Determine the INT folder created by Vestas measurment system or VTS (file extension *.int)

if (GenerateData)
    
    INTdirpath = dirpath;
    INText = '*.int';
    INTsensor = fullfile(INTdirpath,'INT',INText);
    Files = dir(INTsensor);
    p = size(Files,1);
    fprintf('default value : \np = %5d\n',p)
    
%% Apply default values

    if (nargin > 5) 
        error('Too Many Inputs,requires at most three inputs\n')
    elseif (nargin < 1)
        error('No Inputs,requires at least one inputs\n')
    elseif ~isempty(path)
        if isempty(n)
            n = 5; % Determine the number of significant loadcases
        end
        if isempty(margin)
            margin = 35; % Determine the defaulf margin (%)
        end
        if isempty(MinRotorSpdRPM)
            MinRotorSpdRPM = 450;  % Determine the default min rotor speed
        end
        if isempty(MaxPitchAngleDeg)
             MaxPitchAngleDeg = 70; % Determine the default pitch angle
        end
    elseif isempty(path)
         error('Function inputs are set incorrectly\n') 
    end
            
%% Display error message when n > p 

   if (n > p)
       error('n should not be higher than the total number of loadcases(p)(\n')  
   end

%% determine the production state flags

 
  dataflag = 1; % This flag is needed for reading the'.int file with ...
              % LAC.timetrace.int.readint function.

  % Production States 
  ePSC_Connecting = 4;
  ePSC_PowerUp = 5;
  ePSC_Production = 6;
  ePSC_PrepareDisconnectSD = 20;
  ePSC_DisconnectingSD = 21;
  ePSC_PrepareConnectSD = 22;
  
  % Pause States
  ePSC_PowerDown = 7;
  ePSC_Disconnecting = 8;
  ePSC_RunningDown = 9;
  
  ePSC_PitchToNoPA = 12;
  ePSC_SpeedControlAtNoPA = 13;
  ePSC_PitchToMax = 14;
  
  ePSC_PitchToNoPA_Idle = 24;
  ePSC_SpeedControlAtNoPA_Idle = 25;
  ePSC_PitchToPitchIdle	= 26;

%% Initialize the vector

  BladeOrder = 'Control';

  blades = cell(3,1);
  switch BladeOrder  
      case 'Load'
          blades = [1;3;2];
      otherwise
          blades = ['A';'B';'C'];
  end
   
  index = []; % Used in Operational Mode, This vector reflects the loadcases ...
            % that contributes to the Operational TYC range. For ...
            % instance if in specefic loadcase the production is not ...
            % active then that loadcase is overlooked in TYC operational ...
            % range computaion.

  loadcases = cell(p,1);
 
  FreeWindSpeedAvg = [];

  BladeWithMaxFlapMomentInSurvivalMode    = [];
  BladeWithMaxFlapMomentInOperationalMode = [];

  BladeWithMinFlapMomentInSurvivalMode    = [];
  BladeWithMinFlapMomentInOperationalMode = [];

  MaxBladeAFlapMomentSurvivalMode     = [];
  MaxBladeAFlapMomentOperationalMode  = [];
  MinBladeAFlapMomentSurvivalMode     = [];
  MinBladeAFlapMomentOperationalMode  = [];

  MaxBladeBFlapMomentSurvivalMode     = [];
  MaxBladeBFlapMomentOperationalMode  = [];
  MinBladeBFlapMomentSurvivalMode     = [];
  MinBladeBFlapMomentOperationalMode  = [];

  MaxBladeCFlapMomentSurvivalMode     = [];
  MaxBladeCFlapMomentOperationalMode  = [];
  MinBladeCFlapMomentSurvivalMode     = [];
  MinBladeCFlapMomentOperationalMode  = [];

  MaxFlapMomentSurvivalMode    = [];
  MaxFlapMomentOperationalMode = [];

  MinFlapMomentSurvivalMode    = [];
  MinFlapMomentOperationalMode = [];

  tElapsed = [];

%% Read sensor Data

  clc   % clear command window
  for i= 1:p 
     
      tStart = tic; % start the stopwatch time to measure the performance
      clear FreeWindSpeed FWSAvg ProdState TimeStepProdIsActive...
        BladeAFlapMoment BladeAFlapMomentOperationalRange BladeAFlapMomentSurvivalRange...
        BladeBFlapMoment BladeBFlapMomentOperationalRange BladeBFlapMomentSurvivalRange...
        BladeCFlapMoment BladeCFlapMomentOperationalRange BladeCFlapMomentSurvivalRange
           
      RemainingLoadcases = p-i+1;
      fprintf('Remaining Loadcases = %4d\n',RemainingLoadcases)
    
      disp('please wait...')
        
      % read '.int files
      loadcase = Files(i).name;
      folder = Files(i).folder;
      filepath = fullfile(folder,loadcase);
      [GenInfo,time,sensors,ErrorString] = LAC.timetrace.int.readint(filepath,dataflag,[],[],[]);
     
      % Read sensor name
      sensorData = LAC.vts.convert(fullfile(INTdirpath,'INT','sensor')); % Read sensor file to gain acces to long names which are not part of STA filesINTsensor
      idxFWS   = find(strcmp(sensorData.description, 'Char. free wind spd U')); % Find index of free wind speed
      idxPSC   = find(strcmp(sensorData.description, 'prn#PSC_ProdCtrlState')); % Find index of Production state 
      idxMx11r = find(strcmp(sensorData.description, string(flapSensors(1)))); % Find index of Flap bending moment - BLADE A
      idxMx31r = find(strcmp(sensorData.description, string(flapSensors(2)))); % Find index of Flap bending moment - BLADE B
      idxMx21r = find(strcmp(sensorData.description, string(flapSensors(3)))); % Find index of Flap bending moment - BLADE C

      
      idxRotorSpeedRPM = find(strcmp(sensorData.description,'Rotor speed'));         % Find index of Rotor Speed sensor given in RPM
      idxBladeAPitchAngleDeg = find(strcmp(sensorData.description,'Blade pitch 1')); % Find index of Balade A Pitch Angle given in DEGREE
      idxBladeBPitchAngleDeg = find(strcmp(sensorData.description,'Blade pitch 3')); % Find index of Balade B Pitch Angle given in DEGREE
      idxBladeCPitchAngleDeg = find(strcmp(sensorData.description,'Blade pitch 2')); % Find index of Balade C Pitch Angle given in DEGREE
      
      % extract the production states over the simulation time
      ProdState = sensors(:,idxPSC);   % extract production state data
      ProdState = uint8(ProdState);    % convert the data to unsigned 8 bits integer
      % ------------------------
      % Extract Rotor Speed 
      % ------------------------
      RotorSpeedRPM = sensors(:,idxRotorSpeedRPM);
      
      % ----------------------------------
      % Extract Pitch Angles of the Blades
      % ----------------------------------
      BladeAPitchAngleDeg = sensors(:,idxBladeAPitchAngleDeg);
      BladeBPitchAngleDeg = sensors(:,idxBladeBPitchAngleDeg);
      BladeCPitchAngleDeg = sensors(:,idxBladeCPitchAngleDeg);
      
      % Concatinate all Pitch Angles Vectors in a Matrix
      Theta = []; % Initialize Theta with empty matrix
      
      thetaA = BladeAPitchAngleDeg';  % Blade A pitch angle, row vector
      thetaB = BladeBPitchAngleDeg';  % Blade B pitch angle, row vector
      thetaC = BladeCPitchAngleDeg';  % Blade C pitch angle, row vector
      
      Theta = [thetaA;thetaB;thetaC]; % Contract Theta Matrix
      
      MaxPitchAngle = [];             % Initialized with empty matrix
      MaxPitchAngle = (max(Theta))';    % Compute the Maximum Pitch Angle...
                                      % among all blades at each time step
     % -------------------                                
     % Logical Operation
     % -------------------
      
     % Find Time Steps that Rotor Speed is less than the Minimum
     idxOmegaisLow = (RotorSpeedRPM <= MinRotorSpdRPM);
     
     % Find Time Steps that Pitch Angle is higher than the Maximum
     idxMaxPitchAngleisHigh = (MaxPitchAngle >= MaxPitchAngleDeg);
     
     % Find Time Steps that eighter one of above is active
     idxOmegaisLowOrPitchAngleisHigh = (idxOmegaisLow)|(idxMaxPitchAngleisHigh);
     
     % Find Time Steps that None of the above condition is active
     idxOmegaisNormANDPitchAngleisNorm = ~(idxOmegaisLowOrPitchAngleisHigh);
     
     % Find Time Step that Pause States is active
     idxPauseisActive = (ProdState == ePSC_PowerDown)|(ProdState == ePSC_Disconnecting)...
         |(ProdState == ePSC_RunningDown)|(ProdState == ePSC_PitchToNoPA)...
         |(ProdState == ePSC_SpeedControlAtNoPA)|(ProdState == ePSC_PitchToMax)...
         |(ProdState == ePSC_PitchToNoPA_Idle)|(ProdState == ePSC_SpeedControlAtNoPA_Idle)...
         |(ProdState == ePSC_PitchToPitchIdle);
         
    % Find Time Step that Production is active
      idxProdisActive = (ProdState == ePSC_Connecting)|(ProdState == ePSC_PowerUp)|...
        (ProdState == ePSC_Production)|(ProdState == ePSC_PrepareDisconnectSD)|...
        (ProdState == ePSC_DisconnectingSD)|(ProdState == ePSC_PrepareConnectSD); 
    
    % Find Time Step eighter production state or pause state are active
    idxFlapBendingMomentSensorisActive = ((idxPauseisActive)&(idxOmegaisNormANDPitchAngleisNorm))...
        |(idxProdisActive);
    % ---------------------------------------------------------------------
      FreeWindSpeed = sensors(:,idxFWS); % extract free wind speed
      FWSAvg = mean(FreeWindSpeed); % free wind speed average at each load case
     
    % ---------------------------------------------------------------------
    % update loadcase vector (remove underline and .int extention from the file name)
      [filepath,loadcase,ext] = fileparts(filepath);   
      loadcase = loadcase(loadcase ~= '_');
      loadcases(i,1) = cellstr(loadcase);
    
    % update mean value of free wind speed vector
      FreeWindSpeedAvg = [FreeWindSpeedAvg;FWSAvg];
    
    % ---------------------------------------------
 
    
    % If the turbine is not in production state then operational range no
    % need to compute, whereas the survival range is computed anyway.
     
    % ---------------------------------------------------------------------
     % consider the negetive of the sensore value
     
     factor = -1;
    % read sensor values 
     BladeAFlapMoment                 = factor.*sensors(:,idxMx11r);    % extract BladeA Flap Bending Moment
     BladeAFlapMomentSurvivalRange    = BladeAFlapMoment; % extract the survival range of the sensor
     BladeAFlapMomentOperationalRange = BladeAFlapMoment(idxFlapBendingMomentSensorisActive); % extract the operational range of the sensor
    
     BladeBFlapMoment                 = factor.*sensors(:,idxMx31r);    % extract BladeB Flap Bending Moment
     BladeBFlapMomentSurvivalRange    = BladeBFlapMoment; % extract the survival range of the sensor
     BladeBFlapMomentOperationalRange = BladeBFlapMoment(idxFlapBendingMomentSensorisActive); % extract the operational range of the sensor
    
     BladeCFlapMoment                 = factor.*sensors(:,idxMx21r);    % extract Bladec Flap Bending Moment
     BladeCFlapMomentSurvivalRange    = BladeCFlapMoment; % extract the survival range of the sensor
     BladeCFlapMomentOperationalRange = BladeCFlapMoment(idxFlapBendingMomentSensorisActive); % extract the operational range of the sensor
    
    
    % ---------------------------
    % Obtain the Survival Range
    % ---------------------------
    % ---------------------------------------------------------------------
    % compute the maximum of survival range of the sensors 
     MaxBladeAFlapMomentSurvivalMode     =  [MaxBladeAFlapMomentSurvivalMode;max(BladeAFlapMomentSurvivalRange)];
     MaxBladeBFlapMomentSurvivalMode     =  [MaxBladeBFlapMomentSurvivalMode;max(BladeBFlapMomentSurvivalRange)];
     MaxBladeCFlapMomentSurvivalMode     =  [MaxBladeCFlapMomentSurvivalMode;max(BladeCFlapMomentSurvivalRange)];
    
    % compute the maximum flap moment of all blades in survival mode for...
    % current loadcase
     tmp = [max(BladeAFlapMomentSurvivalRange),...
                                     max(BladeBFlapMomentSurvivalRange),...
                                     max(BladeCFlapMomentSurvivalRange)];
                                 
     MaxFlapMomentSurvivalMode = [MaxFlapMomentSurvivalMode;max(tmp)];
                                 
    % determine the blade that is suffered the maximum flap moment in survival mode                            
     BladeWithMaxFlapMomentInSurvivalMode = [BladeWithMaxFlapMomentInSurvivalMode;cellstr(blades(tmp == max(tmp)))];
        
    % compute the minimum of survival range of the sensors 
     MinBladeAFlapMomentSurvivalMode     =  [MinBladeAFlapMomentSurvivalMode;min(BladeAFlapMomentSurvivalRange)];
     MinBladeBFlapMomentSurvivalMode     =  [MinBladeBFlapMomentSurvivalMode;min(BladeBFlapMomentSurvivalRange)];
     MinBladeCFlapMomentSurvivalMode     =  [MinBladeCFlapMomentSurvivalMode;min(BladeCFlapMomentSurvivalRange)];
    
    % compute the minimum flap moment of all balades in survival mode for
    % each loadcase
     tmp = [min(BladeAFlapMomentSurvivalRange),...
                                     min(BladeBFlapMomentSurvivalRange),...
                                     min(BladeCFlapMomentSurvivalRange)];
                                 
     MinFlapMomentSurvivalMode = [MinFlapMomentSurvivalMode;min(tmp)];
                                  
    % determine the blade that is suffered the maximum flap moment in survival mode                           
     BladeWithMinFlapMomentInSurvivalMode = [BladeWithMinFlapMomentInSurvivalMode;cellstr(blades(tmp == min(tmp)))];
    
    % ----------------------------
    % Obtain the Operational Range
    % ----------------------------
    % ---------------------------------------------------------------------
    
     if (~isempty(idxFlapBendingMomentSensorisActive(idxFlapBendingMomentSensorisActive ~= 0)))
         
        % compute the maximum of operational range of the sensors 
         MaxBladeAFlapMomentOperationalMode  =  [MaxBladeAFlapMomentOperationalMode;max(BladeAFlapMomentOperationalRange)];
         MaxBladeBFlapMomentOperationalMode  =  [MaxBladeBFlapMomentOperationalMode;max(BladeBFlapMomentOperationalRange)];
         MaxBladeCFlapMomentOperationalMode  =  [MaxBladeCFlapMomentOperationalMode;max(BladeCFlapMomentOperationalRange)];
    
        
        % compute the maximum flap moment of all blades in operational mode for
        % each loadcase
         tmp = [max(BladeAFlapMomentOperationalRange),...
                                     max(BladeBFlapMomentOperationalRange),...
                                     max(BladeCFlapMomentOperationalRange)];
    
         MaxFlapMomentOperationalMode = [MaxFlapMomentOperationalMode;max(tmp)];
    
    
        % determine the blade that is suffered the maximum flap moment in operational mode at each loadcase                           
         BladeWithMaxFlapMomentInOperationalMode  = [BladeWithMaxFlapMomentInOperationalMode;cellstr(blades(tmp == max(tmp)))];
    

        % compute the minimum of operational range of the sensors 
         MinBladeAFlapMomentOperationalMode  =  [MinBladeAFlapMomentOperationalMode;min(BladeAFlapMomentOperationalRange)];
         MinBladeBFlapMomentOperationalMode  =  [MinBladeBFlapMomentOperationalMode;min(BladeBFlapMomentOperationalRange)];
         MinBladeCFlapMomentOperationalMode  =  [MinBladeCFlapMomentOperationalMode;min(BladeCFlapMomentOperationalRange)];
        
        % compute the maximum flap moment of all balades in operational mode
         tmp = [min(BladeAFlapMomentOperationalRange),...
                                     min(BladeBFlapMomentOperationalRange),...
                                     min(BladeCFlapMomentOperationalRange)];
                                 
        MinFlapMomentOperationalMode = [MinFlapMomentOperationalMode;min(tmp)];
                                  
      % determine the blade that is suffered the maximum flap moment in operational mode                               
       BladeWithMinFlapMomentInOperationalMode = [BladeWithMinFlapMomentInOperationalMode;cellstr(blades(tmp == min(tmp)))];
      
      % specifies the loadcases that production is active
       index = [index;i];   
    end
     
    % Estimates the remaining time
    tElapsed(i) = toc(tStart);   % compute the elapsed time
    tRemainSec = sum(tElapsed)*((p-i)/i); % estimated the remaining time
    tRemainMin = tRemainSec/60;  % convert remaining time to minitues
    if (tRemainMin < 1)
        fprintf('Estimated Remaining Time = %8.0f second\n',tRemainSec) % display the remaining time in second
    else
        fprintf('Estimated Remaining Time = %4.0f minutes\n',tRemainMin) % display the remaining time in minites
    end
  
  end
 disp('...done')


%% Extract the relevent loadcases where the Power production is active ...
% In order to compute the Operational range of Flap Bending Moment

 ActiveLoadcasesInOperationalMode = loadcases(index); % Extract the loadcase that Power production is active
 ActiveFWSAvgInOperationalMode    = FreeWindSpeedAvg(index); % Extract the mean of free wind speed for the loadcases that the production is active

%% Sorts the vectors

 pause(5); % Wait 5 Second
%clc  % clear command window

 BladeWithSigMaxFlapMomentInSurvivalMode    = [];
 BladeWithSigMaxFlapMomentInOperationalMode = [];
 BladeWithSigMinFlapMomentInSurvivalMode    = [];
 BladeWithSigMinFlapMomentInOperationalMode = [];

 SigMaxInSurvivalModeLoadcases              = [];
 SigMinInSurvivalModeLoadcases              = [];
 SigMaxInOperationalModeLoadcases           = [];
 SigMinInOperationalModeLoadcases           = [];

 IndexSigMaxSurvivalMode                    = [];
 IndexSigMaxOperationalMode                 = []; 
 IndexSigMinSurvivalMode                    = []; 
 IndexSigMinOperationalMode                 = []; 

% -------------------------------------------------------------------------
% Compute the highest 'n' value of the Maximum Flap Moment in Survival ...
% Mode.
% -------------------------------------------------------------------------

% Sort the elements of Max vector in descending order
 SortedMaxFlapMomentSurvivalMode = sort(MaxFlapMomentSurvivalMode,'descend');

% Take the most significant 'n' values determined by user
 SignificantMaxFlapMomentSurvivalMode = SortedMaxFlapMomentSurvivalMode(1:n,1); 

% Extract the unique values
 UniqueSignificantMaxFlapMomentSurvivalMode = sort(unique(SignificantMaxFlapMomentSurvivalMode),'descend');

% calculate the number of iterations
 iMaxSurval = length(UniqueSignificantMaxFlapMomentSurvivalMode);

% Determine the blade and loadcase of the significant maximum vector
 for i=1:iMaxSurval
    clear tmp
    tmp = find(MaxFlapMomentSurvivalMode == UniqueSignificantMaxFlapMomentSurvivalMode(i,1)); % Obtain the index of the highest Flap moment
    BladeWithSigMaxFlapMomentInSurvivalMode = vertcat(BladeWithSigMaxFlapMomentInSurvivalMode,cell2mat(BladeWithMaxFlapMomentInSurvivalMode(tmp,1))); % Obtain the blade associated to the highest Flap moment in Survival Mode
    SigMaxInSurvivalModeLoadcases = vertcat(SigMaxInSurvivalModeLoadcases,loadcases(tmp,1)); % Obtain the loadcase that causes the highest Flap moment in Survival mode
    
    IndexSigMaxSurvivalMode = [IndexSigMaxSurvivalMode;tmp]; % obtain the index of the loadcases that cause the highest Flap moments in Survival Mode
 end

% -------------------------------------------------------------------------
% Compute the lowest 'n' value of the Minimum Flap Moment in Survival ...
% Mode.
% -------------------------------------------------------------------------

% Sort the elements of Min vector in ascending order
 SortedMinFlapMomentSurvivalMode    = sort(MinFlapMomentSurvivalMode);   

% Take the most significant values determined by user
 SignificantMinFlapMomentSurvivalMode    = SortedMinFlapMomentSurvivalMode(1:n,1); 

% Extract the unique minimum moments
 UniqueSignificantMinFlapMomentSurvivalMode    = unique(SignificantMinFlapMomentSurvivalMode);

% Calculate the number of iterations
 iMinSurval  = length(UniqueSignificantMinFlapMomentSurvivalMode);

% Determine the blade and loadcase of the lowest Flap moment value
 for i=1:iMinSurval
     clear tmp
     tmp = find(MinFlapMomentSurvivalMode == UniqueSignificantMinFlapMomentSurvivalMode(i,1)); % Obtain the index of the lowest Flap moment
     BladeWithSigMinFlapMomentInSurvivalMode = vertcat(BladeWithSigMinFlapMomentInSurvivalMode,cell2mat(BladeWithMinFlapMomentInSurvivalMode(tmp,1))); % Obtain the blade associated to the lowest Flap moment in Survival Mode
     SigMinInSurvivalModeLoadcases = vertcat(SigMinInSurvivalModeLoadcases,loadcases(tmp,1)); % Obtain the loadcase that causes the lowest Flap moment in Survival mode
    
     IndexSigMinSurvivalMode = [IndexSigMinSurvivalMode;tmp]; % obtain the index of the loadcases that cause the lowest Flap moments in Survival Mode
 end



% -------------------------------------------------------------------------
% Compute the highest 'n' value of the Maximum Flap Moment in Operational
% Mode.
% -------------------------------------------------------------------------

 if (~isempty(MaxFlapMomentOperationalMode))
     if (n > length(MaxFlapMomentOperationalMode)) 
        
         fprintf('n is higher than the length of the highest flap moments computed in Operational Mode\n')
         fprintf('Acordingly n is set to %3d\n',length(MaxFlapMomentOperationalMode))
         nOpr = length(MaxFlapMomentOperationalMode); % Change 'n' to the length of the Max of Flap moment vector
     else
         nOpr = n;
     end

        % Sort the elements of Max vector in descending order
         SortedMaxFlapMomentOperationalMode = sort(MaxFlapMomentOperationalMode,'descend');

        % Take the most significant 'n' values determined by user
         SignificantMaxFlapMomentOperationalMode = SortedMaxFlapMomentOperationalMode(1:nOpr,1);

        % Extract the unique values
         UniqueSignificantMaxFlapMomentOperationalMode = sort(unique(SignificantMaxFlapMomentOperationalMode),'descend');

        % Calculate the number of iterations
         iMaxOperational = length(UniqueSignificantMaxFlapMomentOperationalMode);

        % determine the blades of the most significant values
         for i=1:iMaxOperational 
             clear tmp
             tmp = find(MaxFlapMomentOperationalMode == UniqueSignificantMaxFlapMomentOperationalMode(i,1)); % Obtain the index of the highest Flap moment in Operational Mode
             BladeWithSigMaxFlapMomentInOperationalMode = vertcat(BladeWithSigMaxFlapMomentInOperationalMode,cell2mat(BladeWithMaxFlapMomentInOperationalMode(tmp,1))); % Obtain the blade associated to the lowest Flap moment in Operational Mode
             SigMaxInOperationalModeLoadcases = vertcat(SigMaxInOperationalModeLoadcases,loadcases(index(tmp),1)); % Obtain the loadcase that causes the lowest Flap moment in Operational Mode
             IndexSigMaxOperationalMode = [IndexSigMaxOperationalMode;index(tmp)]; % Obtain the index of the loadcases that cause the lowest Flap moments in Operational Mode
         end     
 end

% -------------------------------------------------------------------------
% Compute the lowest 'n' value of the Maximum Flap Moment in Operational
% Mode.
% -------------------------------------------------------------------------

 if (~isempty(MinFlapMomentOperationalMode))
     if (n > length(MinFlapMomentOperationalMode)) 
        
         fprintf('n is higher than the length of the highest flap moments computed in Operational Mode\n')
         fprintf('Acordingly n is set to %3d\n',length(MinFlapMomentOperationalMode))
         nOpr = length(MinFlapMomentOperationalMode); % Change 'n' to the length of the Min of Flap moment vector
     else
         nOpr = n;
     end
        
        % Sort the elements of Max vector in descending order
         SortedMinFlapMomentOperationalMode = sort(MinFlapMomentOperationalMode);

        % Take the most significant 'n' values determined by user
         SignificantMinFlapMomentOperationalMode = SortedMinFlapMomentOperationalMode(1:nOpr,1);

        % Extract the unique values
         UniqueSignificantMinFlapMomentOperationalMode = sort(unique(SignificantMinFlapMomentOperationalMode));

        % Calculate the number of iterations
         iMinOperational = length(UniqueSignificantMinFlapMomentOperationalMode);

        % determine the blades of the most significant values
         for i=1:iMinOperational 
             clear tmp
             tmp = find(MinFlapMomentOperationalMode == UniqueSignificantMinFlapMomentOperationalMode(i,1)); % Obtain the index of the highest Flap moment in Operational Mode
             BladeWithSigMinFlapMomentInOperationalMode = vertcat(BladeWithSigMinFlapMomentInOperationalMode,cell2mat(BladeWithMinFlapMomentInOperationalMode(tmp,1))); % Obtain the blade associated to the lowest Flap moment in Operational Mode
             SigMinInOperationalModeLoadcases = vertcat(SigMinInOperationalModeLoadcases,loadcases(index(tmp),1)); % Obtain the loadcase that causes the lowest Flap moment in Operational Mode
             IndexSigMinOperationalMode = [IndexSigMinOperationalMode;index(tmp)]; % Obtain the index of the loadcases that cause the lowest Flap moments in Operational Mode
         end         
 end
    
%% Apply margin to the maximum and minimum in Survival and Operation mode

% -------------------------------------------------------------------------
% Extract the first element of the Max and Min of the Flap moment computed
% in Survival Mode.
% -------------------------------------------------------------------------
 MaxofMaxSurvivalMode = SignificantMaxFlapMomentSurvivalMode(1,1);
 MinofMinSurvivalMode = SignificantMinFlapMomentSurvivalMode(1,1);

 % Determine the sign of the Maximum in Survival Morde
 if (MaxofMaxSurvivalMode > 0)
     ProposedMaxFlapMomentSurvivalMode = MaxofMaxSurvivalMode + 0.01*margin*MaxofMaxSurvivalMode;
 else
     ProposedMaxFlapMomentSurvivalMode = MaxofMaxSurvivalMode - 0.01*margin*MaxofMaxSurvivalMode;
 end

% Determine the sign of the Minimum in Survival Morde
 if (MinofMinSurvivalMode > 0)
     ProposedMinFlapMomentSurvivalMode = MinofMinSurvivalMode - 0.01*margin*MinofMinSurvivalMode;
 else
     ProposedMinFlapMomentSurvivalMode = MinofMinSurvivalMode + 0.01*margin*MinofMinSurvivalMode;
 end

% Transfer the results to the function outputs
 FlapMomentProposedRangeSurvivalMode = [ProposedMinFlapMomentSurvivalMode,ProposedMaxFlapMomentSurvivalMode];

% -------------------------------------------------------------------------
% Extract the first element of the Max and Min of the Flap moment computed
% in Operational Mode.
% -------------------------------------------------------------------------
 if (~isempty(MaxFlapMomentOperationalMode))
     MaxofMaxOperationalMode = SignificantMaxFlapMomentOperationalMode(1,1);     
 else
     MaxofMaxOperationalMode  = NaN;   
 end

 if (~isempty(MinFlapMomentOperationalMode))
     MinofMinOperationalMode = SignificantMinFlapMomentOperationalMode(1,1);    
 else
     MinofMinOperationalMode = NaN;
 end

% Determine the Max and Min of the sensor range based on margin in
% Operational Mode 

% Determine the sign of the Maximum in Operational Mode
 if (MaxofMaxOperationalMode > 0)
     ProposedMaxFlapMomentOperationalMode = MaxofMaxOperationalMode + 0.01*margin*MaxofMaxOperationalMode; 
 else 
     ProposedMaxFlapMomentOperationalMode = MaxofMaxOperationalMode - 0.01*margin*MaxofMaxOperationalMode; 
 end

% Determine the sign of the Minimum in Operational Mode
 if (MinofMinOperationalMode > 0)
     ProposedMinFlapMomentOperationalMode = MinofMinOperationalMode - 0.01*margin*MinofMinOperationalMode;
 else
     ProposedMinFlapMomentOperationalMode = MinofMinOperationalMode + 0.01*margin*MinofMinOperationalMode;
 end

% Transfer the results to the function outputs
 FlapMomentProposedRangeOperationalMode = [ProposedMinFlapMomentOperationalMode,ProposedMaxFlapMomentOperationalMode];

%% Archive the data in order to be retrieved for furthur analysis

 % Generate randome mat file
 %r = randi([1 1000]);
 r = datestr(now,30);
 matfilename = strcat('FlapMomentSensorRange-',r);
 
 MAText = '.mat';
 filename = strcat(matfilename,MAText); % file name for data storage

 delete(filename) % Delet the filename 

% -------------------------------------------------------------------------
%                          Variable assigenments
% -------------------------------------------------------------------------

 var00 = 'p';
 var01 = 'n';
 var02 = 'nOpr';
 var03 = 'loadcases';
 var04 = 'FreeWindSpeedAvg';
 var05 = 'index';
 var06 = 'ActiveLoadcasesInOperationalMode';
 var07 = 'ActiveFWSAvgInOperationalMode';
 var08 = 'margin';


 var11 = 'MaxFlapMomentSurvivalMode';
 var12 = 'BladeWithMaxFlapMomentInSurvivalMode';

 var21 = 'MinFlapMomentSurvivalMode';
 var22 = 'BladeWithMinFlapMomentInSurvivalMode';

 var31 = 'MaxFlapMomentOperationalMode';
 var32 = 'BladeWithMaxFlapMomentInOperationalMode';

 var41 = 'MinFlapMomentOperationalMode';
 var42 = 'BladeWithMinFlapMomentInOperationalMode';

 var51 = 'BladeWithSigMaxFlapMomentInSurvivalMode';
 var52 = 'SigMaxInSurvivalModeLoadcases';
 var53 = 'IndexSigMaxSurvivalMode';
 var54 = 'SignificantMaxFlapMomentSurvivalMode';

 var61 = 'BladeWithSigMinFlapMomentInSurvivalMode';
 var62 = 'SigMinInSurvivalModeLoadcases';
 var63 = 'IndexSigMinSurvivalMode';
 var64 = 'SignificantMinFlapMomentSurvivalMode';

 var71 = 'BladeWithSigMaxFlapMomentInOperationalMode';
 var72 = 'SigMaxInOperationalModeLoadcases';
 var73 = 'IndexSigMaxOperationalMode';
 var74 = 'SignificantMaxFlapMomentOperationalMode';

 var81 = 'BladeWithSigMinFlapMomentInOperationalMode';
 var82 = 'SigMinInOperationalModeLoadcases';
 var83 = 'IndexSigMinOperationalMode';
 var84 = 'SignificantMinFlapMomentOperationalMode';

 var91 = 'ProposedMinFlapMomentSurvivalMode';
 var92 = 'ProposedMaxFlapMomentSurvivalMode';
 
 var96 = 'ProposedMinFlapMomentOperationalMode';
 var97 = 'ProposedMaxFlapMomentOperationalMode';
% -------------------------------------------------------------------------
% Save Data in filename
 save(filename,var00,var01,var02,var03,var04,var05,var06,...
     var07,var08,var11,var12, var21,var22,var31,var32,var41,...
     var42,var51,var52,var53,var54,var61,var62,var63,var64,...
     var71,var72,var73,var74,var81,var82,var83,var84,...
     var91,var92,var96,var97);


%% plot the Survival range results

 clc
 % close all
                          
% plot the rest of points
 hfigure = figure;
 legentry = cell(2*n,1);      % specify the leend of most significant moments
 for i=1:n
     scatter(FreeWindSpeedAvg(IndexSigMaxSurvivalMode(i,1)),...
        SignificantMaxFlapMomentSurvivalMode(i,1),120,'filled');
     legentry{i} = strcat(SigMaxInSurvivalModeLoadcases{i,1},',Blade',BladeWithSigMaxFlapMomentInSurvivalMode(i,1),...
        ', ',num2str(SignificantMaxFlapMomentSurvivalMode(i,1)),'kNm' );
     hold on
 end

 for i=1:n
     scatter(FreeWindSpeedAvg(IndexSigMinSurvivalMode(i,1)),...
        SignificantMinFlapMomentSurvivalMode(i,1),120,'filled');
    legentry{n+i} = strcat(SigMinInSurvivalModeLoadcases{i,1},',Blade',BladeWithSigMinFlapMomentInSurvivalMode(i,1),...
        ', ',num2str(SignificantMinFlapMomentSurvivalMode(i,1)),'kNm' );
    hold on
 end

 clear tmp tmp2
 tmp = (1:p)'; % creat a vector with dimension of the number of loadcases
 tmp2 = tmp(~ismember(tmp,IndexSigMaxSurvivalMode)); % remove the indecis of the most maximum flap moment values  
 scatter(FreeWindSpeedAvg(tmp2),MaxFlapMomentSurvivalMode(tmp2));
 hold on
% plot the rest of points
 clear tmp2
 tmp2 = tmp(~ismember(tmp,IndexSigMinSurvivalMode));  % remove the indecis of the most maximum flap moment values  
 scatter(FreeWindSpeedAvg(tmp2),MinFlapMomentSurvivalMode(tmp2))
 hold on
 % plot the margins
 x = 0:0.01:max(FreeWindSpeedAvg)*1.2;
 plot(x,ProposedMinFlapMomentSurvivalMode*ones(length(x),1),'r--','LineWidth',2)
 hold on
 plot(x,ProposedMaxFlapMomentSurvivalMode*ones(length(x),1),'r--','LineWidth',2)

% Add text to the graph 
 TextVertFac = 0.97;   % Vertical place of the text
 %xmin = max(x);
 xmin = min(x);
 ymin = ProposedMinFlapMomentSurvivalMode * TextVertFac;

 %xmax = max(x);
 xmax = min(x);
 ymax = ProposedMaxFlapMomentSurvivalMode * TextVertFac;

 strmin = ['Minimum - ',num2str(margin),' % ',' = ',num2str(ProposedMinFlapMomentSurvivalMode),'[kNm]'];
 text(xmin,ymin,strmin,'HorizontalAlignment','left');

 strmax = ['Maximum + ',num2str(margin),' % ',' = ',num2str(ProposedMaxFlapMomentSurvivalMode),'[kNm]'];
 text(xmax,ymax,strmax,'HorizontalAlignment','left');

 grid on

 lgd = legend(legentry,'Location','west');
 title(lgd,'Highest and Lowest Flap Moments')
 xlabel('Free Wind Speed Average [m/s]')
 ylabel('Flap Bending Moment [kNm]')
 xlim([0 max(FreeWindSpeedAvg)*1.3])
 title('Survival Range')

 %% plot the operational range

 clc
 clear legentry
                          
 % plot the rest of points
 hfigure = figure;

 legentry = cell(2*nOpr,1);      % specify the leend of most significant moments
 for i=1:nOpr
     scatter(FreeWindSpeedAvg(IndexSigMaxOperationalMode(i,1)),...
        SignificantMaxFlapMomentOperationalMode(i,1),120,'filled');
     legentry{i} = strcat(SigMaxInOperationalModeLoadcases{i,1},',Blade',BladeWithSigMaxFlapMomentInOperationalMode(i,1),...
        ', ',num2str(SignificantMaxFlapMomentOperationalMode(i,1)),'kNm' );
     hold on
 end

 for i=1:nOpr
     scatter(FreeWindSpeedAvg(IndexSigMinOperationalMode(i,1)),...
        SignificantMinFlapMomentOperationalMode(i,1),120,'filled');
    legentry{n+i} = strcat(SigMinInOperationalModeLoadcases{i,1},',Blade',BladeWithSigMinFlapMomentInOperationalMode(i,1),...
        ', ',num2str(SignificantMinFlapMomentOperationalMode(i,1)),'kNm' );
    hold on
 end

 clear tmp tmp2
 tmp = (1:length(ActiveFWSAvgInOperationalMode))'; % creat a vector with dimension of the number of loadcases
 tmp2 = tmp(~ismember(index(tmp),IndexSigMaxOperationalMode)); % remove the indecis of the most maximum flap moment values  
 scatter(ActiveFWSAvgInOperationalMode(tmp2),MaxFlapMomentOperationalMode(tmp2));
 hold on
% plot the rest of points
 clear tmp2
 tmp2 = tmp(~ismember(index(tmp),IndexSigMinOperationalMode));  % remove the indecis of the most maximum flap moment values  
 scatter(ActiveFWSAvgInOperationalMode(tmp2),MinFlapMomentOperationalMode(tmp2))
 hold on
% plot the margins
 x = 0:0.01:max(ActiveFWSAvgInOperationalMode)*1.2; 
 plot(x,ProposedMinFlapMomentOperationalMode*ones(length(x),1),'r--','LineWidth',2)
 hold on
 plot(x,ProposedMaxFlapMomentOperationalMode*ones(length(x),1),'r--','LineWidth',2)

% Add text to the graph 
 %xmin = max(x);
 xmin = min(x);
 ymin = ProposedMinFlapMomentOperationalMode * TextVertFac;

 %xmax = max(x);
 xmax = min(x);
 ymax = ProposedMaxFlapMomentOperationalMode * TextVertFac;

 strmin = ['Minimum - ',num2str(margin),' % ',' = ',num2str(ProposedMinFlapMomentOperationalMode),'[kNm]'];
 text(xmin,ymin,strmin,'HorizontalAlignment','left');

 strmax = ['Maximum + ',num2str(margin),' % ',' = ',num2str(ProposedMaxFlapMomentOperationalMode),'[kNm]'];
 text(xmax,ymax,strmax,'HorizontalAlignment','left');

 grid on

 lgd = legend(legentry,'Location','west');
 title(lgd,'Highest and Lowest Flap Moments')
 xlabel('Free Wind Speed Average [m/s]')
 ylabel('Flap Bending Moment [kNm]')
 xlim([0 max(ActiveFWSAvgInOperationalMode)*1.3])
 title('Operational Range')

 
%% Retrive the available data
elseif (RetrieveData)
    MAText = '.mat';
    matfilename = strcat(filename,MAText); % mat file 
    load(matfilename)
    
    % Remove underline from filename
    filename = filename(filename ~= '_');
    
    % Plot the Data
    clc
    %close all
                          
% plot the rest of points
   figure
   legentry = cell(2*n,1);      % specify the leend of most significant moments
   for i=1:n
       scatter(FreeWindSpeedAvg(IndexSigMaxSurvivalMode(i,1)),...
          SignificantMaxFlapMomentSurvivalMode(i,1),120,'filled');
       legentry{i} = strcat(SigMaxInSurvivalModeLoadcases{i,1},',Blade',BladeWithSigMaxFlapMomentInSurvivalMode(i,1),...
          ', ',num2str(SignificantMaxFlapMomentSurvivalMode(i,1)),'kNm' );
       hold on
   end

   for i=1:n
       scatter(FreeWindSpeedAvg(IndexSigMinSurvivalMode(i,1)),...
          SignificantMinFlapMomentSurvivalMode(i,1),120,'filled');
      legentry{n+i} = strcat(SigMinInSurvivalModeLoadcases{i,1},',Blade',BladeWithSigMinFlapMomentInSurvivalMode(i,1),...
          ', ',num2str(SignificantMinFlapMomentSurvivalMode(i,1)),'kNm' );
      hold on
   end

   clear tmp tmp2
   tmp = (1:p)'; % creat a vector with dimension of the number of loadcases
   tmp2 = tmp(~ismember(tmp,IndexSigMaxSurvivalMode)); % remove the indecis of the most maximum flap moment values  
   scatter(FreeWindSpeedAvg(tmp2),MaxFlapMomentSurvivalMode(tmp2));
   hold on
% plot the rest of points
   clear tmp2
   tmp2 = tmp(~ismember(tmp,IndexSigMinSurvivalMode));  % remove the indecis of the most maximum flap moment values  
   scatter(FreeWindSpeedAvg(tmp2),MinFlapMomentSurvivalMode(tmp2))
   hold on
 % plot the margins
   x = 0:0.01:max(FreeWindSpeedAvg)*1.2;
   plot(x,ProposedMinFlapMomentSurvivalMode*ones(length(x),1),'r--','LineWidth',2)
   hold on
   plot(x,ProposedMaxFlapMomentSurvivalMode*ones(length(x),1),'r--','LineWidth',2)

% Add text to the graph 
   %xmin = max(x);
   TextVertFac = 0.97;   % Vertical place of the text 
   xmin = min(x);
   ymin = ProposedMinFlapMomentSurvivalMode * TextVertFac;

   %xmax = max(x);
   xmax = min(x);
   ymax = ProposedMaxFlapMomentSurvivalMode * TextVertFac;

   strmin = ['Minimum - ',num2str(margin),' % ',' = ',num2str(ProposedMinFlapMomentSurvivalMode),'[kNm]'];
   text(xmin,ymin,strmin,'HorizontalAlignment','left');

   strmax = ['Maximum + ',num2str(margin),' % ',' = ',num2str(ProposedMaxFlapMomentSurvivalMode),'[kNm]'];
   text(xmax,ymax,strmax,'HorizontalAlignment','left');

   grid on

   lgd = legend(legentry,'Location','west');
   title(lgd,'Highest and Lowest Flap Moments')
   xlabel('Free Wind Speed Average [m/s]')
   ylabel('Flap Bending Moment [kNm]')
   xlim([0 max(FreeWindSpeedAvg)*1.3])
   txt = strcat('Survival Range',',',filename);
   title({'Survival Range',filename})

 %% plot the operational range

   clc
   clear legentry
                          
 % plot the rest of points
    figure
   legentry = cell(2*nOpr,1);      % specify the leend of most significant moments
   for i=1:nOpr
       scatter(FreeWindSpeedAvg(IndexSigMaxOperationalMode(i,1)),...
          SignificantMaxFlapMomentOperationalMode(i,1),120,'filled');
       legentry{i} = strcat(SigMaxInOperationalModeLoadcases{i,1},',Blade',BladeWithSigMaxFlapMomentInOperationalMode(i,1),...
          ', ',num2str(SignificantMaxFlapMomentOperationalMode(i,1)),'kNm' );
       hold on
   end

   for i=1:nOpr
       scatter(FreeWindSpeedAvg(IndexSigMinOperationalMode(i,1)),...
          SignificantMinFlapMomentOperationalMode(i,1),120,'filled');
      legentry{n+i} = strcat(SigMinInOperationalModeLoadcases{i,1},',Blade',BladeWithSigMinFlapMomentInOperationalMode(i,1),...
          ', ',num2str(SignificantMinFlapMomentOperationalMode(i,1)),'kNm' );
      hold on
   end

   clear tmp tmp2
   tmp = (1:length(ActiveFWSAvgInOperationalMode))'; % creat a vector with dimension of the number of loadcases
   tmp2 = tmp(~ismember(index(tmp),IndexSigMaxOperationalMode)); % remove the indecis of the most maximum flap moment values  
   scatter(ActiveFWSAvgInOperationalMode(tmp2),MaxFlapMomentOperationalMode(tmp2));
   hold on
% plot the rest of points
   clear tmp2
   tmp2 = tmp(~ismember(index(tmp),IndexSigMinOperationalMode));  % remove the indecis of the most maximum flap moment values  
   scatter(ActiveFWSAvgInOperationalMode(tmp2),MinFlapMomentOperationalMode(tmp2))
   hold on
% plot the margins
   x = 0:0.01:max(ActiveFWSAvgInOperationalMode)*1.2; 
   plot(x,ProposedMinFlapMomentOperationalMode*ones(length(x),1),'r--','LineWidth',2)
   hold on
   plot(x,ProposedMaxFlapMomentOperationalMode*ones(length(x),1),'r--','LineWidth',2)

% Add text to the graph 
   %xmin = max(x);
   xmin = min(x);
   ymin = ProposedMinFlapMomentOperationalMode * TextVertFac;

   %xmax = max(x);
   xmax = min(x);
   ymax = ProposedMaxFlapMomentOperationalMode * TextVertFac;

   strmin = ['Minimum - ',num2str(margin),' % ',' = ',num2str(ProposedMinFlapMomentOperationalMode),'[kNm]'];
   text(xmin,ymin,strmin,'HorizontalAlignment','left');

   strmax = ['Maximum + ',num2str(margin),' % ',' = ',num2str(ProposedMaxFlapMomentOperationalMode),'[kNm]'];
   text(xmax,ymax,strmax,'HorizontalAlignment','left');

   grid on

   lgd = legend(legentry,'Location','west');
   title(lgd,'Highest and Lowest Flap Moments')
   xlabel('Free Wind Speed Average [m/s]')
   ylabel('Flap Bending Moment [kNm]')
   xlim([0 max(ActiveFWSAvgInOperationalMode)*1.3])
   txt = strcat('Operational Range',',',filename);
   title({'Operational Range',filename})
     
   % Constract the Outputs
   FlapMomentProposedRangeSurvivalMode = [ProposedMinFlapMomentSurvivalMode,ProposedMaxFlapMomentSurvivalMode];
   FlapMomentProposedRangeOperationalMode = [ProposedMinFlapMomentOperationalMode,ProposedMaxFlapMomentOperationalMode];
    
end
%% Display the job was Done!
disp('Done successfully...')

