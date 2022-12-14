function [AEP_range]=AEP_WSPrange_V2(Xbin, X_sens,Y_sens,WTG, FlagInterpolAll)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script was partly adapted from Plot_PowerCurve function, editted by
% SEHIK and MFCCM (January-2022)

% INPUT:
%     Xbin-> Measured (dat1) or simulated data (Simdat1) across wind speed bins, as well as the whole data set (.data),
%     with values of reduced sensor list
%     WTG -> general info on the turbine (CutInWSP, CutOutWSP, Weibull)
%     X_sens -> sensor number which stores wind speed entering the calculations,
%     defined in Sensors Sheet in InputInfo excel (12 - additional sensor, normalized WSP)
%     Y_sens -> number of sensor which stores power entering the calculations (usually 2 or 12 for normalized WSP)
%     WTG -> to define Vin, Vrat, Vout and reference power curve
%     FlagInterpolAll -> define as 1 if forcing the interpolation of
%     empty bin even though IEC standard is not fulfilled

% OUTPUT:
% Structure holding binned/total AEP measured and simulated for
% range of Annual Wind Speeds
% Output is printed to \Reports\AEP_data_range.txt

% Columns:
% (:,1) Average Annual Wind Speed [m/s], (:,2) AEP Measured, (:,3) AEP Measured Extrapolated, (:,4) AEP Simulated , (:,5) AEP Simulated Extrapolated,
% (:,6) AEP Measured Extrapolated based on Pref, (:,7) AEP Simulated Extrapolated based on Pref, (:,8) Simulated AEP/ AEP Extrapolated, (:,9) Measured AEP/ AEP Extrapolated
% (:,10) Sim-Extrapolated/Meas-Extrapolated, (:,11) Meas/Meas-Extrapolated-Pref, (:,12) Sim/Sim-Extrapolated-Pref]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initiation
% Find index of the incomplete bins
[bin_row, ~] = cellfun(@size,Xbin.bin1);
idx_empty_bins = find(bin_row<3); % bins which have less than 3 measurement data
idx_empty_bins = idx_empty_bins(find(cell2mat(Xbin.upperbinlimit(idx_empty_bins))>WTG.CutInWSP)); % disregard what comes below CutIn wind speed

% Getting rid of incomplete bins at the end of the dataset
idxi=0;
while idxi<length(idx_empty_bins)
    if idx_empty_bins(end) == length(bin_row)-idxi
        idx_empty_bins(end)=[];
        idxi=idxi+1;
    else
        break
    end
end

% IEC requirements check

[idx_WSP_required, idx_cutin, FlagCutWSP, line]=IEC_check(WTG, Xbin, bin_row,idx_empty_bins, FlagInterpolAll);

%% Dataset scenario

% Different scenarios ACCEPTABLE by IEC (interpretation of IEC 61400 - Part12)
% Note that the incomplete bins at the end of the dataset will be discarded
% 1 - No incomplete bin (or only at the end)
% 2/3 - 1 incomplete bin sorrounded by complete bins
%       -> 2 - incomplete bin below or equal to 1.5* WSP at 85% of the power rated -> will be interpolated, the database ends with the last complete bin;
%		-> 3 - incomplte bin above 1.5* WSP at 85% of the power rated -> the dataset will terminate by this incomplete bin;
%				option to force interpolation of all incomplete bins by FlagInterpolAll
% 4/5/6 - Multiple incomplete bins (not including bins at the end of the dataset)
%       -> 4 - 1 incomplete bin below 1.5* WSP at power rated, ONLY THE FIRST ONE can be interpolated, the database ends with the second incomplete bin;
%				option to force interpolation of incomplete bins >1.5*WSP(0.85Prated) by FlagInterpolAll
%				two options -> reduced dataset cover 1.5* WSP 
%							-> reduced dataset does not cover 1.5* WSP at 85% of the power rated - AEP measured has to be >95% AEP extrapolated
%		-> 5 - all incomplte bins above 1.5* WSP at 85% of the power rated - the dataset will terminate by the first incomplete bin;
%				option to force interpolation of all incomplete bins by FlagInterpolAll

if isempty(idx_empty_bins)
    idx_lastbin = length(bin_row)-idxi;  % minus incomplete bin at the end of the dataset (because  icomplete bin still captured in bin_row matrix)
    idx_interpol = [];
    
