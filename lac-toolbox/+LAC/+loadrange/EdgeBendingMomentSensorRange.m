function [EdgeMomentProposedRangeSurvivalMode,EdgeMomentProposedRangeOperationalMode] = EdgeBendingMomentSensorRange(path,n,margin,MinRotorSpdRPM,MaxPitchAngleDeg)
%% FUNCTION DESCRIPTION 

% The script is used to compute the range of the EDGE BENDING MOMENT sensor 


% The script computes the highest and lowest measurements over given INT 
% files, meaning for each loadcase the maximum and minimum of the sensor 
% is computed as a function of the free wind speed average. Afterwards, 
% maximum over all maximum and minimum all over minimum will be 
% calculated. This range is considered as a desired range for Edge 
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
% EdgeMomentProposedRangeSurvivalMode : represents a vector contains min
% and max of the sensor range by considering the safty margin in
% survival mode. It should be  mentioned that if a user only desires to 
% compute the actual range the margin should be set to zero.
% EdgeMomentProposedRangeOperationalMode : represents a vector contains min
% and max of the sensor range by considering the safty margin in
% operational mode. It should be mentioned that if a user only desires to 
% compute the actual range the margin should be set to zero.


%% Initialization 

clc
%clear all
%close all


%% Optional: Change Edge Load Sensor

% change this sensor only if required. Find the description of the sensor
% in the sensors file inside INT folder. 
edgeSensors = {'Moment about normal angle axis B1-Pos1, 2.500m'; 'Moment about normal angle axis B3-Pos1, 2.500m'; 'Moment about normal angle axis B2-Pos1, 2.500m'};


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
% Margin = 20 % the extra margin that applies to maxand min of the edge moment
% n = 5 No. of most significant loadcases

    if (nargin > 5) 
        error('Too Many Inputs,requires at most three inputs\n')
    elseif (nargin < 1)
        error('No Inputs,requires at least one inputs\n')
    elseif ~isempty(path)
        if isempty(n)
            n = 5; % Determine the number of significant loadcases
        end
        if isempty(margin)
            margin = 35; % Determine the defaulf margin
        end
        if isempty(MinRotorSpdRPM)
            MinRotorSpdRPM = 450;  % Determine the default Rotor Speed
        end
        if isempty(MaxPitchAngleDeg)
             MaxPitchAngleDeg = 70; % Determine the default Pitch Angle
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

  BladeWithMaxEdgeMomentInSurvivalMode    = [];
  BladeWithMaxEdgeMomentInOperationalMode = [];

  BladeWithMinEdgeMomentInSurvivalMode    = [];
  BladeWithMinEdgeMomentInOperationalMode = [];

  MaxBladeAEdgeMomentSurvivalMode     = [];
  MaxBladeAEdgeMomentOperationalMode  = [];
  MinBladeAEdgeMomentSurvivalMode     = [];
  MinBladeAEdgeMomentOperationalMode  = [];

  MaxBladeBEdgeMomentSurvivalMode     = [];
  MaxBladeBEdgeMomentOperationalMode  = [];
  MinBladeBEdgeMomentSurvivalMode     = [];
  MinBladeBEdgeMomentOperationalMode  = [];

  MaxBladeCEdgeMomentSurvivalMode     = [];
  MaxBladeCEdgeMomentOperationalMode  = [];
  MinBladeCEdgeMomentSurvivalMode     = [];
  MinBladeCEdgeMomentOperationalMode  = [];

  MaxEdgeMomentSurvivalMode    = [];
  MaxEdgeMomentOperationalMode = [];

  MinEdgeMomentSurvivalMode    = [];
  MinEdgeMomentOperationalMode = [];

  tElapsed = [];

