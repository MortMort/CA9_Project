function [pitAngleVsCpVsTSR, deltaAngleVsCpVsTSR, TSR_vec, Cp_vec] = getPitchVsCpVsTSR(PyroFiles, csvFiles,  settings, fnxt, TurbineofInterest)

nPyroFiles      = length(PyroFiles);

BetzLimit            = 16/27;
c_map                = parula(nPyroFiles);

% If it is desired to apply the Cp  margin then all the ones are found by
% searching for the largest pitch angle corresponding to CpMax
if settings.UseCpMargin
    findDirection = 'last';
else
    findDirection = 'first';
end

%% Step 1.1, (optional) reads the CSV files
if ~isempty(csvFiles) && settings.useCSVfiles2tune
    if ~iscell(csvFiles)
        csvFiles = {csvFiles};
    end
    
    if length(csvFiles) ~= nPyroFiles && settings.Btuning.Enable == false
        error('The number of CSV files must match the number of PyRO out files!');
    elseif settings.Btuning.Enable == true && length(csvFiles) < 1
        error('With B-tuning the CSV of the PrdMix profile is required!');
    end
    
    csv_TableLambdaToPitchOptX = [];
    csv_TableLambdaToPitchOptY = [];
    csv_PartLoadLambdaOpt      = [];
    csv_PartLoadPitOpt         = [];
    % For each csvFile provided
    for iPath = 1:length(csvFiles)
        csvPath = csvFiles{iPath};
        % Reads the optiLambda pitch relation from the supplied CSV file
        [csv_TableLambdaToPitchOptX(iPath,:), csv_TableLambdaToPitchOptY(iPath,:), csv_PartLoadLambdaOpt(iPath,:), ~] = ...
            LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.loadOptiTipPitchTableFromCSV(csvPath);
        
        % Find the angle corresponding to optimal TSR
        csv_PartLoadPitOpt(iPath,:) = interp1(csv_TableLambdaToPitchOptX(iPath,:), csv_TableLambdaToPitchOptY(iPath,:), csv_PartLoadLambdaOpt(iPath,:));
        
        % Finds the rated generator speed and rated power
        if ~exist(csvPath, 'file')                         % check if the file exists
            error('ProdCtrl_ file not found!')              % throw error if it doesn't
        else
            csv_norm_par    = LAC.vts.convert(csvPath);    % load controller parameters if it does
        end
    end
    
    figure(fnxt); fnxt = fnxt+1;
    plot(csv_TableLambdaToPitchOptX', csv_TableLambdaToPitchOptY','.-');
    l = legend(csvFiles);
    hold all;
    plot(csv_PartLoadLambdaOpt, csv_PartLoadPitOpt, 'O', 'DisplayName', 'Optimal pitch angle for reference TSR');
    grid on;
    title({'Opti-Lambda pitch reference (CSV files)', csvFiles{1}}, 'fontsize', 8)
    xlabel('Tip-Speed ratio [-]');
    ylabel('Pitch angle [deg]');
    set(l, 'Interpreter','none')
    xlim([0, settings.TSR.max]);
    xticks([0 : 1: settings.TSR.max])
else
    csv_TableLambdaToPitchOptX          = [];
    csv_TableLambdaToPitchOptY          = [];
    csv_PartLoadLambdaOpt               = [];
    csv_PartLoadPitOpt                  = [];
    if settings.clampCpMaxPitch2csvPitch
        error('The clampCpMaxPitch2csvPitch is true but no CSV file is provided!');
    end
    settings.clampCpMaxPitch2csvPitch   = false;
end

%% Step 1.2 Reads the PyRO OUT files, and finds CpMax and corresponding pitch for each TSR
% Creates a mesh grid to uniform the input data from PyRO
TSRvec = settings.TSR.min : settings.TSR.dTSR : settings.TSR.max;
TSRvec = [settings.TSR.min : settings.TSR.dTSR : settings.TSR.max csv_PartLoadLambdaOpt(1,:)];
TSRvec = sort(TSRvec);
TSRvec = unique(TSRvec);
[tsrQ, pitQ] = ndgrid(TSRvec, ...
    settings.pitchAngle.min : settings.pitchAngle.dPitchAngle : settings.pitchAngle.max);