elseif length(idx_empty_bins) == 1
    if (idx_empty_bins<=idx_WSP_required && ~FlagCutWSP) || ((idx_empty_bins>idx_WSP_required || (idx_empty_bins<=idx_WSP_required && FlagCutWSP)) && FlagInterpolAll) 
	%	if incomplete bin <=idx_WSP_required interpolation defaultly, if >idx_WSP_required, interpolation has to be force by flag
        idx_interpol = idx_empty_bins;
        idx_lastbin = length(bin_row)-idxi;
        if idx_empty_bins<=idx_WSP_required && idx_empty_bins~=idx_lastbin
            line{end+1,1}=['A single incomplete bin was identified (bin ', num2str(cell2mat(Xbin.upperbinlimit(idx_interpol))-0.25), ' m/s). This bin was estimated by linear interpolation from the two adjacent complete bins.'];
            line{end+1,1}='';
            disp(' ');disp(line{end});
        elseif idx_empty_bins==idx_WSP_required && idx_empty_bins==idx_lastbin
            idx_interpol = [];
            idx_lastbin = idx_WSP_required-1;
        else
            line{end+1,1}=['A single incomplete bin above 1.5*(WSP at 85% of power rated) was identified (bin ', num2str(cell2mat(Xbin.upperbinlimit(idx_interpol))-0.25), ' m/s).'];
            disp(line{end});
            line{end+1,1}='';
            disp(' ');
            if FlagInterpolAll
                line{end+1,1}='This bin was estimated by linear interpolation from the two adjacent complete bins as requested by the user.';
            else
                line{end+1,1}='According to IEC standard, this bin will be considered as the last bin of dataset.';
            end
            disp(line{end});
            line{end+1,1}='';
            disp(' ');
        end
    else % (idx_empty_bins>idx_WSP_required || (idx_empty_bins<=idx_WSP_required && FlagCutWSP)) && ~FlagInterpolAll
        % if FlagInterpolAll not activated and dataset does not cover cut-in WSP -> AEP calculation wont be executed later
        idx_interpol = [];
        idx_lastbin = idx_empty_bins-1-idxi;
        
        if FlagCutWSP
            Flag_InterpolateBinsBelow85WSP=input('Dataset is not acceptable because it does not cover cut-in WSP.\n Do you wish to extrapolate this bin and calculate the AEP anyway? If yes, please enter 1, if not 0.\n');
            if Flag_InterpolateBinsBelow85WSP
                disp('Plese note that the dataset will NOT be acceptable.');
            end
            if Flag_InterpolateBinsBelow85WSP
                line{end+1,1}='As requested by the user, cut-in WSP was extrapolated and AEP calculated.';
                idx_interpol=idx_empty_bins;
                idx_lastbin = length(bin_row)-idxi;
            end
        end
    end
    