%% Read sensor Data

  clc   % clear command window
  for i= 1:p 
     
      tStart = tic; % start the stopwatch time to measure the performance
      clear FreeWindSpeed FWSAvg ProdState TimeStepProdIsActive...
        BladeAEdgeMoment BladeAEdgeMomentOperationalRange BladeAEdgeMomentSurvivalRange...
        BladeBEdgeMoment BladeBEdgeMomentOperationalRange BladeBEdgeMomentSurvivalRange...
        BladeCEdgeMoment BladeCEdgeMomentOperationalRange BladeCEdgeMomentSurvivalRange
           
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
      idxMy11r = find(strcmp(sensorData.description, string(edgeSensors(1)))); % Find index of Edge bending moment - BLADE A
      idxMy31r = find(strcmp(sensorData.description, string(edgeSensors(2)))); % Find index of Edge bending moment - BLADE B
      idxMy21r = find(strcmp(sensorData.description, string(edgeSensors(3)))); % Find index of Edge bending moment - BLADE C
       
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
    idxEdgeBendingMomentSensorisActive = ((idxPauseisActive)&(idxOmegaisNormANDPitchAngleisNorm))...
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
     BladeAEdgeMoment                 = factor.*sensors(:,idxMy11r);    % extract BladeA Edge Bending Moment
     BladeAEdgeMomentSurvivalRange    = BladeAEdgeMoment; % extract the survival range of the sensor
     BladeAEdgeMomentOperationalRange = BladeAEdgeMoment(idxEdgeBendingMomentSensorisActive); % extract the operational range of the sensor
    
     BladeBEdgeMoment                 = factor.*sensors(:,idxMy31r);    % extract BladeB Edge Bending Moment
     BladeBEdgeMomentSurvivalRange    = BladeBEdgeMoment; % extract the survival range of the sensor
     BladeBEdgeMomentOperationalRange = BladeBEdgeMoment(idxEdgeBendingMomentSensorisActive); % extract the operational range of the sensor
    
     BladeCEdgeMoment                 = factor.*sensors(:,idxMy21r);    % extract Bladec Edge Bending Moment
     BladeCEdgeMomentSurvivalRange    = BladeCEdgeMoment; % extract the survival range of the sensor
     BladeCEdgeMomentOperationalRange = BladeCEdgeMoment(idxEdgeBendingMomentSensorisActive); % extract the operational range of the sensor
    
    
    % ---------------------------
    % Obtain the Survival Range
    % ---------------------------
    % ---------------------------------------------------------------------
    % compute the maximum of survival range of the sensors 
     MaxBladeAEdgeMomentSurvivalMode     =  [MaxBladeAEdgeMomentSurvivalMode;max(BladeAEdgeMomentSurvivalRange)];
     MaxBladeBEdgeMomentSurvivalMode     =  [MaxBladeBEdgeMomentSurvivalMode;max(BladeBEdgeMomentSurvivalRange)];
     MaxBladeCEdgeMomentSurvivalMode     =  [MaxBladeCEdgeMomentSurvivalMode;max(BladeCEdgeMomentSurvivalRange)];
    
    % compute the maximum Edge moment of all blades in survival mode for...
    % current loadcase
     tmp = [max(BladeAEdgeMomentSurvivalRange),...
                                     max(BladeBEdgeMomentSurvivalRange),...
                                     max(BladeCEdgeMomentSurvivalRange)];
                                 
     MaxEdgeMomentSurvivalMode = [MaxEdgeMomentSurvivalMode;max(tmp)];
                                 
    % determine the blade that is suffered the maximum Edge moment in survival mode                            
     BladeWithMaxEdgeMomentInSurvivalMode = [BladeWithMaxEdgeMomentInSurvivalMode;cellstr(blades(tmp == max(tmp)))];
        
    % compute the minimum of survival range of the sensors 
     MinBladeAEdgeMomentSurvivalMode     =  [MinBladeAEdgeMomentSurvivalMode;min(BladeAEdgeMomentSurvivalRange)];
     MinBladeBEdgeMomentSurvivalMode     =  [MinBladeBEdgeMomentSurvivalMode;min(BladeBEdgeMomentSurvivalRange)];
     MinBladeCEdgeMomentSurvivalMode     =  [MinBladeCEdgeMomentSurvivalMode;min(BladeCEdgeMomentSurvivalRange)];
    
    % compute the minimum Edge moment of all balades in survival mode for
    % each loadcase
     tmp = [min(BladeAEdgeMomentSurvivalRange),...
                                     min(BladeBEdgeMomentSurvivalRange),...
                                     min(BladeCEdgeMomentSurvivalRange)];
                                 
     MinEdgeMomentSurvivalMode = [MinEdgeMomentSurvivalMode;min(tmp)];
                                  
    % determine the blade that is suffered the maximum Edge moment in survival mode                           
     BladeWithMinEdgeMomentInSurvivalMode = [BladeWithMinEdgeMomentInSurvivalMode;cellstr(blades(tmp == min(tmp)))];
    
    % ----------------------------
    % Obtain the Operational Range
    % ----------------------------
    % ---------------------------------------------------------------------
    
     if (~isempty(idxEdgeBendingMomentSensorisActive(idxEdgeBendingMomentSensorisActive ~= 0)))
         
        % compute the maximum of operational range of the sensors 
         MaxBladeAEdgeMomentOperationalMode  =  [MaxBladeAEdgeMomentOperationalMode;max(BladeAEdgeMomentOperationalRange)];
         MaxBladeBEdgeMomentOperationalMode  =  [MaxBladeBEdgeMomentOperationalMode;max(BladeBEdgeMomentOperationalRange)];
         MaxBladeCEdgeMomentOperationalMode  =  [MaxBladeCEdgeMomentOperationalMode;max(BladeCEdgeMomentOperationalRange)];
    
        
        % compute the maximum Edge moment of all blades in operational mode for
        % each loadcase
         tmp = [max(BladeAEdgeMomentOperationalRange),...
                                     max(BladeBEdgeMomentOperationalRange),...
                                     max(BladeCEdgeMomentOperationalRange)];
    
         MaxEdgeMomentOperationalMode = [MaxEdgeMomentOperationalMode;max(tmp)];
    
    
        % determine the blade that is suffered the maximum Edge moment in operational mode at each loadcase                           
         BladeWithMaxEdgeMomentInOperationalMode  = [BladeWithMaxEdgeMomentInOperationalMode;cellstr(blades(tmp == max(tmp)))];
    

        % compute the minimum of operational range of the sensors 
         MinBladeAEdgeMomentOperationalMode  =  [MinBladeAEdgeMomentOperationalMode;min(BladeAEdgeMomentOperationalRange)];
         MinBladeBEdgeMomentOperationalMode  =  [MinBladeBEdgeMomentOperationalMode;min(BladeBEdgeMomentOperationalRange)];
         MinBladeCEdgeMomentOperationalMode  =  [MinBladeCEdgeMomentOperationalMode;min(BladeCEdgeMomentOperationalRange)];
        
        % compute the maximum Edge moment of all balades in operational mode
         tmp = [min(BladeAEdgeMomentOperationalRange),...
                                     min(BladeBEdgeMomentOperationalRange),...
                                     min(BladeCEdgeMomentOperationalRange)];
                                 
        MinEdgeMomentOperationalMode = [MinEdgeMomentOperationalMode;min(tmp)];
                                  
      % determine the blade that is suffered the maximum Edge moment in operational mode                               
       BladeWithMinEdgeMomentInOperationalMode = [BladeWithMinEdgeMomentInOperationalMode;cellstr(blades(tmp == min(tmp)))];
      
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
% In order to compute the Operational range of Edge Bending Moment

 ActiveLoadcasesInOperationalMode = loadcases(index); % Extract the loadcase that Power production is active
 ActiveFWSAvgInOperationalMode    = FreeWindSpeedAvg(index); % Extract the mean of free wind speed for the loadcases that the production is active

