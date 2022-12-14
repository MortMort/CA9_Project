%% Cold Climate Operations

% This script is run within MainDesignCCOTrajectory.m and collects all
% settings that are usually variant independent and therefore, there is no
% need to change. The user finding it useful is welcome to read about the 
% meaning of each setting and to apply any needed change. If clarification 
% is needed, please reach out to FASAL, SIEMA and KAVAS.

% Retreives the branchName from the repository
[~, BranchName] = system(sprintf('sh %s','..\GetBranchInfo.sh'));

%% Meshgrid Design

% Here is specified the pitch and the tsr intervals to be used when 
% designing the CCO pitch map

% Cp range
settings.CpVec       = 0.01:0.01:0.5;
BetzLimit            = 16/27;

% PyRO OUT files shall be generated using the discretization
% -5.00  40.00   0.20    theta_min theta_max theta_step
%  0.80  20.00   0.50    lambda_min lambda_max lambda_step 

% True  : (default) matches the mesh grid always to the settings. Thus
% resizing the shape and the resolution of the meshgrid.
% False : uses the grid specified in the out files
settings.Match2MeshGrid             = true;

% Pitch angle limitations
settings.pitchAngle.min             = -10;  %[deg]
settings.pitchAngle.dPitchAngle     = 0.5; %[deg]
settings.pitchAngle.max             = 40;  %[deg] 

% Tip-Speed ratio limitations
settings.TSR.min                    = 1;    %[-]
settings.TSR.dTSR                   = 0.5;  %[-] 
settings.TSR.max                    = 15.1; %[-]

% False : uses the fixed angle limits defined min/max 
% True  : calculates the envelope of pitch vs TSR giving CpMax
settings.useFixedPitchAngleLimits   = false;



%% Cp Stacking, Pitch Monotonicity and Table Filtering (Backcompatibility only, use is deprecated)

% Enforces Cp stacking, i.e. the Cp must decrease always with the
% increasing of degradation default (FALSE)
settings.enforceCpStacking          = false;  %[-]

% pitch step to be applied when Cp stacking is not fullfilled
settings.deltaPitch                 = 0.1;   %[deg]

% Enforces pitch monotonicity, i.e. the pitch must increase always with the
% increasing of degradation default (TRUE)
settings.enforcePitchMonotonicity   = true;

% Cp table 2D filtering for smoothing settings. Now same as MPC suggested
settings.CpTileSize                 = 0; %[-]

% Size of moving average filter applied to max Cp vs TSR pitch angle. Set
% to zero if filtering is not wished
settings.PitchVsTSRspan             = 0;  %[-]

%% Margin to the max power coefficient (Backcompatibility only, use is deprecated)

% true: selects the Cp Max corresponding to the selected margin to the 
% maximum for each TSR (See findCpMaxVsTSR function). 
% false: selects barely the Cp max vs TSR
settings.UseCpMargin                = false; % [bool]

% true: applies the margin only to the degraded profiles and not to the
% reference, in case it is chosen to use the CpMargin search function
settings.applyMarginToDegradedProfi = false; % [bool]

% Margin to Cp max vs TSR, determines how much should the controller back off from
% CpMax. It is percentage. Meaning that 1.0 = no margin, 0.9 = 10% margin to CpMax
settings.CpMaxMargin                = 1; 

% Margin to Cp max vs TSR, determines how many degrees should the controller
% back off from the CpMax point chosen.
settings.pitchMarginToCpMax         = 0.0; % [deg]

% Should the clamping pitch angle be the one used in the reference CSV
% file? Generally no, because we would otherwise mix the VTS results with
% PyRO results.
settings.clampCpMaxPitch2csvPitch   = false; % [bool]

%% VTS-tuned CCO controller

% True: uses the csv files provided to tune the CCO control table
% In B-Tuning the opti-tip curve of the nominal profile is applied as a
% pitch starting point. For B-tuning select always true.
% False: uses the PyRO inputs to calculate the CpMax for each TSR and
% corresponding pitch, default (true).

% If settings.Btuning.Enable = false the script applies the VTS-tuned
% opti-pitch curve obtained for each pyro file input (VTS simulations for each ice shape needed). 
% The script requires that the number of csv files matches that of the inputs pyro files.
settings.useCSVfiles2tune           = true; % [bool]

%% B-Tuning

% Assuming that the uncertainty in the ice shapes and corresponding
% aerodynamic polars is too high, the beer tuning (from now on B-tuning) is
% an alternative tuning method where the degraded aerodynamic polars are
% not used to generate the lookup table. Instead, we use our experience
% (and a virtual beer in hand :D ) to generate the lookup table.

% Below are listed the B-Tuning parameters that the CCO team believes shall
% be kept constant for the different rotors in scope. Changing these
% parameters increases the degrees of freedom, and with that the tuning
% options.

% If set equal to false, check VTS-tuned CCO controller section.
settings.Btuning.Enable = true; % [bool]

% RatioToNomCpForRegion0Start - Region 0 goes up from nominal Cp times this
% ratio down to nominal Cp times RatioToNomCpForRegion0End.
settings.Btuning.RatioToNomCpForRegion0Start = 1.5; %[-]

% RatioToNomCpForRegion2Start - Region 1 goes from nominal Cp times 
% RatioToNomCpForRegion1Start to nominal Cp times this ratio. Region 2 goes
% from nominal Cp times this ratio to Cp of zero.
settings.Btuning.RatioToNomCpForRegion2Start = 0.5; %[-]

% Slope of pitch vs Cp used in Region 0.
settings.Btuning.dThetadCpRegion0 = 0;

% Slope of pitch vs Cp used in Region 2. There is not enough data
% backing a rotor specific tuning after the CCO 2020 winter verification
% campaign. So the slope is kept constant to 0.
settings.Btuning.dThetadCpRegion2 = 0;

% It has been observed that for high TSRs the stall pitch angle is reduced
% rather than increased. In order to account for that, dThetadCp is
% linearly reduced with increase of TSR in region 3. Region 3 overlaps with
% the other regions, affecting their respective dThetadCp. Start and end
% points are speficied by a ratio to the TSR where Cp is at max (LambdaOpt)
settings.Btuning.RatioToLambdaOptForRegion3End = 1.05; %[-]

%% Table Offsets and Final Filtering

% 2D smoothing of lookupTable - suggested value is 3 or 5. Select 0 to
% disable functionality (3 is an alternative)
settings.PitchVsCpTSRtileSize       = 0;

% Shall any pitch offset be applied to the table?
settings.DeltaPitch                 = 0; 

% Table naming follows Simulink naming
settings.TableTag       = 'DeepStallRecovery-table'; 
settings.TableName      = 'CtrlInput_DegradedProfile.txt'; % Follow Simulink Naming
settings.TableDecimals  = 1; % How many decimal points in the table

settings.TableDeltaTag = 'OptiTipPitchOffset-table'; % Follow Simulink Naming