else % length(idx_empty_bins) > 1
    if sum(idx_empty_bins<=idx_WSP_required)>1
        % dataset is NOT acceptable but user can force the interpolation by FlagInterpolAll
        
        idx_belowWSPrequired=idx_empty_bins(idx_empty_bins<=idx_WSP_required);
        Flag3bins = check_3bins (idx_belowWSPrequired, line);
        
        if ~FlagInterpolAll && ~Flag3bins
            Flag_InterpolateBinsBelow85WSP=input('Dataset is not acceptable because there are multiple incomplete bins below or equal to 1.5* WSP at power rated.\n Do you wish to interpolate those bins to calculate the AEP anyway? If yes, please enter 1, if not 0.\n');
            if Flag_InterpolateBinsBelow85WSP
                disp('Plese note that the dataset will NOT be acceptable.');
            end
        end
        
        if FlagInterpolAll && ~Flag3bins
            line{end+1,1}='As requested by the user, all incomplete bins were interpolated and AEP calculated.';
            disp(line{end});
            idx_interpol=idx_empty_bins;
            idx_lastbin=length(bin_row)-idxi;
            
            Flag3bins = check_3bins (idx_interpol, line); % check if ANY incomplete bins (which are to be interpolated) are three in a row and more
            if Flag3bins
                idx_interpol=[];
                idx_lastbin=[];
            end
            
        elseif FlagInterpolAll && Flag3bins
            line{end+1,1}=' ';
            disp(line{end});
            line{end+1,1}='Although requested by the user, incomplete bins could not be interpolated as there are three or more incomplete bins in a row.';
            disp(line{end});
            idx_interpol=[];
            idx_lastbin=[];
        elseif exist('Flag_InterpolateBinsBelow85WSP') && Flag_InterpolateBinsBelow85WSP % ~Flag3bins from previous condition
            line{end+1,1}='As requested by the user, all incomplete bins below 1.5* WSP at power rated were interpolated and AEP calculated.';
            idx_interpol=idx_empty_bins(find(idx_empty_bins<=idx_WSP_required));
            if isempty(idx_empty_bins>idx_WSP_required)
                idx_lastbin=length(bin_row)-idxi;
            else
                idx_lastbin=idx_empty_bins(find(idx_empty_bins>idx_WSP_required));
                idx_lastbin=idx_lastbin(1)-1-idxi;
            end
            
        else % there is more than 1 incomplete bins below 1.5WSP(0.85Prat) and FlagInterpolAll and Flag_InterpolateBinsBelow85WSP are inactive -> check if dataset up to the second incomplete bin fulfills 95% AEP extrapolated requirement
            if Flag3bins
                idx_interpol=[];
                idx_lastbin=[];
            else
                idx_interpol=idx_empty_bins(1);
                idx_lastbin=idx_empty_bins(2)-1-idxi;
            end
        end
        
        if ~isempty(idx_interpol) && idx_interpol(end)==idx_lastbin
            idx_interpol(end)=[];
            idx_lastbin=idx_lastbin-1;
        end
        
    else % isempty(idx_empty_bins<=idx_WSP_required) || length(idx_empty_bins<=idx_WSP_required)==1
        % if dataset covers cut-in WSP, dataset is acceptable and user can choose to either follow IEC requirements or calculate AEP by interpolating all empty bins by FlagInterpolAll
        if FlagInterpolAll
            line{end+1,1}=' ';
            disp(line{end});
            idx_interpol = idx_empty_bins;
            idx_lastbin=length(bin_row)-idxi;
            Flag3bins = check_3bins (idx_interpol, line); % check if ANY incomplete bins (which are to be interpolated) are three in a row and more
            if Flag3bins
                line{end+1,1}='Although requested by the user, incomplete bins could not be interpolated as there are three or more incomplete bins in a row.';
                disp(line{end});
                idx_interpol=[];
                idx_lastbin=[];
            else
                line{end+1,1}='As requested by the user, all incomplete bins were interpolated and AEP calculated.';
                disp(line{end});
            end
        elseif sum(idx_empty_bins<=idx_WSP_required)==1 && ~FlagCutWSP
            if idx_empty_bins(2)-idx_empty_bins(1)~=1
                idx_interpol = idx_empty_bins(1);
                idx_lastbin = idx_empty_bins(2)-1;
                line{end+1,1}=['A single incomplete bin was identified (bin ', num2str(cell2mat(Xbin.upperbinlimit(idx_interpol))-0.25), ' m/s). This bin will be estimated by linear interpolation from the two adjacent complete bins.'];
                disp(' ');disp(line{end});disp(' ');
            else
                idx_interpol = [];
                idx_lastbin = idx_empty_bins(2)-2;
            end
        elseif FlagCutWSP  % there is incomplete bin at cut-in WSP -> AEP will not be calculated
            
			if ~FlagInterpolAll 
				Flag_InterpolateBinsBelow85WSP=input('Do you wish to interpolate the cut-in WSP bin to calculate the AEP anyway? If yes, please enter 1, if not 0.\n');
				if Flag_InterpolateBinsBelow85WSP
					disp('Plese note that the dataset will NOT be acceptable.');
				end
			end
			
			if Flag_InterpolateBinsBelow85WSP
				idx_interpol = idx_empty_bins(1);
				idx_lastbin = idx_empty_bins(2)-1;
			else
				idx_interpol = [];
				idx_lastbin = [];
			end
			
        else  %isempty(idx_empty_bins<=idx_WSP_required)
            idx_interpol = [];
            idx_lastbin = idx_empty_bins(1)-1;
            line{end+1,1}=['The dataset ends by the first incomplete bin (bin ', num2str(cell2mat(Xbin.upperbinlimit(idx_lastbin))-0.25), ' m/s).'];
            disp(' ');disp(line{end});
        end
    end
end

%% CALCULATE AEP

if isempty(idx_lastbin)
    AEP_range=[];
else
    % If dataset does not cover cut-in and extrapolation is not forced, AEP won't be calculated
    if FlagCutWSP && (~FlagInterpolAll && (~exist('Flag_InterpolateBinsBelow85WSP') || (exist('Flag_InterpolateBinsBelow85WSP')&& ~Flag_InterpolateBinsBelow85WSP)))
        line{end+1,1}='AEP will not be calculated. ';
        disp(' ');disp(line{end});
        AEP_range=[];
        fid = fopen('AEP_msg.txt', 'w');
        msg = sprintf('%s\n',line{:});
        fwrite(fid,msg);
        fclose(fid);
        return;
    end
    
    line_idx_init=length(line);
    
    [AEP_range, line] = AEP_calculation(Xbin, X_sens,Y_sens, WTG, idx_lastbin, line, idx_interpol, idx_cutin, FlagInterpolAll);
    
    line_idx_final=length(line);
    
    % If dataset does not cover 1.5WSP(0.85Prat), check IEC requirement of AEP measured >= 95% of AEP extrapolated
    if idx_lastbin<=idx_WSP_required
        if table2array(AEP_range.total.table(9,8))<0.95 
            line{end+1,1}='';
            line{end+1,1}='The dataset does not cover 1.5*WSP at 85% power rated and the ratio AEP measured/AEP-extrapolated is less than 95%, AEP will not be calculated. ';
            disp(' ');disp(line{end});
			Flag_ForceDisplay=input('Do you wish to save the AEP calculation results anyway? If yes, please enter 1, if not 0.\n');
			if Flag_ForceDisplay
				disp('Plese note that the dataset will NOT be acceptable.');
				sprintf('%s\n',line{line_idx_init+1:line_idx_final,1});
                disp(' ');disp(line{end});
            else
                line(line_idx_init:line_idx_final)=[];
				AEP_range=[];
			end
        else
            sprintf('%s\n',line{line_idx_init+1:line_idx_final,1});
            line{end+1,1}='';
            line{end+1,1}='The dataset does not cover 1.5*WSP at 85% power rated but the ratio AEP measured/AEP-extrapolated is equal or more than 95%, AEP will be calculated. ';
            disp(' ');disp(line{end});
        end
        
    else
        sprintf('%s\n',line{line_idx_init+1:line_idx_final,1})
    end