%% Sorts the vectors

 pause(5); % Wait 5 Second
%clc  % clear command window

 BladeWithSigMaxEdgeMomentInSurvivalMode    = [];
 BladeWithSigMaxEdgeMomentInOperationalMode = [];
 BladeWithSigMinEdgeMomentInSurvivalMode    = [];
 BladeWithSigMinEdgeMomentInOperationalMode = [];

 SigMaxInSurvivalModeLoadcases              = [];
 SigMinInSurvivalModeLoadcases              = [];
 SigMaxInOperationalModeLoadcases           = [];
 SigMinInOperationalModeLoadcases           = [];

 IndexSigMaxSurvivalMode                    = [];
 IndexSigMaxOperationalMode                 = []; 
 IndexSigMinSurvivalMode                    = []; 
 IndexSigMinOperationalMode                 = []; 

% -------------------------------------------------------------------------
% Compute the highest 'n' value of the Maximum Edge Moment in Survival ...
% Mode.
% -------------------------------------------------------------------------

% Sort the elements of Max vector in descending order
 SortedMaxEdgeMomentSurvivalMode = sort(MaxEdgeMomentSurvivalMode,'descend');

% Take the most significant 'n' values determined by user
 SignificantMaxEdgeMomentSurvivalMode = SortedMaxEdgeMomentSurvivalMode(1:n,1); 

% Extract the unique values
 UniqueSignificantMaxEdgeMomentSurvivalMode = sort(unique(SignificantMaxEdgeMomentSurvivalMode),'descend');

% calculate the number of iterations
 iMaxSurval = length(UniqueSignificantMaxEdgeMomentSurvivalMode);

% Determine the blade and loadcase of the significant maximum vector
 for i=1:iMaxSurval
    clear tmp
    tmp = find(MaxEdgeMomentSurvivalMode == UniqueSignificantMaxEdgeMomentSurvivalMode(i,1)); % Obtain the index of the highest Edge moment
    BladeWithSigMaxEdgeMomentInSurvivalMode = vertcat(BladeWithSigMaxEdgeMomentInSurvivalMode,cell2mat(BladeWithMaxEdgeMomentInSurvivalMode(tmp,1))); % Obtain the blade associated to the highest Edge moment in Survival Mode
    SigMaxInSurvivalModeLoadcases = vertcat(SigMaxInSurvivalModeLoadcases,loadcases(tmp,1)); % Obtain the loadcase that causes the highest Edge moment in Survival mode
    
    IndexSigMaxSurvivalMode = [IndexSigMaxSurvivalMode;tmp]; % obtain the index of the loadcases that cause the highest Edge moments in Survival Mode
 end

% -------------------------------------------------------------------------
% Compute the lowest 'n' value of the Minimum Edge Moment in Survival ...
% Mode.
% -------------------------------------------------------------------------