%Find Cp max for all lambda
%Extract corresponding theta and smooth
lgdTxt          = {};
CpStack         = [];
AEP             = [];
legendTxt       = {};
% For each pyro out file
for fIdx=1:nPyroFiles
    fprintf('[%d/%d] Processing [%s]\n',fIdx, nPyroFiles, PyroFiles{fIdx});
    % Reads the file
    Pyro                        = LAC.pyro.ReadPyroOutFile(PyroFiles{fIdx});
    %AEP(fIdx)                   = PyRO.AEP;
    cpRaw                       = Pyro.Cp_table_2;
    pitAngleRaw                 = Pyro.Col_2_Theta;
    TSRraw                      = Pyro.Row_2_Lambda;
    % Interpolates to the meshgrid
    if settings.Match2MeshGrid % default
        cpInterpolantFnc         = griddedInterpolant({TSRraw,pitAngleRaw}, cpRaw, 'linear');
        cp                       = cpInterpolantFnc(tsrQ, pitQ);
        pitAngle                 = unique(pitQ);
        TSR                      = unique(tsrQ');
    else
        cp                       = cpRaw;
        pitAngle                 = pitAngleRaw;
        TSR                      = TSRraw;
    end
    % number of points
    nTSR                         = length(TSR);
    nPitAngle                    = length(pitAngle);
    if fIdx == 1 % Initialization of matrices
        CpMaxVsTSR_PyRO = zeros(nPyroFiles, nTSR);
        pitchVsTSR_PyRO = zeros(nPyroFiles, nTSR);
        CpCCODisVsTSR_PyRO = zeros(nPyroFiles, nTSR);
        pitchCCODisVsTSR_PyRO = zeros(nPyroFiles, nTSR);
    end
    % FiXME: Removes outliers from Cp table -- FACAP: this function is not
    % yet finished nor tested. It does some issues with V117 latest PyRO
    % file
    % cp                          = smooth2Dtable(cp',pitAngle,TSR,{'Cp','Lambda','Theta'})';
    cpNoFilt                    = cp;
    if settings.CpTileSize > 0  % Filters the Cp table for outliers and smoothens the surface
        cp                      = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.nanmedfilt2(cp, settings.CpTileSize); % FixME: the tileSize will influence the degree of smoothing
        cpInterpolantFnc        = griddedInterpolant({TSR,pitAngle}, cp, 'linear');
        cp                      = cpInterpolantFnc(tsrQ, pitQ);
    end
    % Saves all Cp curves for reference
    CpStack(fIdx,:,:)           = cp; %Stacks all the Cp curves onto a 3D array
    
    if settings.UseCpMargin || (fIdx>1 && settings.applyMarginToDegradedProfi)
        findDirection = 'last';
        [CpMaxVsTSR_PyRO(fIdx,:), idx]   = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.findCpMaxVsTSR(cp, settings.CpMaxMargin, findDirection);
        pitchVsTSR_PyRO(fIdx,:)          = pitAngle(idx);
        fprintf('[%d/%d] CpMax(TSR) found with findCpMaxVsTSR, direction[%s]\n',fIdx, nPyroFiles, findDirection);        
    else
        % Finds the max Cp for each TSR and corresponding pitch angle
        [CpMaxVsTSR_PyRO(fIdx,:), idx]   = max(cp,[],2);
        pitchVsTSR_PyRO(fIdx,:)          = pitAngle(idx);
        fprintf('[%d/%d] CpMax(TSR) found with MAX(Cp)\n',fIdx, nPyroFiles);
    end
    
    % Finds the CCO disabled Cp based on design opti-tip pitch angle
    if settings.useCSVfiles2tune
        pitchCCODisVsTSR_temp = interp1(csv_TableLambdaToPitchOptX(1,:), csv_TableLambdaToPitchOptY(1,:),TSR,'linear','extrap');
        pitchCCODisVsTSR_PyRO(fIdx,:) = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.OptiPitchAtNominalOperations(pitchCCODisVsTSR_temp, pitAngle);
        CpCCODisVsTSR_PyRO(fIdx,:) = cpInterpolantFnc(TSR', pitchCCODisVsTSR_PyRO(1,:));
    else
        pitchCCODisVsTSR_PyRO(fIdx,:) = pitchVsTSR_PyRO(1,:);
        CpCCODisVsTSR_PyRO(fIdx,:) = cpInterpolantFnc(TSR', pitchCCODisVsTSR_PyRO(1,:)); 
    end
    
    % Saves the maximum found
    pitchVsTSR_noMarg(fIdx,:)   =  pitchVsTSR_PyRO(fIdx,:);
    CpMaxVsTSR_noMarg(fIdx,:)   =  CpMaxVsTSR_PyRO(fIdx,:);
    % Applies a fixed pitch margin to the maximum found and re-establish
    % the Cp at the new pitch angle
    pitchVsTSR_PyRO(fIdx,:)          = pitchVsTSR_PyRO(fIdx,:) + settings.pitchMarginToCpMax;
    CpMaxVsTSR_PyRO(fIdx,:)          = cpInterpolantFnc(TSR', pitchVsTSR_PyRO(fIdx,:));
    
    % Finds the pitch angle
    if settings.PitchVsTSRspan > 0 % smoothing shall influence the degree of pitch activity given variation of tsr
        pitchVsTSR_PyRO(fIdx,:)      = smooth(pitchVsTSR_PyRO(fIdx,:), settings.PitchVsTSRspan);
    end
    % Sets the legend as the PyRO files for reference
    [~,lgdTxt{fIdx},~]       = fileparts(PyroFiles{fIdx});
    
    % plots each Cp Curve
    figure(fnxt); fnxt = fnxt+1;
    if sqrt((cp-cpNoFilt).^2) > 0
        subplot(1,2,1);
        mesh(pitAngle, TSR, cp);
        xlabel('Pitch angle [deg]'); ylabel('\lambda [-]'); zlabel('Cp [-]');
        zlim([0 BetzLimit]); caxis([0,BetzLimit]);
        title({'CP-table calculated at w=7.50 m/s', lgdTxt{fIdx}}, 'fontsize',8,'Interpreter','none');
        subplot(1,2,2);
        contourf(pitAngle, TSR, sqrt((cp-cpNoFilt).^2), 30);
        xlabel('Pitch angle [deg]'); ylabel('\lambda [-]'); zlabel('Cp [-]');
    else
        mesh(pitAngle, TSR, cp);
        xlabel('Pitch angle [deg]'); ylabel('\lambda [-]'); zlabel('Cp [-]');
        zlim([0 BetzLimit]); caxis([0,BetzLimit]);
        title({'CP-table calculated at w=7.50 m/s', lgdTxt{fIdx}}, 'fontsize',8,'Interpreter','none');
    end
end

% % By assumption - the first element in the PyRO file list is the reference
% % profile
% CpMaxVsTSR_Reference    = CpMaxVsTSR(1,:);
% pitchVsTSR_Reference    = pitchVsTSR(1,:);
% if settings.clampCpMaxPitch2csvPitch
%     pitchVSTSR_RefFromCSV   = interp1(csv_TableLambdaToPitchOptX, csv_TableLambdaToPitchOptY, TSR, 'linear', 'extrap');
% end


%% Step 1.3 (optional) Determination of CpMax and corresponding pitch for each TSR based on B-tuning settings

if settings.Btuning.Enable
    if settings.enforcePitchMonotonicity == true
        warning('Enforce pitch monotonicity is enabled, but it is not compatible with B-tuning! It is being disabled now.');
        settings.enforcePitchMonotonicity = false;
    end
    
    % Initializing the tables
    CpMaxVsTSR_Btuning = zeros(4,size(cp,1));
    pitchVsTSR_Btuning = zeros(4,size(cp,1));
    
    % Use Opti-tip curve to tune pitch starting point?
    if settings.useCSVfiles2tune 
        pitchVsTSR_Btuning_temp = interp1(csv_TableLambdaToPitchOptX(1,:), csv_TableLambdaToPitchOptY(1,:),TSR,'linear','extrap');
        pitchVsTSR_Btuning(2,:) = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.OptiPitchAtNominalOperations(pitchVsTSR_Btuning_temp, pitAngle);
    else
        pitchVsTSR_Btuning(2,:) = pitchVsTSR_PyRO(1,:);
    end
    
    % Use hardcoded table to tune Cp Max vs TSR?
    if settings.Btuning.CpMaxFromHardcoded
        P = path();
        P = strsplit(P,';');
        PEmpty = strfind(P,'\tsw\application\phTurbineCommon\Simulink\Include');
        for ii = 1:length(P)+1
            if ii <=length(P) && ~isempty(PEmpty{ii})
                run(strcat(P{ii},'\constant.m'));
                break
            elseif ii == length(P)+1
                pause(1);
                disp('If you have tsw repo checked in, call the psetup shortcut and retry.')
                disp('If you continue, the function will look for constant.m in this local path.')
                disp('If the file is not found, the function will exit and suggest where to download it.')
                Answer = input('Do you want to continue? [y/n]','s');                
                
                if Answer == 'y'
                    try 
                        run('constant.m')
                    catch ME
                        warning('constant.m is not found in the current location. Please download it from http://code.tsw.vestas.net/projects/TS/repos/tsw/browse/application/phTurbineCommon/Simulink/Include/constant.m and paste it to the current location.')
                        pitAngleVsCpVsTSR = 0;
                        deltaAngleVsCpVsTSR = 0;
                        TSR_vec = 0;
                        Cp_vec = 0;
                        return;
                    end
                elseif Answer == 'n'
                    pitAngleVsCpVsTSR = 0;
                    deltaAngleVsCpVsTSR = 0;
                    TSR_vec = 0;
                    Cp_vec = 0;
                    return;
                end
            end
                
        end
        CpTable = eval(strcat('cCpTabCpData',TurbineofInterest));
        TSRTable = eval(strcat('cCpTabLambdaBins',TurbineofInterest));
        CpMaxVsTSR_Btuning(2,:) = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.CpMaxAtNominalOperations(CpTable, TSRTable, TSR)*settings.Btuning.RatioToNomCpForRegion0End;
    else
        CpMaxVsTSR_Btuning(2,:) = CpMaxVsTSR_PyRO(1,:)*settings.Btuning.RatioToNomCpForRegion0End;
    end
    
    % Finding the LambdaOpt
    RoundedCpMaxVsTSR = round(CpMaxVsTSR_PyRO(1,:),3);
    idx = RoundedCpMaxVsTSR==max(RoundedCpMaxVsTSR);
    LambdaOpt = csv_PartLoadLambdaOpt(1,:);
    
    % Creating the dThetadCp ratio vector, which is used for the reduction
    % of dThetadCp with increase of TSR in region 3. The ratio is
    % linearly interpolated from 1 at the start of region 3, and
    % 'dThetadCpRatioAtRegion3End' at the end of region 3. Outside region
    % 3, the ratio is kept constant.
    LambdaAtRegion3Bounds = [LambdaOpt*settings.Btuning.RatioToLambdaOptForRegion3Start ...
        LambdaOpt*settings.Btuning.RatioToLambdaOptForRegion3End];
    dThetadCpRatioAtRegion3Bounds = [1 settings.Btuning.dThetadCpRatioAtRegion3End];
    dThetadCpRatioVsTSR = interp1(LambdaAtRegion3Bounds,dThetadCpRatioAtRegion3Bounds,TSR','linear','extrap');
    dThetadCpRatioVsTSR = min(dThetadCpRatioVsTSR,1);
    dThetadCpRatioVsTSR = max(dThetadCpRatioVsTSR,settings.Btuning.dThetadCpRatioAtRegion3End);
    
    % At the start of region 0, it is calculated as a delta from the
    % nominal, using the dThetadCp specified in settings for region 0.
    CpMaxVsTSR_Btuning(1,:) = CpMaxVsTSR_Btuning(2,:)*settings.Btuning.RatioToNomCpForRegion0Start/settings.Btuning.RatioToNomCpForRegion0End;
    dThetadCpRegion0VsTSR = settings.Btuning.dThetadCpRegion0*dThetadCpRatioVsTSR;
    pitchVsTSR_Btuning(1,:) = pitchVsTSR_Btuning(2,:) + (CpMaxVsTSR_Btuning(1,:)-CpMaxVsTSR_Btuning(2,:)*settings.Btuning.RatioToNomCpForRegion0End).*dThetadCpRegion0VsTSR;
    
    % At the transition between regions 1 and 2, it is calculated as a
    % delta from the nominal, using the dThetadCp specified in settings for
    % region 1.
    CpMaxVsTSR_Btuning(3,:) = CpMaxVsTSR_Btuning(2,:)*settings.Btuning.RatioToNomCpForRegion2Start/settings.Btuning.RatioToNomCpForRegion0End;
    dThetadCpRegion1VsTSR = settings.Btuning.dThetadCpRegion1*dThetadCpRatioVsTSR;
    pitchVsTSR_Btuning(3,:) = pitchVsTSR_Btuning(2,:) - (CpMaxVsTSR_Btuning(2,:)-CpMaxVsTSR_Btuning(3,:)).*dThetadCpRegion1VsTSR;
    
    % At Cp = 0, it is calculated as a delta from the pitch at the
    % transition between regions 1 and 2, using the dThetadCp specified in
    % settings for region 2.
    dThetadCpRegion2VsTSR = settings.Btuning.dThetadCpRegion2*dThetadCpRatioVsTSR;
    pitchVsTSR_Btuning(4,:) = pitchVsTSR_Btuning(3,:) - (CpMaxVsTSR_Btuning(3,:)-CpMaxVsTSR_Btuning(4,:)).*dThetadCpRegion2VsTSR;
end

%% Step 2 (optional) Interpolates pitch on the TSR grid
% If we want to use the CSV files for tuning, we now use the fine TSR grid to interpolate on all the points for each lookuptable in OTC

if settings.useCSVfiles2tune == true && settings.Btuning.Enable == false
    % For each csvFile provided, the pitch and Cp vs TSR are populated, using
    % PyRO Cp files
    figure(fnxt); fnxt = fnxt+1; clf();     hold all;
    pitchVsTSR_csv = zeros(length(csvFiles), nTSR);
    CpMaxVsTSR_csv = zeros(length(csvFiles), nTSR);
    for iPath = 1:length(csvFiles)
        % Interpolates the CSV curve on the TSR range - FixME: evaluate if to
        % apply extrapolations. Note potential issue for high TSRs
        pitchVsTSR_csv(iPath, :) = interp1(csv_TableLambdaToPitchOptX(iPath,:), csv_TableLambdaToPitchOptY(iPath,:), TSR, 'linear');
        % For any TSR outside the range min/max of the CSV file we keep the
        % nearest value ( as in the controller behaviour)
        pitchVsTSR_csv(iPath, :) = fillmissing(pitchVsTSR_csv(iPath,:), 'previous', 'EndValues', 'nearest');
        cpInterpolantFnc         = griddedInterpolant({TSR,pitAngle}, squeeze(CpStack(iPath, :, :)), 'linear');
        CpMaxVsTSR_csv(iPath, :) = cpInterpolantFnc(TSR', pitchVsTSR_csv(iPath,:));
        
        subplot(2,1,1); hold all; grid on;
        plot(TSR', CpMaxVsTSR_csv(iPath, :)','.-', 'color', c_map(iPath,:),'displayName',[lgdTxt{iPath},'_CSV']);
        plot(TSR', CpMaxVsTSR_PyRO(iPath, :)','O-', 'color', c_map(iPath,:),'displayName',[lgdTxt{iPath},'_PyRO']);
        ylabel('Cp [-]');
        
        subplot(2,1,2); hold all; grid on;
        plot(TSR', pitchVsTSR_csv(iPath, :)','.-', 'color', c_map(iPath,:),'displayName',[lgdTxt{iPath},'_CSV']);
        plot(TSR', pitchVsTSR_PyRO(iPath, :)','O-', 'color', c_map(iPath,:),'displayName',[lgdTxt{iPath},'_PyRO']);
        ylabel('Pitch angle [deg]');
        
    end
    l = legend('Interpreter','none');
    title({'Opti-Lambda pitch reference (CSV files)', csvFiles{1}}, 'fontsize', 8)
    set(l, 'visible', 'on')
    xlabel('Tip-Speed ratio [-]');
    set(l, 'Interpreter','none')
    xlim([0, settings.TSR.max]);
    xticks([0 : 1: settings.TSR.max])
    grid on;
end

%% Step 3. Selects CpMax and pitch based on user selection

if settings.Btuning.Enable
    % CpMax & pitch vs TSR from B-tuning
    CpMaxVsTSR          = CpMaxVsTSR_Btuning;
    pitchVsTSR          = pitchVsTSR_Btuning;
elseif settings.useCSVfiles2tune == true && settings.Btuning.Enable == false
    % CpMax & pitch vs TSR from tuned CSV files
    CpMaxVsTSR          = CpMaxVsTSR_csv;
    pitchVsTSR          = pitchVsTSR_csv;
else
    % CpMax & pitch vs TSR found from PyRO
    CpMaxVsTSR          = CpMaxVsTSR_PyRO;
    pitchVsTSR          = pitchVsTSR_PyRO;
end

%% Step 4. Cp stacking violation handling
% Hypothesis: the list of files is in ascending order of degradation, hence
% as we progress through the files we are to observe a degradation in Cp

% Saves the variables prior handling
CpMaxVsTSR_raw          = CpMaxVsTSR;
pitchVsTSR_raw          = pitchVsTSR;

% For each TSR
for tsrIdx = 1:nTSR
    cpVSfile = squeeze(CpStack(:,tsrIdx,:));  
    
    pitAngleMinVsTSR(tsrIdx) = interp1(TSR, min(pitchVsTSR_raw), TSR(tsrIdx), 'linear');
    pitAngleMaxVsTSR(tsrIdx) = interp1(TSR, max(pitchVsTSR_raw), TSR(tsrIdx), 'linear');
    
    % interpolate for all CP values in CpVec - no extrapolation allowed
    pitAngleVsCpNoSat(:,tsrIdx) = interp1(CpMaxVsTSR_raw(:,tsrIdx), pitchVsTSR_raw(:,tsrIdx), settings.CpVec, 'linear', 'extrap' );
    % Limits the pitch angle to the chosen boundaries
    pitAngleVsCpVsTSR(:,tsrIdx) = max(pitAngleMinVsTSR(tsrIdx), min(pitAngleMaxVsTSR(tsrIdx), pitAngleVsCpNoSat(:,tsrIdx)));
    
    % interpolate Cp of each ice shape with pitch from B-tuning
    for nn = 1:size(cpVSfile,1)
        CpVSfileBTuningPitch = interp1(pitAngle,cpVSfile(nn,:),pitAngleVsCpVsTSR(:,tsrIdx),'linear');
        [~,IdxIntersect(nn)] = min(abs(CpVSfileBTuningPitch - settings.CpVec'));
        CpToPlotBTuningPitch(nn,tsrIdx) = CpVSfileBTuningPitch(IdxIntersect(nn));
    end
    
    % For each file
    for fIdx = 2:size(CpMaxVsTSR,1)
        % if Cp is higher for the succeeding file or the pitch is lower
        % than the preceding one then
        if CpMaxVsTSR(fIdx,tsrIdx) >= CpMaxVsTSR(fIdx-1, tsrIdx) || pitchVsTSR(fIdx, tsrIdx) < pitchVsTSR(fIdx-1, tsrIdx)
            if settings.enforcePitchMonotonicity % enforces the pitch to be higher from one file to the next
                cpVSfileAtTSR  = squeeze(CpStack(fIdx, tsrIdx, :));
                % enforces the monotonicity of the pitch from one file to
                % another
                pitRef         = pitchVsTSR(fIdx-1, tsrIdx);
                cpVal          = interp1(pitAngle, cpVSfileAtTSR, pitRef);
                if isnan(cpVal) % If the pitch reference is out of bounds (outside the table) then the interp1 returns NaN
                    cpVal      = CpMaxVsTSR(fIdx-1, tsrIdx)-0.001; % FixME, perhaps can be beautified
                    warning('Out of bound pitch angle! Value substitute with preceding value.');
                end
                if settings.enforceCpStacking % enforces the Cp to be lower from one file to the next
                    while cpVal > CpMaxVsTSR(fIdx-1,tsrIdx) && pitRef < max(pitAngle) - settings.deltaPitch
                        pitRef         = pitRef + settings.deltaPitch;
                        cpVal          = interp1(pitAngle, cpVSfileAtTSR, pitRef, 'linear');
                        if isnan(cpVal) % If the pitch reference is out of bounds (outside the table) then the interp1 returns NaN
                            cpVal      = CpMaxVsTSR(fIdx-1, tsrIdx)-0.001; % FixME, perhaps can be beautified
                            warning('Out of bound pitch angle! Value substitute with preceding value.');
                        end
                    end
                else
                    warning('Cp stacking is violated and not enforced.');
                end
                CpMaxVsTSR(fIdx, tsrIdx) = cpVal;
                pitchVsTSR(fIdx, tsrIdx) = pitRef;
            end
        end
    end
    
    % plots every fifth TSR from the vector, the 1st element of TSR is ofen
    % problematic
%     if mod(tsrIdx,5)==0 || TSR(tsrIdx) == 11 || TSR(tsrIdx) == 1 || TSR(tsrIdx) == 6 || TSR(tsrIdx) == 7 || TSR(tsrIdx) == 10
    if mod(TSR(tsrIdx),1) == 0 && TSR(tsrIdx) >= 3 && TSR(tsrIdx) <= 13 || mod(TSR(tsrIdx),csv_PartLoadLambdaOpt(1,:)) == 0
        h=figure(fnxt); fnxt = fnxt+1;
        plot(pitAngle, cpVSfile, '.-'); hold all;
        plot(pitchCCODisVsTSR_PyRO(:,tsrIdx),CpCCODisVsTSR_PyRO(:,tsrIdx),'mO-','linewidth',2)
        plot(pitchVsTSR(:, tsrIdx), CpMaxVsTSR(:, tsrIdx), 'bO-', 'linewidth',2)
        plot(pitAngleVsCpVsTSR(IdxIntersect, tsrIdx), CpToPlotBTuningPitch(:,tsrIdx), '^', 'linewidth',2)
        plot(pitchVsTSR_noMarg(:, tsrIdx), CpMaxVsTSR_noMarg(:, tsrIdx), '^','linewidth',2)
%         plot(pitchVsTSR_raw(:, tsrIdx), CpMaxVsTSR_raw(:, tsrIdx), 'v-')
        if settings.Btuning.Enable && settings.Btuning.CpMaxFromHardcoded
            plot(pitAngle, settings.Btuning.RatioToNomCpForRegion0End*ones(length(pitAngle),1)*CpMaxVsTSR_Btuning(2, tsrIdx)/settings.Btuning.RatioToNomCpForRegion0End,'k--','linewidth',2)
        else
            plot(pitAngle, settings.Btuning.RatioToNomCpForRegion0End*ones(length(pitAngle),1)*CpMaxVsTSR_PyRO(1, tsrIdx),'k--','linewidth',2)
        end
        xlabel('Pitch angle [deg]'); ylabel('Cp [-]');
        l = legend({lgdTxt{:},'Cp CCO Disabled', 'CCO degraded opti-pitch', 'Cp CCO Enabled', 'Max achievable Cp','GID Activation Threshold'});
        set(l, 'Interpreter', 'none');
        if  ~isempty(csv_PartLoadLambdaOpt) && csv_PartLoadLambdaOpt(1,:) == TSR(tsrIdx)
            title(sprintf('Cp : TSR* = %2.2f', TSR(tsrIdx)));
        else
            title(sprintf('Cp : TSR = %2.2f', TSR(tsrIdx)));
            legend off
        end
        grid on;
        xlim([min(pitchVsTSR_noMarg(:, tsrIdx))-2, max(pitchVsTSR_noMarg(:, tsrIdx))+2])
        if settings.SavePitchTrajectory
            if exist(TurbineofInterest, 'dir')~=7
                mkdir(TurbineofInterest)
            end
            saveas(h,strcat(TurbineofInterest,'\',sprintf('TSR = %2.2f.png', TSR(tsrIdx))),'png')
        end
    end
        
end

% Plot Designed Opti-tip curves for each of the ice shapes
figure(fnxt);fnxt = fnxt + 1;
hold on
plot(TSR,pitAngleVsCpVsTSR(IdxIntersect,:),'.-')
title('CCO Opti-tip curve for each ice shape')
l = legend({lgdTxt{:}});
set(l, 'Interpreter', 'none'); 
hold off

%% Step 5. Visualization of individual optiLambdlegena vs pitch

% figure(fnxt); fnxt = fnxt+1;
% for idx = 1:size(CpMaxVsTSR,1)
%     h(1) = subplot(2,1,1);grid on;
%     plot(TSR(CpMaxVsTSR(idx,:)>0), CpMaxVsTSR(idx,CpMaxVsTSR(idx,:)>0), 'O-', 'color', c_map(idx,:),'displayName',lgdTxt{idx}); hold all;
%     plot(TSR(CpMaxVsTSR_raw(idx,:)>0), CpMaxVsTSR_raw(idx,CpMaxVsTSR_raw(idx,:)>0), '.--', 'color', c_map(idx,:),'displayName',[lgdTxt{idx},'_Raw']);
%     ylabel('Cp [-]');
%     xlabel('Tip-Speed ratio [-]');
%     h(2) = subplot(2,1,2);grid on;
%     plot(TSR, pitchVsTSR(idx,:), 'O-', 'color', c_map(idx,:),'displayName',lgdTxt{idx}); hold all;
%     plot(TSR, pitchVsTSR_raw(idx,:), '.--', 'color', c_map(idx,:),'displayName',[lgdTxt{idx},'_Raw']);
%     ylabel('Pitch [deg]');
%     xlabel('Tip-Speed ratio [-]');
% end
% 
% title({'CpMax vs TSR given pitch'}, 'fontsize', 8)
% xlim([0, settings.TSR.max]);
% linkaxes(h,'x');
% l = legend('Interpreter','none');
% set(l, 'Interpreter', 'none');

% %% Step 6. Find the min/max pitch envelope vs TSR
% 
% pitAngleMaxVsTSR   = ones(1, length(TSR))*settings.pitchAngle.max;
% pitAngleMinVsTSR   = ones(1, length(TSR))*settings.pitchAngle.min;
% 
% if ~settings.useFixedPitchAngleLimits
%     for l=1:length(TSR)
%         pitAngleMinVsTSR(l) = interp1(TSR, min(pitchVsTSR), TSR(l), 'linear');
%         pitAngleMaxVsTSR(l) = interp1(TSR, max(pitchVsTSR), TSR(l), 'linear');
%     end
% end
% 
% if settings.clampCpMaxPitch2csvPitch
%     for l=1:length(TSR)
%         % The first line in the table is the referece by assumption
%         csvPitOpt                 = interp1(csv_TableLambdaToPitchOptX(1,:), csv_TableLambdaToPitchOptY(1,:), TSR(l), 'linear');
%         pitAngleMinVsTSR(l)       = max(pitAngleMinVsTSR(l), csvPitOpt);
%         pitAngleMaxVsTSR(l)       = max(pitAngleMaxVsTSR(l), pitAngleMinVsTSR(l));
%     end
% end
% %Visualize envelope
% figure(fnxt); fnxt = fnxt+1;
% if settings.Btuning.Enable == false
%     plot(TSR, pitchVsTSR', '--');
%     hold all; grid on;
%     plot(TSR, pitAngleMinVsTSR, '-', 'linewidth', 2);
%     plot(TSR, pitAngleMaxVsTSR, '-', 'linewidth', 2);
%     xlabel('Tip-Speed ratio [-]');
%     ylabel('Pitch Angle [deg]');
%     legend({lgdTxt{:}, 'MIN', 'MAX'});
% else
%     hold all; grid on;
%     plot(TSR, pitAngleMinVsTSR, '-', 'linewidth', 2);
%     plot(TSR, pitAngleMaxVsTSR, '-', 'linewidth', 2);
%     xlabel('Tip-Speed ratio [-]');
%     ylabel('Pitch Angle [deg]');
%     legend({'MIN Opti-pitch curve', 'MAX Opti-pitch curve'});
% end


%% Step 7. Builds look-up table

TSR_vec              = TSR;
Cp_vec               = settings.CpVec;

for l=1:length(TSR)
    cpVSfile = squeeze(CpStack(:,l,:));
    % interpolate for all CP values in CpVec - no extrapolation allowed
    pitAngleVsCpNoSat(:,l)          = interp1(CpMaxVsTSR(:,l), pitchVsTSR(:,l), settings.CpVec, 'linear', 'extrap' );
    % Limits the pitch angle to the chosen boundaries
    pitAngleVsCpVsTSR(:,l)          = max(pitAngleMinVsTSR(l), min(pitAngleMaxVsTSR(l), pitAngleVsCpNoSat(:,l)));
end

% Rounds the calculated pitch angles to 1 decimal
pitAngleVsCpVsTSR    = round(pitAngleVsCpVsTSR, settings.TableDecimals);

% if wished the lookup table can be further smoothed - perhaps to reduce
% pitch actuation
if settings.PitchVsCpTSRtileSize > 0
    fprintf('Look-up table smoothen with 2D kernel function of size %d\n', settings.PitchVsCpTSRtileSize);
    pitAngleVsCpVsTSR = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.nanmedfilt2(pitAngleVsCpVsTSR, settings.PitchVsCpTSRtileSize);
end

% Visualize the lookup table as contour plot
figure(fnxt); fnxt = fnxt+1;
v = [settings.pitchAngle.min:2:settings.pitchAngle.max];
[C,h] = contourf(TSR_vec, settings.CpVec, pitAngleVsCpVsTSR, v);
clabel(C,h,v)
hold on;
CpMaxVsTSR_Temp = CpMaxVsTSR;
CpMaxVsTSR_Temp(CpMaxVsTSR_Temp<0) = 0;
plot(TSR,CpMaxVsTSR_Temp','linewidth',2)
ylim([0, settings.CpVec(end)]);
xlabel('Tip Speed ratio [-]');
ylabel('Power coefficient, Cp [-]');
title(sprintf('Pitch angle reference \n %s', TurbineofInterest));
if settings.Btuning.Enable
    l = legend({'Pitch angle Ref [deg]', 'Region 0 Start', 'Region 1 Start', 'Region 2 Start'});
else
    l = legend({'Pitch angle Ref [deg]' lgdTxt{:}});
end
set(l, 'Interpreter', 'none');
%% Step 8. Builds the table as gradient from a reference Cp

% settings.CpMaxRef   = max(max(CpMaxVsTSR));
% % finds the reference Cp max column as the closest to the wished
% cpRefId             = find( settings.CpVec >= max(max(CpMaxVsTSR)), 1, 'first');
% % finds the reference row of pitch angles
% refPit              = pitAngleVsCpVsTSR(cpRefId, :);
% deltaAngleVsCpVsTSR = pitAngleVsCpVsTSR - repmat(refPit,size(pitAngleVsCpVsTSR,1),1);

deltaAngleVsCpVsTSR = zeros(length(settings.CpVec), nTSR);

if settings.Btuning.Enable
    refProfileIdx = 2;
else
    refProfileIdx = 1;
end

for iTSR = 1:nTSR
    % Computes the difference for each TSR compared to the pitch angle at
    % for the reference profile at the chosen TSR
    deltaAngleVsCpVsTSR(:, iTSR) = pitAngleVsCpVsTSR(:, iTSR) - pitchVsTSR(refProfileIdx, iTSR);
end

% Visualize the lookup table as contour plot
figure(fnxt); fnxt = fnxt+1;
v = linspace(min(min(deltaAngleVsCpVsTSR)), max(max(deltaAngleVsCpVsTSR)), 10);
v = round(v,1);
[C,h] = contourf(TSR_vec, settings.CpVec, round(deltaAngleVsCpVsTSR,2), v);
clabel(C,h,v)
hold on;
CpMaxVsTSR_Temp = CpMaxVsTSR;
CpMaxVsTSR_Temp(CpMaxVsTSR_Temp<0) = 0;
plot(TSR,CpMaxVsTSR_Temp','linewidth',2)
ylim([0, settings.CpVec(end)]);
xlabel('Tip Speed ratio [-]');
ylabel('Power coefficient, Cp [-]');
title(sprintf('Pitch angle delta vs reference \n %s', TurbineofInterest));
if settings.Btuning.Enable
    l = legend({'Pitch angle offset [deg]', 'Region 0 Start', 'Region 1 Start', 'Region 2 Start'});
else
    l = legend({'Pitch angle offset [deg]' lgdTxt{:}});
end
set(l, 'Interpreter', 'none');

%% Step 9. Compute Cp Gain in % due to CCO enabled: 10 % uncertainty expected from B-tuning gain in heavy ice conditions

idx = 1;

for iTSR = 1:nTSR
    % Ice classification
    if mod(TSR(iTSR),1) == 0 && TSR(iTSR) >= 3 && TSR(iTSR) <= 13
        CpPercent = CpMaxVsTSR_PyRO(:,iTSR)./CpMaxVsTSR_PyRO(1,iTSR);
        CpGainPercent = CpToPlotBTuningPitch(:,iTSR)./CpMaxVsTSR_PyRO(:,iTSR)*100;
        TSRReduced(idx) = TSR(iTSR);
        CpGainPercentLight(idx) = 100 - mean(CpGainPercent(CpPercent >= 0.75));
        CpGainPercentMedium(idx) = 100 - mean(CpGainPercent(CpPercent >= 0.5 & CpPercent < 0.75));
        CpGainPercentHeavy(idx) = 100 - 0.9*mean(CpGainPercent(CpPercent < 0.5));
        idx = idx + 1;
    end
end

[~,IdxLbdOpt] = min(abs(TSRReduced-LambdaOpt));

% Compute year averaged Cp Percent Gain
[YearPercentCpGainLight] = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.ComputeYearPercentCpGain(settings.k, settings.Vavg, csvPath, CpGainPercentLight,IdxLbdOpt,LambdaOpt);
[YearPercentCpGainMedium] = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.ComputeYearPercentCpGain(settings.k, settings.Vavg, csvPath, CpGainPercentMedium,IdxLbdOpt,LambdaOpt);
[YearPercentCpGainHeavy] = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.ComputeYearPercentCpGain(settings.k, settings.Vavg, csvPath, CpGainPercentHeavy,IdxLbdOpt,LambdaOpt);

CpGainPercentLight = [CpGainPercentLight YearPercentCpGainLight];
CpGainPercentMedium = [CpGainPercentMedium YearPercentCpGainMedium];
CpGainPercentHeavy = [CpGainPercentHeavy YearPercentCpGainHeavy];

% Print results
fid = fopen('CCOPercentMargin2Cpmax.txt','wt');
fprintf(fid,'%s','Tip-speed-ratio ()');
for I = 1:length(TSRReduced)
    fprintf(fid,'%13.2f',TSRReduced(I));
end
fprintf(fid,'%13.7s','YearAvg')
fprintf(fid,'\n');   
fprintf(fid,'%s','MarginLightIce (%) ') ;    
for I = 1:length(TSRReduced)+1
    fprintf(fid,'%13.2f',CpGainPercentLight(I));
end
fprintf(fid,'\n');      
fprintf(fid,'%s','MarginMediumIce (%)');  
for I = 1:length(TSRReduced)+1
    fprintf(fid,'%13.2f',CpGainPercentMedium(I));
end
fprintf(fid,'\n');
fprintf(fid,'%s','MarginHeavyIce (%) ');
for I = 1:length(TSRReduced)+1
    fprintf(fid,'%13.2f',CpGainPercentHeavy(I));
end
fprintf(fid,'\n');
fprintf(fid,'\n');
fprintf(fid,'%s\n','Ice Categories');
fprintf(fid,'%s\n','Light ice: >=0.75*NominalCp');
fprintf(fid,'%s\n','Medium ice: >0.5 & =<0.75*NominalCp');
fprintf(fid,'%s\n','Heavy ice: <0.5*NominalCp');
fprintf(fid,'\n');
fprintf(fid,'\n');
fprintf(fid,'%s\n','Requirements on yearly averaged margins to Cp Max (YearAvg):');
fprintf(fid,'%s\n','Light ice: <2%');
fprintf(fid,'%s\n','Medium ice: <5%');
fprintf(fid,'%s\n','Heavy ice: <15%');
fprintf(fid,'\n');
fprintf(fid,'%s\n','Note: The heavy ice Cp margin is scaled down by 10% to accommodate uncertainty on the ice shapes');

fclose(fid);

%%
% figure(fnxt); fnxt = fnxt+1;
% v = [settings.pitchAngle.min:2:settings.pitchAngle.max];
% [px,py] = gradient(pitAngleVsCpVsTSR);
% 
% contourf(TSR_vec,Cp_vec,pitAngleVsCpVsTSR, v)
% hold on
% quiver(TSR_vec,Cp_vec,px,py)
% hold off
% grid on;