end

%% WRITE CALCULATION MEASAGE

fid = fopen('AEP_msg.txt', 'w');

if FlagInterpolAll || (exist('Flag_InterpolateBinsBelow85WSP') && Flag_InterpolateBinsBelow85WSP) || (exist('Flag_ForceDisplay') && Flag_ForceDisplay)
	msg = sprintf('%s\n','!! Note that the dataset does not fullfil IEC 61400 requirements and calculation should only serve for investigation purposes.','', line{:});
else
	msg = sprintf('%s\n',line{:});
end
fwrite(fid,msg);
fclose(fid);
if ~isempty(AEP_range)
    writetable(AEP_range.total.table, 'AEP_table.txt','Delimiter','\t');
end

end


function [idx_WSP_required, idx_cutin, FlagCutWSP, line]=IEC_check(WTG, Xbin, bin_row,idx_empty_bins, FlagInterpolAll)

%% Preparing input parameters

Hours_measured = sum(bin_row)*10/60;
idx_cutin = find(cell2mat(Xbin.upperbinlimit)>WTG.CutInWSP);
idx_cutin = idx_cutin(1);
Power_85pctg = 0.85*WTG.Power;

idx=1;
while (WTG.Pref(idx,2)-Power_85pctg)<0
    idx=idx+1;
end

WSP_85pctg = WTG.Pref(idx,1);
idx_WSP_required = find(cell2mat(Xbin.upperbinlimit)>1.5*WSP_85pctg);
idx_WSP_required = idx_WSP_required(1);

%% Initial message

if (~isempty(idx_empty_bins) && (idx_cutin == idx_empty_bins(1) || sum(idx_empty_bins < idx_WSP_required) > 1)) && FlagInterpolAll
    line{1,1} = '!!  Warning: Interpolation of incomplete bins was forced by the user even though the dataset does NOT fulfill IEC standard.';
    disp(line{end});
    line{2,1} = 'Please note that AEP calculation should thus only serve for additional investigations. ';
    disp(line{end});
    line{end+1,1} = ' ';
    disp(line{end});
    line{end+1,1} = 'Checking IEC requirements of the dataset (IEC standard 61400-12-2).';
    disp(line{end});
    line{end+1,1} = ' ';
    disp(line{end});
else
    line{1,1} = 'Checking IEC requirements of the dataset (IEC standard 61400-12-2).';
    disp(line{end});
    line{end+1,1} = ' ';
    disp(line{end});
end



%% 1. Check that the dataset includes > 180 hours of measurement
% Note: AEP will still be calculated even if the requirement is not fulfilled

if (Hours_measured < 180)
    line{end+1,1} = '!! Dataset cannot be accepted. Reason: does not include a minimum of 180 hours of sampled data.';
    disp(line{end});
    FlagHours=1;
else
    FlagHours=0;
end

%% 2. Check that the WSP range covers cut-in WSP
% Note: AEP will still be calculated even if the requirement is not fulfilled

if (~isempty(idx_empty_bins) && idx_cutin == idx_empty_bins(1)) || Xbin.lowerbinlimit{1}>WTG.CutInWSP  
    line{end+1,1} = '!! Dataset cannot be accepted. Reason: WSP range does not cover cut-in WSP.';
    disp(line{end});
    FlagCutWSP=1;
else
    FlagCutWSP=0;
end

%% 3. Check that the WSP range covers 1.5*WSP(at 0.85*Prat)
% Note: AEP will still be calculated even if the requirement is not fulfilled