% Sort the elements of Min vector in ascending order
 SortedMinEdgeMomentSurvivalMode    = sort(MinEdgeMomentSurvivalMode);   

% Take the most significant values determined by user
 SignificantMinEdgeMomentSurvivalMode    = SortedMinEdgeMomentSurvivalMode(1:n,1); 

% Extract the unique minimum moments
 UniqueSignificantMinEdgeMomentSurvivalMode    = unique(SignificantMinEdgeMomentSurvivalMode);

% Calculate the number of iterations
 iMinSurval  = length(UniqueSignificantMinEdgeMomentSurvivalMode);

% Determine the blade and loadcase of the lowest Edge moment value
 for i=1:iMinSurval
     clear tmp
     tmp = find(MinEdgeMomentSurvivalMode == UniqueSignificantMinEdgeMomentSurvivalMode(i,1)); % Obtain the index of the lowest Edge moment
     BladeWithSigMinEdgeMomentInSurvivalMode = vertcat(BladeWithSigMinEdgeMomentInSurvivalMode,cell2mat(BladeWithMinEdgeMomentInSurvivalMode(tmp,1))); % Obtain the blade associated to the lowest Edge moment in Survival Mode
     SigMinInSurvivalModeLoadcases = vertcat(SigMinInSurvivalModeLoadcases,loadcases(tmp,1)); % Obtain the loadcase that causes the lowest Edge moment in Survival mode
    
     IndexSigMinSurvivalMode = [IndexSigMinSurvivalMode;tmp]; % obtain the index of the loadcases that cause the lowest Edge moments in Survival Mode
 end



% -------------------------------------------------------------------------
% Compute the highest 'n' value of the Maximum Edge Moment in Operational
% Mode.
% -------------------------------------------------------------------------

 if (~isempty(MaxEdgeMomentOperationalMode))
     if (n > length(MaxEdgeMomentOperationalMode)) 
        
         fprintf('n is higher than the length of the highest Edge moments computed in Operational Mode\n')
         fprintf('Acordingly n is set to %3d\n',length(MaxEdgeMomentOperationalMode))
         nOpr = length(MaxEdgeMomentOperationalMode); % Change 'n' to the length of the Max of Edge moment vector
     else
         nOpr = n;
     end

        % Sort the elements of Max vector in descending order
         SortedMaxEdgeMomentOperationalMode = sort(MaxEdgeMomentOperationalMode,'descend');

        % Take the most significant 'n' values determined by user
         SignificantMaxEdgeMomentOperationalMode = SortedMaxEdgeMomentOperationalMode(1:nOpr,1);

        % Extract the unique values
         UniqueSignificantMaxEdgeMomentOperationalMode = sort(unique(SignificantMaxEdgeMomentOperationalMode),'descend');

        % Calculate the number of iterations
         iMaxOperational = length(UniqueSignificantMaxEdgeMomentOperationalMode);

        % determine the blades of the most significant values
         for i=1:iMaxOperational 
             clear tmp
             tmp = find(MaxEdgeMomentOperationalMode == UniqueSignificantMaxEdgeMomentOperationalMode(i,1)); % Obtain the index of the highest Edge moment in Operational Mode
             BladeWithSigMaxEdgeMomentInOperationalMode = vertcat(BladeWithSigMaxEdgeMomentInOperationalMode,cell2mat(BladeWithMaxEdgeMomentInOperationalMode(tmp,1))); % Obtain the blade associated to the lowest Edge moment in Operational Mode
             SigMaxInOperationalModeLoadcases = vertcat(SigMaxInOperationalModeLoadcases,loadcases(index(tmp),1)); % Obtain the loadcase that causes the lowest Edge moment in Operational Mode
             IndexSigMaxOperationalMode = [IndexSigMaxOperationalMode;index(tmp)]; % Obtain the index of the loadcases that cause the lowest Edge moments in Operational Mode
         end     
 end

