function turbine = defineTurbineConfigurations
%% Input script defining service configurations for SSS analysis
% Do not alter default format.

% Turbines/variants
turbine(1).name = 'EV162'; % NO WHITESPACE ALLOWED
turbine(1).hub_height = 'HH119'; % NO WHITESPACE ALLOWED
turbine(1).prepfile = 'H:\Vidar\LoadReleases\L10\L10.13\Loads_V162_Master_Model\V162_HTq_6.00_IEC_HH119.0_STD_STE_TA27701\V162_HTq_6.00_IEC_HH119.0_STD_STE_TA27701.txt';
turbine(1).config = {};

turbine(2).name = 'EV162'; % NO WHITESPACE ALLOWED
turbine(2).hub_height = 'HH166'; % NO WHITESPACE ALLOWED
turbine(2).prepfile = 'H:\Vidar\LoadReleases\L10\L10.13\Loads_V162_Master_Model\V162_HTq_6.00_IEC_HH166.0_STD_STE_TA2A600\V162_HTq_6.00_IEC_HH166.0_STD_STE_TA2A600.txt';
turbine(2).config = {};

% Service scenario configurations
% GENERAL
config = struct('case',                 {'RL',          'RLPiMis',      'Idling'},...   % NAME OF CASE (NO WHITESPACE ALLOWED)
                'idleflag',             {false,         false,          true},...       % FLAG ROTOR LOCK (ENABLED/DISABLED)
                'standstillpitch',      {[95 95 95],    [95 95 95],     [95 95 95]},... % PITCH PARKED/IDLING POSITION (SELECT MOST UNFAVOURABLE)
                'wsps',                 {[10:5:25],     [10:5:25],      [15:5:35]},...  % DEFAULT WIND SPEED RESOLUTION (RECOMMENDED)
                'pitch_misalignment',   {[95],          [0 45],         [95]},...       % MANUAL PITCH LOCK POSITIONS WHEN MISALIGNED/IMBALANCED (IF NONE - SET AS PARKED/IDLING POSITIONS)
                'wdir',                 {[0:5:355],     [0:10:350],     [0:10:350]},... % DEFAULT WIND DIRECTION RESOLUTION (RECOMMENDED) - YAWERROR AUTOMATICALLY DERIVED
                'azim',                 {[0:30:90],     [0:30:330],     [0:10:110]},... % ROTOR LOCK/IDLING AZIMUTHAL POSITIONS (LOCKED: TYPICALLY 30 DEG BINS, IDLING: 10 DEG BINS)
                'UYC',                  {false,         false,          false},...      % UPWIND YAW CONTROL E.G. YAW-POWER BACKUP AVAILABLE (REQUIRES SPECIFIC RISK LIMITS)
                'service_type',         {[1],           [2],            [3]},...        % [1-3] SERVICE TYPE TAG - SEE DESCRIPTIONS (TAG LINKING TO RISK REFERENCE CURVES)
                'description',          {'Rotor locked with all blades in parked position.', 'Rotor locked with two blades in parked position, one misaligned.', 'Idling i.e. rotor not locked.'});

% UPWIND YAW CONTROL (UYC)            
% config = struct('case',                 {'RL',                   'RLPiMis',              'Idling'},...   % NAME OF CASE (NO WHITESPACE ALLOWED)
%                 'idleflag',             {false,                  false,                  true},...       % FLAG ROTOR LOCK (ENABLED/DISABLED)
%                 'standstillpitch',      {[95 95 95],             [95 95 95],             [95 95 95]},... % PITCH PARKED/IDLING POSITION (SELECT MOST UNFAVOURABLE)
%                 'wsps',                 {[10:5:25],              [10:5:25],              [15:5:35]},...  % DEFAULT WIND SPEED RESOLUTION (RECOMMENDED)
%                 'pitch_misalignment',   {[95],                   [0 45],                 [95]},...       % MANUAL PITCH LOCK POSITIONS WHEN MISALIGNED/IMBALANCED (IF NONE - SET AS PARKED/IDLING POSITIONS)
%                 'wdir',                 {[345:5:355 0:5:15],     [345:5:355 0:5:15],     [345:5:355 0:5:15]},... % DEFAULT WIND DIRECTION RESOLUTION (RECOMMENDED)
%                 'azim',                 {[0:30:90],              [0:30:330],             [0:10:110]},... % ROTOR LOCK/IDLING AZIMUTHAL POSITIONS (LOCKED: TYPICALLY 30 DEG BINS, IDLING: 10 DEG BINS)
%                 'UYC',                  {true,                   true,                   true},...       % UPWIND YAW CONTROL E.G. YAW-POWER BACKUP AVAILABLE (REQUIRES SPECIFIC RISK LIMITS)
%                 'service_type',         {[1],                    [2],                    [3]},...        % [1-3] SERVICE TYPE TAG - SEE DESCRIPTIONS (TAG LINKING TO RISK REFERENCE CURVES)
%                 'description',          {'Rotor locked with all blades in parked position.', 'Rotor locked with two blades in parked position, one misaligned.', 'Idling i.e. rotor not locked.'});

% Store in turbine struct
turbine(1).config = config;
turbine(2).config = config;