if sum(idx_empty_bins <= idx_WSP_required) > 1 || ((sum(idx_empty_bins <= idx_WSP_required)==1 && Xbin.lowerbinlimit{1}>WTG.CutInWSP) || (sum(idx_empty_bins <= idx_WSP_required)==0 && Xbin.lowerbinlimit{1}>WTG.CutInWSP+0.5))
    % need to check not onlu empty bins but also when the capture matrix starts
    line{end+1,1} = '!! Dataset cannot be accepted. Reason: there are at least 2 incomplete bins between cut-in WSP and 1.5*WSP(at 0.85*Prat).';
    disp(line{end});
    FlagReqWSP=1;
else
    FlagReqWSP=0;
end
%% All requirements fulfilled

if ~FlagHours && ~FlagCutWSP && ~FlagReqWSP
    
    line{end+1,1} = 'All the following criteria were respected:';
    disp(line{end});
    line{end+1,1} = '- Minimum of 180 hours of sampled data';
    disp(line{end});
    line{end+1,1} = '- The range of measured wind speeds covers cut-in WSP';
    disp(line{end});
    line{end+1,1} = '- There is not more than 1 empty bin between cut-in and 1,5 times the wind speed at 85% of the rated power of the wind turbine';
    disp(line{end});
    disp(' ');
end

end


function [AEP_range, line] = AEP_calculation(Xbin, X_sens,Y_sens, WTG, idx_lastbin, line, idx_interpol, idx_cutin, FlagInterpolAll)

%% INPUTS

line{end+1,1}='Computing the AEP over the range of average wind speeds';

line{end+1,1}=' ';
line{end+1,1} = 'AEP will be calculated in 3 different ways:';
line{end+1,1} = '- AEP-measured shall be obtained from the measured power curve by assuming zero power for all wind speeds above and below the range of the measured power curve.';
line{end+1,1} = '- AEP-extrapolated shall be obtained from the measured PC by assuming zero power for all wind speeds below the lowest wind speed in the measured PC and constant power for wind speeds between the highest wind speed in the measured PC and the cut-out wind speed. The constant power used for the extrapolated AEP shall be the power value from the bin at the highest wind speed in the measured PC.';
line{end+1,1} = '- AEP-extrapolated shall be obtained from the measured PC by assuming zero power for all wind speeds below the lowest wind speed in the measured PC and follow the reference power curve for wind speeds between the highest wind speed in the measured PC and the cut-out wind speed.';
line{end+1,1} = ' ';

types={'meas' 'meas_extrapol' 'sim' 'sim_extrapol' 'meas_extrapol_Pref' 'sim_extrapol_Pref'};
Nh = 8760;                                  % number of hours in one year

% For each bin and AEP total, over the designed range of annual wind speeds
Vavg_range = 4:1:11; 						% range of Average Annual Wind Speed [m/s] required
Vavg_range(end+1) = WTG.Vavg; 				% AEP in last column is calculated for reference Vavg
AEP_range.total.data(:, 1) = Vavg_range;

% Get Vavg_names vector
for v = 1:length(Vavg_range)
    Vavg_names{v} = ['Vavg ' num2str(Vavg_range(v)) ' m/s'];
end

% Loop over 6 types of calculations : meas., meas. extrapol., simul.,simul. extrapol., meas. extrapol. Pref, sim. extrapol. Pref