% -------------------------------------------------------------------------
% Compute the lowest 'n' value of the Maximum Edge Moment in Operational
% Mode.
% -------------------------------------------------------------------------

 if (~isempty(MinEdgeMomentOperationalMode))
     if (n > length(MinEdgeMomentOperationalMode)) 
        
         fprintf('n is higher than the length of the highest Edge moments computed in Operational Mode\n')
         fprintf('Acordingly n is set to %3d\n',length(MinEdgeMomentOperationalMode))
         nOpr = length(MinEdgeMomentOperationalMode); % Change 'n' to the length of the Min of Edge moment vector
     else
         nOpr = n;
     end
        
        % Sort the elements of Max vector in descending order
         SortedMinEdgeMomentOperationalMode = sort(MinEdgeMomentOperationalMode);

        % Take the most significant 'n' values determined by user
         SignificantMinEdgeMomentOperationalMode = SortedMinEdgeMomentOperationalMode(1:nOpr,1);

        % Extract the unique values
         UniqueSignificantMinEdgeMomentOperationalMode = sort(unique(SignificantMinEdgeMomentOperationalMode));

        % Calculate the number of iterations
         iMinOperational = length(UniqueSignificantMinEdgeMomentOperationalMode);

        % determine the blades of the most significant values
         for i=1:iMinOperational 
             clear tmp
             tmp = find(MinEdgeMomentOperationalMode == UniqueSignificantMinEdgeMomentOperationalMode(i,1)); % Obtain the index of the highest Edge moment in Operational Mode
             BladeWithSigMinEdgeMomentInOperationalMode = vertcat(BladeWithSigMinEdgeMomentInOperationalMode,cell2mat(BladeWithMinEdgeMomentInOperationalMode(tmp,1))); % Obtain the blade associated to the lowest Edge moment in Operational Mode
             SigMinInOperationalModeLoadcases = vertcat(SigMinInOperationalModeLoadcases,loadcases(index(tmp),1)); % Obtain the loadcase that causes the lowest Edge moment in Operational Mode
             IndexSigMinOperationalMode = [IndexSigMinOperationalMode;index(tmp)]; % Obtain the index of the loadcases that cause the lowest Edge moments in Operational Mode
         end         
 end
    
%% Apply margin to the maximum and minimum in Survival and Operation mode

% -------------------------------------------------------------------------
% Extract the first element of the Max and Min of the Edge moment computed
% in Survival Mode.
% -------------------------------------------------------------------------
 MaxofMaxSurvivalMode = SignificantMaxEdgeMomentSurvivalMode(1,1);
 MinofMinSurvivalMode = SignificantMinEdgeMomentSurvivalMode(1,1);

 % Determine the sign of the Maximum in Survival Morde
 if (MaxofMaxSurvivalMode > 0)
     ProposedMaxEdgeMomentSurvivalMode = MaxofMaxSurvivalMode + 0.01*margin*MaxofMaxSurvivalMode;
 else
     ProposedMaxEdgeMomentSurvivalMode = MaxofMaxSurvivalMode - 0.01*margin*MaxofMaxSurvivalMode;
 end

% Determine the sign of the Minimum in Survival Morde
 if (MinofMinSurvivalMode > 0)
     ProposedMinEdgeMomentSurvivalMode = MinofMinSurvivalMode - 0.01*margin*MinofMinSurvivalMode;
 else
     ProposedMinEdgeMomentSurvivalMode = MinofMinSurvivalMode + 0.01*margin*MinofMinSurvivalMode;
 end

% Transfer the results to the function outputs
 EdgeMomentProposedRangeSurvivalMode = [ProposedMinEdgeMomentSurvivalMode,ProposedMaxEdgeMomentSurvivalMode];

% -------------------------------------------------------------------------
% Extract the first element of the Max and Min of the Edge moment computed
% in Operational Mode.
% -------------------------------------------------------------------------
 if (~isempty(MaxEdgeMomentOperationalMode))
     MaxofMaxOperationalMode = SignificantMaxEdgeMomentOperationalMode(1,1);     
 else
     MaxofMaxOperationalMode  = NaN;   
 end

 if (~isempty(MinEdgeMomentOperationalMode))
     MinofMinOperationalMode = SignificantMinEdgeMomentOperationalMode(1,1);    
 else
     MinofMinOperationalMode = NaN;
 end

% Determine the Max and Min of the sensor range based on margin in
% Operational Mode 

% Determine the sign of the Maximum in Operational Mode
 if (MaxofMaxOperationalMode > 0)
     ProposedMaxEdgeMomentOperationalMode = MaxofMaxOperationalMode + 0.01*margin*MaxofMaxOperationalMode; 
 else 
     ProposedMaxEdgeMomentOperationalMode = MaxofMaxOperationalMode - 0.01*margin*MaxofMaxOperationalMode; 
 end

% Determine the sign of the Minimum in Operational Mode
 if (MinofMinOperationalMode > 0)
     ProposedMinEdgeMomentOperationalMode = MinofMinOperationalMode - 0.01*margin*MinofMinOperationalMode;
 else
     ProposedMinEdgeMomentOperationalMode = MinofMinOperationalMode + 0.01*margin*MinofMinOperationalMode;
 end

% Transfer the results to the function outputs
 EdgeMomentProposedRangeOperationalMode = [ProposedMinEdgeMomentOperationalMode,ProposedMaxEdgeMomentOperationalMode];

%% Archive the data in order to be retrieved for furthur analysis

 % Generate randome mat file
 %r = randi([1 1000]);
 r = datestr(now,30);
 matfilename = strcat('EdgeMomentSensorRange-',r);
 
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


 var11 = 'MaxEdgeMomentSurvivalMode';
 var12 = 'BladeWithMaxEdgeMomentInSurvivalMode';

 var21 = 'MinEdgeMomentSurvivalMode';
 var22 = 'BladeWithMinEdgeMomentInSurvivalMode';

 var31 = 'MaxEdgeMomentOperationalMode';
 var32 = 'BladeWithMaxEdgeMomentInOperationalMode';

 var41 = 'MinEdgeMomentOperationalMode';
 var42 = 'BladeWithMinEdgeMomentInOperationalMode';

 var51 = 'BladeWithSigMaxEdgeMomentInSurvivalMode';
 var52 = 'SigMaxInSurvivalModeLoadcases';
 var53 = 'IndexSigMaxSurvivalMode';
 var54 = 'SignificantMaxEdgeMomentSurvivalMode';

 var61 = 'BladeWithSigMinEdgeMomentInSurvivalMode';
 var62 = 'SigMinInSurvivalModeLoadcases';
 var63 = 'IndexSigMinSurvivalMode';
 var64 = 'SignificantMinEdgeMomentSurvivalMode';

 var71 = 'BladeWithSigMaxEdgeMomentInOperationalMode';
 var72 = 'SigMaxInOperationalModeLoadcases';
 var73 = 'IndexSigMaxOperationalMode';
 var74 = 'SignificantMaxEdgeMomentOperationalMode';

 var81 = 'BladeWithSigMinEdgeMomentInOperationalMode';
 var82 = 'SigMinInOperationalModeLoadcases';
 var83 = 'IndexSigMinOperationalMode';
 var84 = 'SignificantMinEdgeMomentOperationalMode';

 var91 = 'ProposedMinEdgeMomentSurvivalMode';
 var92 = 'ProposedMaxEdgeMomentSurvivalMode';
 
 var96 = 'ProposedMinEdgeMomentOperationalMode';
 var97 = 'ProposedMaxEdgeMomentOperationalMode';
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
        SignificantMaxEdgeMomentSurvivalMode(i,1),120,'filled');
     legentry{i} = strcat(SigMaxInSurvivalModeLoadcases{i,1},',Blade',BladeWithSigMaxEdgeMomentInSurvivalMode(i,1),...
        ', ',num2str(SignificantMaxEdgeMomentSurvivalMode(i,1)),'kNm' );
     hold on
 end

 for i=1:n
     scatter(FreeWindSpeedAvg(IndexSigMinSurvivalMode(i,1)),...
        SignificantMinEdgeMomentSurvivalMode(i,1),120,'filled');
    legentry{n+i} = strcat(SigMinInSurvivalModeLoadcases{i,1},',Blade',BladeWithSigMinEdgeMomentInSurvivalMode(i,1),...
        ', ',num2str(SignificantMinEdgeMomentSurvivalMode(i,1)),'kNm' );
    hold on
 end

 clear tmp tmp2
 tmp = (1:p)'; % creat a vector with dimension of the number of loadcases
 tmp2 = tmp(~ismember(tmp,IndexSigMaxSurvivalMode)); % remove the indecis of the most maximum Edge moment values  
 scatter(FreeWindSpeedAvg(tmp2),MaxEdgeMomentSurvivalMode(tmp2));
 hold on
% plot the rest of points
 clear tmp2
 tmp2 = tmp(~ismember(tmp,IndexSigMinSurvivalMode));  % remove the indecis of the most maximum Edge moment values  
 scatter(FreeWindSpeedAvg(tmp2),MinEdgeMomentSurvivalMode(tmp2))
 hold on
 % plot the margins
 x = 0:0.01:max(FreeWindSpeedAvg)*1.2;
 plot(x,ProposedMinEdgeMomentSurvivalMode*ones(length(x),1),'r--','LineWidth',2)
 hold on
 plot(x,ProposedMaxEdgeMomentSurvivalMode*ones(length(x),1),'r--','LineWidth',2)