for t=1:length(types)
    type=types{t};
    
    if any(t==[1,2,5])
        data=Xbin.dat1;
    else
        data=Xbin.Simdat1;
    end
    
    % Excluding bins from the first bin which does not fulfil IEC standard
    Vn = data.mean(1:idx_lastbin,X_sens);
    
    for v = 1:length(Vavg_range) % loop for range of Average Annual Wind Speeds
        
        Vavg=Vavg_range(v);
        
        if WTG.Weibull == 2
            F_Rayleigh = 1;
        else
            F_Rayleigh = 0;
            C_factor   = Vavg / gamma(1 + 1 / WTG.Weibull);
        end
        
        j = 1; k=1; FlagSkip=0;
        for i = WTG.CutInWSP:0.5:WTG.CutOutWSP
            ws_p = find((round(Vn(:) * 2) / 2) == i, 1);
            
            if FlagSkip
                FlagSkip=0;
                continue;
            end
            
            if ~isempty(ws_p) && (isempty(idx_interpol) || i ~= cell2mat(Xbin.upperbinlimit(idx_interpol(k)))-0.25)
                
                % READS THE DATA DIRECTLY
                AEP_range.binned.(type)(j, 1) = data.mean(ws_p, X_sens);
                AEP_range.binned.(type)(j, 2) = data.mean(ws_p, Y_sens);
                
            elseif ~isempty(idx_interpol) && i == cell2mat(Xbin.upperbinlimit(idx_interpol(k)))-0.25
                
                % EXTRAPOLATE to cut-in WSP
                if i==WTG.CutInWSP
                    ws_p_low = idx_cutin+1;
                    ws_p_high = idx_cutin+2;
                    if FlagInterpolAll && idx_interpol(2)-idx_interpol(1)==1 % two incomplete bins at cut-in WSP and following
                        AEP_range.binned.(type)(j+1, 1) = 2*(data.mean(ws_p_low+1, X_sens))-data.mean(ws_p_high+1, X_sens); % extrapolate first the later wind bin
                        AEP_range.binned.(type)(j+1, 2) = 2*(data.mean(ws_p_low+1, Y_sens))-data.mean(ws_p_high+1, Y_sens);
                        AEP_range.binned.(type)(j, 1) = 2*(data.mean(ws_p_low, X_sens))-data.mean(ws_p_high, X_sens);
                        AEP_range.binned.(type)(j, 2) = 2*(data.mean(ws_p_low, Y_sens))-data.mean(ws_p_high, Y_sens);
                        if AEP_range.binned.(type)(j, 2)<0
                            AEP_range.binned.(type)(j, 2)=0; % set to zero if extrapolation results in negative value
                        end
                        FlagSkip=1; % skip the next bin
                    else % length(idx_interpol)==1 || idx_interpol(2)-idx_interpol(1)~=1
                        AEP_range.binned.(type)(j, 1) = 2*(data.mean(ws_p_low, X_sens))-data.mean(ws_p_high, X_sens);
                        AEP_range.binned.(type)(j, 2) = 2*(data.mean(ws_p_low, Y_sens))-data.mean(ws_p_high, Y_sens);
                        if AEP_range.binned.(type)(j, 2)<0
                            AEP_range.binned.(type)(j, 2)=0; % set to zero if extrapolation results in negative value
                        end
                        if length(idx_interpol)>k
                            k=k+1;
                        end
                    end
                    
                    %INTERPOLATE MISSING BINS
                    %SCENARIOS: 1) 1 bin to interpolate 2) >1 bins to interpolate - 2a) bins are surrounded by complete bins 2b) bins are adjacent
                elseif length(idx_interpol)>1 && k~=length(idx_interpol) && idx_interpol(k+1)-idx_interpol(k)==1 % scenario 2b -> interpolate both bins at once
                    ws_p_low = find((round(Vn(:) * 2) / 2) == i-0.5, 1);
                    ws_p_high = ws_p_low+3;
                    AEP_range.binned.(type)(j, 1) = data.mean(ws_p_low, X_sens)+ (data.mean(ws_p_high, X_sens)- data.mean(ws_p_low, X_sens))*1/3;
                    AEP_range.binned.(type)(j, 2) = data.mean(ws_p_low, Y_sens)+ (data.mean(ws_p_high, Y_sens)- data.mean(ws_p_low, Y_sens))*1/3;
                    AEP_range.binned.(type)(j+1, 1) = data.mean(ws_p_low, X_sens)+ (data.mean(ws_p_high, X_sens)- data.mean(ws_p_low, X_sens))*2/3;
                    AEP_range.binned.(type)(j+1, 2) = data.mean(ws_p_low, Y_sens)+ (data.mean(ws_p_high, Y_sens)- data.mean(ws_p_low, Y_sens))*2/3;
                    FlagSkip=1; % skip the next bin
                elseif length(idx_interpol)==1 || k==length(idx_interpol) || idx_interpol(k+1)-idx_interpol(k)~=1 % scenario 1 & 2a
                    ws_p_low = find((round(Vn(:) * 2) / 2) == i-0.5, 1);
                    ws_p_high = ws_p_low+2;
                    AEP_range.binned.(type)(j, 1) = (data.mean(ws_p_low, X_sens)+data.mean(ws_p_high, X_sens))/2;
                    AEP_range.binned.(type)(j, 2) = (data.mean(ws_p_low, Y_sens)+data.mean(ws_p_high, Y_sens))/2;
                    if length(idx_interpol)>1 && k~=length(idx_interpol) && idx_interpol(k+1)-idx_interpol(k)~=1 % scenario 2a
                        k=k+1;
                    end
                end
                
            elseif any(t==[1,3])
                
                % ASSUMES AEP TO BE ZERO FOR MEASURED/SIMULATED AEP
                AEP_range.binned.(type)(j, 1) = WTG.Pref(j, 1);
                AEP_range.binned.(type)(j, 2) = 0;
                
            elseif any(t==[2,4])
                
                % ASSUMES CONSTANT VALUES BASED ON LAST NON-EMPTY BIN (AEP extrapolated)
                % loop in case that WSP does not cover cut-in WSP
                AEP_range.binned.(type)(j, 1) = WTG.Pref(j, 1);
                AEP_range.binned.(type)(j, 2) =  AEP_range.binned.(type)(idx_lastbin-1, 2); % minus first empty bin
            else
                % ASSUMES VALUES FROM POWER REFERENCE CURVE
                
                AEP_range.binned.(type)(j, 1) = WTG.Pref(j, 1);
                AEP_range.binned.(type)(j, 2) = WTG.Pref(j, 2);
                
            end
            
            if F_Rayleigh == 1
                F_V(j,v) = 1 - exp(-(pi/4) * (AEP_range.binned.(type)(j, 1) / Vavg) ^ WTG.Weibull); % SEHIK 18/08/2021 change from WTG.Vavg to Vavg over required range
                if FlagSkip
                    F_V(j+1,v)= 1 - exp(-(pi/4) * (AEP_range.binned.(type)(j+1, 1) / Vavg) ^ WTG.Weibull);
                end
            else
                F_V(j,v) = 1 - exp( -(AEP_range.binned.(type)(j, 1) / C_factor) ^ WTG.Weibull);
                if FlagSkip
                    F_V(j+1,v) = 1 - exp( -(AEP_range.binned.(type)(j+1, 1) / C_factor) ^ WTG.Weibull);
                end
            end
            
            if j == 1
                AEP_range.binned.(type)(j, v+2) = Nh * (F_V(j,v) - 0) * (AEP_range.binned.(type)(j, 2) + 0) / 2;
                if FlagSkip
                    AEP_range.binned.(type)(j+1, v+2) = Nh * (F_V(j+1,v) - F_V(j,v)) * (AEP_range.binned.(type)(j+1, 2) + AEP_range.binned.(type)(j, 2)) / 2;
                end
            elseif isempty(ws_p)
                if ~isempty(idx_interpol) && i == cell2mat(Xbin.upperbinlimit(idx_interpol(k)))-0.25
                    if FlagSkip
                        AEP_range.binned.(type)(j, v+2) = Nh * (F_V(j,v) - F_V(j-1,v)) * (AEP_range.binned.(type)(j, 2) + AEP_range.binned.(type)(j-1, 2)) / 2;
                        AEP_range.binned.(type)(j+1, v+2) = Nh * (F_V(j+1,v) - F_V(j,v)) * (AEP_range.binned.(type)(j+1, 2) + AEP_range.binned.(type)(j, 2)) / 2;
                    else
                        AEP_range.binned.(type)(j, v+2) = Nh * (F_V(j,v) - F_V(j-1,v)) * (AEP_range.binned.(type)(j, 2) + AEP_range.binned.(type)(j-1, 2)) / 2;
                    end
                elseif any(t==[1,3])
                    AEP_range.binned.(type)(j, v+2)=0;
                else
                    AEP_range.binned.(type)(j, v+2) = Nh * (F_V(j,v) - F_V(j-1,v)) * (AEP_range.binned.(type)(j, 2) + AEP_range.binned.(type)(j-1, 2)) / 2;
                end
                
            else
                if ~isempty(idx_interpol) && i == cell2mat(Xbin.upperbinlimit(idx_interpol(k)))-0.25 && FlagSkip
                    
                    AEP_range.binned.(type)(j, v+2) = Nh * (F_V(j,v) - F_V(j-1,v)) * (AEP_range.binned.(type)(j, 2) + AEP_range.binned.(type)(j-1, 2)) / 2;
                    AEP_range.binned.(type)(j+1, v+2) = Nh * (F_V(j+1,v) - F_V(j,v)) * (AEP_range.binned.(type)(j+1, 2) + AEP_range.binned.(type)(j, 2)) / 2;
                else
                    AEP_range.binned.(type)(j, v+2) = Nh * (F_V(j,v) - F_V(j-1,v)) * (AEP_range.binned.(type)(j, 2) + AEP_range.binned.(type)(j-1, 2)) / 2;
                end
            end
            
            if FlagSkip
                j=j+1;
                k=k+1;
            end
            j = j + 1;
            
        end
        
        AEP_range.total.data(v, t+1)= sum(AEP_range.binned.(type)(:, v+2));
        
    end
    
    AEP_range.unit={'m/s' 'MWh' 'kW'};
    line{end+1,1}=(['AEP based on ' type ': ', num2str(AEP_range.total.data(end,t+1)/1000), ' MWh for Average Wind Speed of ', num2str(Vavg), ' m/s']);
    
    if t==4
        line{end+1,1}=['!! Warning: Wind speed bin ', num2str(round(Vn(idx_lastbin) * 2) / 2+0.5), ' to ' num2str(WTG.CutOutWSP), ' m/s is empty. AEP will be considered zero for this bin for the calculation of AEP measured/simulated.'];
        line{end+1,1}=['!! Warning: Wind speed bin ', num2str(round(Vn(idx_lastbin) * 2) / 2+0.5), ' to ' num2str(WTG.CutOutWSP), ' m/s is empty. The power curve data from last non-empty bin will be used for this bin for the calculation of AEP-extrapolated.'];
    elseif t==6
        line{end+1,1}=['!! Warning: Wind speed bin ', num2str(round(Vn(idx_lastbin) * 2) / 2+0.5), ' to ' num2str(WTG.CutOutWSP), ' m/s is empty. The reference power curve is used for extrapolation.'];
    end
    