% Add text to the graph 
 TextVertFac = 0.97;   % Vertical place of the text
 %xmin = max(x);
 xmin = min(x);
 ymin = ProposedMinEdgeMomentSurvivalMode * TextVertFac;

 %xmax = max(x);
 xmax = min(x);
 ymax = ProposedMaxEdgeMomentSurvivalMode * TextVertFac;

 strmin = ['Minimum - ',num2str(margin),' % ',' = ',num2str(ProposedMinEdgeMomentSurvivalMode),'[kNm]'];
 text(xmin,ymin,strmin,'HorizontalAlignment','left');

 strmax = ['Maximum + ',num2str(margin),' % ',' = ',num2str(ProposedMaxEdgeMomentSurvivalMode),'[kNm]'];
 text(xmax,ymax,strmax,'HorizontalAlignment','left');

 grid on

 lgd = legend(legentry,'Location','west');
 title(lgd,'Highest and Lowest Edge Moments')
 xlabel('Free Wind Speed Average [m/s]')
 ylabel('Edge Bending Moment [kNm]')
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
        SignificantMaxEdgeMomentOperationalMode(i,1),120,'filled');
     legentry{i} = strcat(SigMaxInOperationalModeLoadcases{i,1},',Blade',BladeWithSigMaxEdgeMomentInOperationalMode(i,1),...
        ', ',num2str(SignificantMaxEdgeMomentOperationalMode(i,1)),'kNm' );
     hold on
 end

 for i=1:nOpr
     scatter(FreeWindSpeedAvg(IndexSigMinOperationalMode(i,1)),...
        SignificantMinEdgeMomentOperationalMode(i,1),120,'filled');
    legentry{n+i} = strcat(SigMinInOperationalModeLoadcases{i,1},',Blade',BladeWithSigMinEdgeMomentInOperationalMode(i,1),...
        ', ',num2str(SignificantMinEdgeMomentOperationalMode(i,1)),'kNm' );
    hold on
 end

 clear tmp tmp2
 tmp = (1:length(ActiveFWSAvgInOperationalMode))'; % creat a vector with dimension of the number of loadcases
 tmp2 = tmp(~ismember(index(tmp),IndexSigMaxOperationalMode)); % remove the indecis of the most maximum Edge moment values  
 scatter(ActiveFWSAvgInOperationalMode(tmp2),MaxEdgeMomentOperationalMode(tmp2));
 hold on
% plot the rest of points
 clear tmp2
 tmp2 = tmp(~ismember(index(tmp),IndexSigMinOperationalMode));  % remove the indecis of the most maximum Edge moment values  
 scatter(ActiveFWSAvgInOperationalMode(tmp2),MinEdgeMomentOperationalMode(tmp2))
 hold on
% plot the margins
 x = 0:0.01:max(ActiveFWSAvgInOperationalMode)*1.2; 
 plot(x,ProposedMinEdgeMomentOperationalMode*ones(length(x),1),'r--','LineWidth',2)
 hold on
 plot(x,ProposedMaxEdgeMomentOperationalMode*ones(length(x),1),'r--','LineWidth',2)

% Add text to the graph 
 %xmin = max(x);
 xmin = min(x);
 ymin = ProposedMinEdgeMomentOperationalMode * TextVertFac;

 %xmax = max(x);
 xmax = min(x);
 ymax = ProposedMaxEdgeMomentOperationalMode * TextVertFac;

 strmin = ['Minimum - ',num2str(margin),' % ',' = ',num2str(ProposedMinEdgeMomentOperationalMode),'[kNm]'];
 text(xmin,ymin,strmin,'HorizontalAlignment','left');

 strmax = ['Maximum + ',num2str(margin),' % ',' = ',num2str(ProposedMaxEdgeMomentOperationalMode),'[kNm]'];
 text(xmax,ymax,strmax,'HorizontalAlignment','left');

 grid on

 lgd = legend(legentry,'Location','west');
 title(lgd,'Highest and Lowest Edge Moments')
 xlabel('Free Wind Speed Average [m/s]')
 ylabel('Edge Bending Moment [kNm]')
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
          SignificantMaxEdgeMomentSurvivalMode(i,1),120,'filled');
       legentry{i} = strcat(SigMaxInSurvivalModeLoadcases{i,1},',Blade',BladeWithSigMaxEdgeMomentInSurvivalMode(i,1),...
          ', ',num2str(SignificantMaxEdgeMomentSurvivalMode(i,1)),'kNm' );
       hold on
   end

   for i=1:n
       scatter(FreeWindSpeedAvg(IndexSigMinSurvivalMode(i,1)),...
          SignificantMinEdgeMomentSurvivalMode(i,1),120,'filled');
      legentry{n+i} = strcat(SigMinInSurvivalModeLoadcases{i,1},',Blade',BladeWithSigMinEdgeMomentInSurvivalMode(i,1),...
          ', ',num2str(SignificantMinEdgeMomentSurvivalMode(i,1)),'kNm' );
      hold on
   end

   clear tmp tmp2
   tmp = (1:p)'; % creat a vector with dimension of the number of loadcases
   tmp2 = tmp(~ismember(tmp,IndexSigMaxSurvivalMode)); % remove the indecis of the most maximum Edge moment values  
   scatter(FreeWindSpeedAvg(tmp2),MaxEdgeMomentSurvivalMode(tmp2));
   hold on
% plot the rest of points
   clear tmp2
   tmp2 = tmp(~ismember(tmp,IndexSigMinSurvivalMode));  % remove the indecis of the most maximum Edge moment values  
   scatter(FreeWindSpeedAvg(tmp2),MinEdgeMomentSurvivalMode(tmp2))
   hold on
 % plot the margins
   x = 0:0.01:max(FreeWindSpeedAvg)*1.2;
   plot(x,ProposedMinEdgeMomentSurvivalMode*ones(length(x),1),'r--','LineWidth',2)
   hold on
   plot(x,ProposedMaxEdgeMomentSurvivalMode*ones(length(x),1),'r--','LineWidth',2)

% Add text to the graph 
   %xmin = max(x);
   TextVertFac = 0.97;   % Vertical place of the text 
   xmin = min(x);
   ymin = ProposedMinEdgeMomentSurvivalMode * TextVertFac;

   %xmax = max(x);
   xmax = min(x);
   ymax = ProposedMaxEdgeMomentSurvivalMode * TextVertFac;

   strmin = ['Minimum - ',num2str(margin),' % ',' = ',num2str(ProposedMinEdgeMomentSurvivalMode),'[kNm]'];
   text(xmin,ymin,strmin,'HorizontalAlignment','left');

   strmax = ['Maximum + ',num2str(margin),' % ',' = ',num2str(ProposedMaxEdgeMomentSurvivalMode),'[kNm]'];
   text(xmax,ymax,strmax,'HorizontalAlignment','left');

   grid on

   lgd = legend(legentry,'Location','west');
   title(lgd,'Highest and Lowest Edge Moments')
   xlabel('Free Wind Speed Average [m/s]')
   ylabel('Edge Bending Moment [kNm]')
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
          SignificantMaxEdgeMomentOperationalMode(i,1),120,'filled');
       legentry{i} = strcat(SigMaxInOperationalModeLoadcases{i,1},',Blade',BladeWithSigMaxEdgeMomentInOperationalMode(i,1),...
          ', ',num2str(SignificantMaxEdgeMomentOperationalMode(i,1)),'kNm' );
       hold on
   end

   for i=1:nOpr
       scatter(FreeWindSpeedAvg(IndexSigMinOperationalMode(i,1)),...
          SignificantMinEdgeMomentOperationalMode(i,1),120,'filled');
      legentry{n+i} = strcat(SigMinInOperationalModeLoadcases{i,1},',Blade',BladeWithSigMinEdgeMomentInOperationalMode(i,1),...
          ', ',num2str(SignificantMinEdgeMomentOperationalMode(i,1)),'kNm' );
      hold on
   end

   clear tmp tmp2
   tmp = (1:length(ActiveFWSAvgInOperationalMode))'; % creat a vector with dimension of the number of loadcases
   tmp2 = tmp(~ismember(index(tmp),IndexSigMaxOperationalMode)); % remove the indecis of the most maximum Edge moment values  
   scatter(ActiveFWSAvgInOperationalMode(tmp2),MaxEdgeMomentOperationalMode(tmp2));
   hold on
% plot the rest of points
   clear tmp2
   tmp2 = tmp(~ismember(index(tmp),IndexSigMinOperationalMode));  % remove the indecis of the most maximum Edge moment values  
   scatter(ActiveFWSAvgInOperationalMode(tmp2),MinEdgeMomentOperationalMode(tmp2))
   hold on
% plot the margins
   x = 0:0.01:max(ActiveFWSAvgInOperationalMode)*1.2; 
   plot(x,ProposedMinEdgeMomentOperationalMode*ones(length(x),1),'r--','LineWidth',2)
   hold on
   plot(x,ProposedMaxEdgeMomentOperationalMode*ones(length(x),1),'r--','LineWidth',2)

% Add text to the graph 
   %xmin = max(x);
   xmin = min(x);
   ymin = ProposedMinEdgeMomentOperationalMode * TextVertFac;

   %xmax = max(x);
   xmax = min(x);
   ymax = ProposedMaxEdgeMomentOperationalMode * TextVertFac;

   strmin = ['Minimum - ',num2str(margin),' % ',' = ',num2str(ProposedMinEdgeMomentOperationalMode),'[kNm]'];
   text(xmin,ymin,strmin,'HorizontalAlignment','left');

   strmax = ['Maximum + ',num2str(margin),' % ',' = ',num2str(ProposedMaxEdgeMomentOperationalMode),'[kNm]'];
   text(xmax,ymax,strmax,'HorizontalAlignment','left');

   grid on

   lgd = legend(legentry,'Location','west');
   title(lgd,'Highest and Lowest Edge Moments')
   xlabel('Free Wind Speed Average [m/s]')
   ylabel('Edge Bending Moment [kNm]')
   xlim([0 max(ActiveFWSAvgInOperationalMode)*1.3])
   txt = strcat('Operational Range',',',filename);
   title({'Operational Range',filename})
     
   % Constract the Outputs
   EdgeMomentProposedRangeSurvivalMode = [ProposedMinEdgeMomentSurvivalMode,ProposedMaxEdgeMomentSurvivalMode];
   EdgeMomentProposedRangeOperationalMode = [ProposedMinEdgeMomentOperationalMode,ProposedMaxEdgeMomentOperationalMode];
    
end
%% Display the job was Done!
disp('Done successfully...')