end
line{end+1,1} = '';
AEP_range.binned.cellnames=['Normalized WSP [m/s]' 'Power [kW]' cellstr(Vavg_names)];
AEP_range.total.data(:,end+1)=AEP_range.total.data(:,2)./AEP_range.total.data(:,3);
AEP_range.total.data(:,end+1)=AEP_range.total.data(:,4)./AEP_range.total.data(:,5);
AEP_range.total.data(:,end+1)=AEP_range.total.data(:,4)./AEP_range.total.data(:,2);
AEP_range.total.data(:,end+1)=AEP_range.total.data(:,5)./AEP_range.total.data(:,3);
AEP_range.total.data(:,end+1)=AEP_range.total.data(:,2)./AEP_range.total.data(:,6);
AEP_range.total.data(:,end+1)=AEP_range.total.data(:,4)./AEP_range.total.data(:,7);
AEP_range.total.cellnames={'Average_Annual_Wind_Speed', 'AEP_Measured', 'AEP_Measured_Extrapolated', 'AEP_Simulated' , 'AEP_Simulated_Extrapolated', 'AEP_Measured_Extrapolated_PRef', 'AEP_Simulated_Extrapolated_PRef','Measured_AEP_Extrapolated_ratio', 'Simulated_AEP_Extrapolated_ratio' , 'Simulated_AEP_Measured_ratio' , 'Simulated_Extrapolated_AEP_Measured_Extrapolated_ratio' , 'Measured_AEP_Extrapolated_PRef_ratio' , 'Simulated_AEP_Extrapolated_PRef_ratio'};
AEP_range.total.table=array2table(AEP_range.total.data,'VariableNames', AEP_range.total.cellnames);
%line{end+1,1}=['AEP measured for ' num2str(WTG.Vavg) ' m/s is ' num2str(AEP_range.total.data(end,2)/1e3) ' MWh, AEP measured-extrapolated is ' num2str(AEP_range.total.data(end,3)/1e3) ' MWh, AEP simulated is ' num2str(AEP_range.total.data(end,4)/1e3) ' MWh, AEP simulated-extrapolated is ' num2str(AEP_range.total.data(end,5)/1e3) ' MWh, AEP measured-extrapolated-PRef is ' num2str(AEP_range.total.data(end,6)/1e3) ' MWh and AEP simulated-extrapolated-PRef is ' num2str(AEP_range.total.data(end,7)/1e3) ' MWh.'];
line{end+1,1} = ['Ratio Meas/Meas-Extrapolated = ' num2str(AEP_range.total.data(end,8))];
line{end+1,1} = ['Ratio Sim/Sim-Extrapolated = ' num2str(AEP_range.total.data(end,9))];
line{end+1,1} = ['Ratio Sim/Meas = ' num2str(AEP_range.total.data(end,10))];
line{end+1,1} = ['Ratio Sim-Extrapolated/Meas-Extrapolated = ' num2str(AEP_range.total.data(end,11))];
line{end+1,1} = ['Ratio Meas/Meas-Extrapolated-Pref = ' num2str(AEP_range.total.data(end,12))];
line{end+1,1} = ['Ratio Sim/Sim-Extrapolated-Pref = ' num2str(AEP_range.total.data(end,13))];
line{end+1,1} = '';
line{end+1,1} = 'Please consult AEP_table.txt for AEP information for different Vavg.';

%% Check for IEC alternative requirement: 'AEP-measured' is greater than or equal to 95 % of ?AEP-extrapolated?
% 			if AEP_range.total.data(end,length(types)+2)<0.95
% 				line{end+1,1} = 'AEP-measured is NOT greater than or equal to 95% of AEP-extrapolated, thus AEP-extrapolated cannot be used for AEP evaluation in this investigation.';
% 				disp(line{end});
% 			else
% 				line{end+1,1} = 'AEP-measured is greater than or equal to 95% of AEP-extrapolated, thus AEP-extrapolated can be used for AEP evaluation in this investigation.';
% 				disp(line{end});
% 			end

end

function [Flag3bins, line] = check_3bins (idx, line)

Flag3bins=0;
if length(idx)>=3
    for ii=1:length(idx)-2
        if idx(ii+2)-idx(ii)==2
            Flag3bins=1;
            line{end+1,1}='There are 3 or more adjacent incomplete bins in the dataset, AEP will not be calculated.';
            disp(line{end});
        end
    end
end

end






