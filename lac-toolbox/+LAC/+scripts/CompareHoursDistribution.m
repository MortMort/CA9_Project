function CompareHoursDistribution(FoldersBaseline, FoldersISM, WSpds, saveFlag, SaveFolder)
% Function to create and save plots comparing number of hours (per quantile 
% and total), turbulence intensity and frequency distribution between standard 
% and ISM simulations for DLC 1.1 (different implementation of lognormal - DB 2.0). 
% These plots can be used for the creation of the gap analysis document for 
% ISM (see [1] and [2])
% [1] http://wiki.tsw.vestas.net/display/LACWIKI/Gap+Analysis+Document+for+ISM
% [2] 0103-2094.V00
%
% SYNTAX:
% 	LAC.scripts.CompareHoursDistribution(FoldersBaseline, FoldersISM, WSpds, saveFlag, SaveFolder)
%
% INPUTS:
% 	FoldersBaseline - Cell with baseline / standard simulation paths
% 	FoldersISM - Cell with ISM simulation paths (DLC 1.1 based on DB 2.0 lognormal implementation)
%   * Note: Folders order in cells above should be corresponding to one another (same variants)
%   WSpds - Vector containing the DLC 1.1 wind speeds (WSpds = 4:2:24)
%   saveFlag - Flag to save (1) or not (0) the plots created
%   SaveFolder - Folder to save the plots
%
% OUTPUTS:
%	Plots saved consisting on:
%   1. 'TurbInt' - For check only on the turbulence intensity values used
%   in both cases, should be the same (ratios included)
%   2. 'HoursComp' - Comparison of the number of hours per quantile (30%,
%   90%, 99%) per wind speed (ratios included)
%   3. 'FreqQuantiles' - Comparison between the frequency distribution of 
%   each quantile per wind speed  
%   4. 'TotalNrHours' - Comparison of the total number of hours considered
%   in DLC 1.1 per wind speed (sum of all quantiles, ratios included)
%
% VERSIONS:
% 	2021/03/26 - AAMES: V00
%
%% Quantiles definition (naming) 
Quantiles = {'[ab]lo','[ab]nt','[ab]hi'};

%% Read *.frq and *.set files, compare hours and turbulence 
for i = 1:length(FoldersBaseline)
    % Initialize matrices
    HoursBaseline = zeros(length(WSpds),length(Quantiles));
    HoursISM = zeros(length(WSpds),length(Quantiles));
    TotHoursBaseline = zeros(length(WSpds),1);
    TotHoursISM = zeros(length(WSpds),1);
    TurbIntBaseline = zeros(length(WSpds),length(Quantiles));
    TurbIntISM = zeros(length(WSpds),length(Quantiles));
    RatioFreqBaseline = zeros(length(WSpds),length(Quantiles));
    RatioFreqISM = zeros(length(WSpds),length(Quantiles));
    %% Get *.frq and *.set data
    simObjBaseline = LAC.vts.simulationdata(FoldersBaseline{i});
    simObjISM = LAC.vts.simulationdata(FoldersISM{i});
    frqObjBaseline = LAC.vts.convert(fullfile(simObjBaseline.simulationpath,'INPUTS',simObjBaseline.frqfile));
    frqObjISM = LAC.vts.convert(fullfile(simObjISM.simulationpath,'INPUTS',simObjISM.frqfile));
    setObjBaseline = LAC.vts.convert(fullfile(simObjBaseline.simulationpath,'INPUTS',simObjBaseline.setfile));
    setObjISM = LAC.vts.convert(fullfile(simObjISM.simulationpath,'INPUTS',simObjISM.setfile));
    %% Get number of hours for INT files
    TimeBaseline = [frqObjBaseline.time];
    TimeISM = [frqObjISM.time];
    %% Get freq of INT files
    FrqBaseline = [frqObjBaseline.frq];
    FrqISM = [frqObjISM.frq];
    %% Calculate hours based on number of seeds and freq
    % Get number of seeds / family
    [FamBaseline,~,icBase] = unique([frqObjBaseline.family]); 
    SeedsFamBaseline = accumarray(icBase,1)';
    [FamISM,~,icISM] = unique([frqObjISM.family]); 
    SeedsFamISM = accumarray(icISM,1)';
    % Calculate hours 
    if isequal(SeedsFamBaseline,SeedsFamISM)
        NrSeeds = zeros(1,length(TimeBaseline));
        index_end = 0;
        for f = 1:length(FamBaseline)
            index_start = index_end + 1;
            index_end = index_start + SeedsFamBaseline(f) - 1;
            NrSeeds(index_start:index_end) = SeedsFamBaseline(f);
        end
        NrSeedsBaseline = NrSeeds;
        NrSeedsISM = NrSeeds;
    else
        NrSeedsBaseline = zeros(1,length(TimeBaseline));
        NrSeedsISM = zeros(1,length(TimeISM));
        index_end = 0;
        for f = 1:length(FamBaseline)
            index_start = index_end + 1;
            index_end = index_start + SeedsFamBaseline(f) - 1;
            NrSeedsBaseline(index_start:index_end) = SeedsFamBaseline(f);
        end
        index_end = 0;
        for f = 1:length(FamISM)
            index_start = index_end + 1;
            index_end = index_start + SeedsFamISM(f) - 1;
            NrSeedsISM(index_start:index_end) = SeedsFamISM(f);
        end
    end
    TimeCalcFrqBaseline = FrqBaseline./NrSeedsBaseline;
    TimeCalcFrqISM = FrqISM./NrSeedsISM;
    %% Get TI (turbulence) for INT files
    TurbBaseline = [setObjBaseline.Turb];
    TurbISM = [setObjISM.Turb];
    %% Get relevant DLCs (DLC 1.1) for each WSpd and Quantile, get number of hours and turbulence and save data
    for k = 1:length(WSpds)
        if WSpds(k)<10
            WsToken = sprintf('0%d',WSpds(k));
        else
            WsToken = sprintf('%d',WSpds(k));
        end
        LC = sprintf('11%s',WsToken);
        % Loop in quantiles
        for j = 1:length(Quantiles)            
            %% Get nr hours for quantile and Wsp
            LCsQuantBaseline = find(~cellfun(@isempty,regexp([frqObjBaseline.LC],[LC Quantiles{j}])));
            LCsQuantISM = find(~cellfun(@isempty,regexp([frqObjISM.LC],[LC Quantiles{j}])));
            SumTimeBaseline = sum(TimeCalcFrqBaseline(LCsQuantBaseline));
            SumTimeISM = sum(TimeCalcFrqISM(LCsQuantISM));
            % Save number of hours per quantile for WSpd
            HoursBaseline(k,j) = SumTimeBaseline;
            HoursISM(k,j) = SumTimeISM;
            % Save total num of hours for WSp
            TotHoursBaseline(k) = TotHoursBaseline(k) + SumTimeBaseline;
            TotHoursISM(k) = TotHoursISM(k) + SumTimeISM;           
            %% Get turb for quantile and Wsp
            LCsSetQuantBaseline = find(~cellfun(@isempty,regexp([setObjBaseline.LC],[LC Quantiles{j}])));
            LCsSetQuantISM = find(~cellfun(@isempty,regexp([setObjISM.LC],[LC Quantiles{j}])));
            TiBaseline = unique(TurbBaseline(LCsSetQuantBaseline));
            TiISM = unique(TurbISM(LCsSetQuantISM));
            % Save turb for Wspd, quantile
            TurbIntBaseline(k,j) = TiBaseline;
            TurbIntISM(k,j) = TiISM;
        end
        % Get quantile ratios for baseline and ISM (per WSpeed)
        RatioFreqBaseline(k,:) = HoursBaseline(k,:)./TotHoursBaseline(k);
        RatioFreqISM(k,:) = HoursISM(k,:)./TotHoursISM(k);
    end
    %% Plot quantiles ratios
    figTitles = {'30% Quantile','90% Quantile','99% Quantile'};
    figure('Name',sprintf('Ref [%d] - Quantiles frequencies distribution',i))
    % Number of hours
    for qt = 1:length(Quantiles)
        subplot(1,3,qt)
        plot(WSpds,100.*(RatioFreqBaseline(:,qt)),'-o','LineWidth',1.2)
        hold on
        plot(WSpds,100.*(RatioFreqISM(:,qt)),'-^','LineWidth',1.2)
        grid on
        legend('Standard','ISM')
        xlim([WSpds(1)-1 WSpds(end)+1])
        xlabel('Wind speed [m/s]')
        ylabel('Percentage of total nr. of hours [%]')
        title(figTitles{qt})
    end
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.05, 0.9, 0.5]);
    % Save plot
    if saveFlag == 1
        compsFold = strsplit(FoldersBaseline{i},'\');
        variant = regexp(compsFold,'V.*HH.*','match','once');
        variant = variant{~cellfun(@isempty,variant)};
        saveas(gcf,fullfile(SaveFolder,sprintf('FreqQuantiles_%s.emf',variant)),'emf');
        saveas(gcf,fullfile(SaveFolder,sprintf('FreqQuantiles_%s.fig',variant)),'fig');
    end
    %% Plot number of hours + ratio ISM/Baseline and save plot
    figName = sprintf('Ref [%d] - Hours distribution - 30%%, 90%%, 99%% Quantiles',i);
    figTitles = {'30% Quantile','90% Quantile','99% Quantile'};
    figure('Name',figName)
    % Number of hours
    for qt = 1:length(Quantiles)
        subplot(2,3,qt)
        plot(WSpds,HoursBaseline(:,qt),'-o','LineWidth',1.2)
        hold on
        plot(WSpds,HoursISM(:,qt),'-^','LineWidth',1.2)
        grid on
        legend('Standard','ISM')
        xlim([WSpds(1)-1 WSpds(end)+1])
        xlabel('Wind speed [m/s]')
        ylabel('Number of hours [h]')
        title(figTitles{qt})
    end
    % Ratio
    for qt = 1:length(Quantiles)
        Ratio = HoursISM(:,qt)./HoursBaseline(:,qt);
        %Ratio(isnan(Ratio)) = 1;
        subplot(2,3,qt+length(Quantiles))
        plot(WSpds,Ratio,'-*','Color',[0.5 0.5 0.5],'LineWidth',1.2)
        grid on
        xlim([WSpds(1)-1 WSpds(end)+1])
        xlabel('Wind speed [m/s]')
        ylabel('Ratio ISM / Baseline [-]')
        title(figTitles{qt})
    end
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.05, 1, 0.95]);
    % Save nr of hours plot
    if saveFlag == 1
        saveas(gcf,fullfile(SaveFolder,sprintf('HoursComp_%s.emf',variant)),'emf');
        saveas(gcf,fullfile(SaveFolder,sprintf('HoursComp_%s.fig',variant)),'fig');
    end
    %% Plot sum of hours for each wind speed (needs to be the same for ISM and Baseline)
    RatioTot = TotHoursISM./TotHoursBaseline;
    figure('Name',sprintf('Ref [%d] - Total Number of Hours',i))
    subplot(1,2,1)
    plot(WSpds,TotHoursBaseline,'-o','LineWidth',1.2)
    hold on
    plot(WSpds,TotHoursISM,'-^','LineWidth',1.2)
    grid on
    legend('Standard','ISM')
    xlim([WSpds(1)-1 WSpds(end)+1])
    xlabel('Wind speed [m/s]')
    ylabel('Number of hours [h]')
    subplot(1,2,2)
    plot(WSpds,RatioTot,'-*','LineWidth',1.2)
    grid on
    xlim([WSpds(1)-1 WSpds(end)+1])
    xlabel('Wind speed [m/s]')
    ylabel('Ratio ISM / Baseline [-]')
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 0.95, 0.6]);
    % Save total nr of hours plot
    if saveFlag == 1
        saveas(gcf,fullfile(SaveFolder,sprintf('TotalNrHours_%s.emf',variant)),'emf');
        saveas(gcf,fullfile(SaveFolder,sprintf('TotalNrHours_%s.fig',variant)),'fig');
    end
    %% Plot turbulence 
    figNameTI = sprintf('Ref [%d] - Turb Intensity - 30%%, 90%%, 99%% Quantiles',i);
    figure('Name',figNameTI)
    % Number of hours
    for qt = 1:length(Quantiles)
        subplot(2,3,qt)
        plot(WSpds,TurbIntBaseline(:,qt),'-o','LineWidth',1.2)
        hold on
        plot(WSpds,TurbIntISM(:,qt),'-^','LineWidth',1.2)
        grid on
        legend('Standard','ISM')
        xlim([WSpds(1)-1 WSpds(end)+1])
        xlabel('Wind speed [m/s]')
        ylabel('Turbulence Intensity [-]')
        title(figTitles{qt})
    end
    % Ratio
    for qt = 1:length(Quantiles)
        Ratio = TurbIntISM(:,qt)./TurbIntBaseline(:,qt);
        %Ratio(isnan(Ratio)) = 1;
        subplot(2,3,qt+length(Quantiles))
        plot(WSpds,Ratio,'-*','Color',[0.5 0.5 0.5],'LineWidth',1.2)
        grid on
        xlim([WSpds(1)-1 WSpds(end)+1])
        xlabel('Wind speed [m/s]')
        ylabel('Ratio ISM / Baseline [-]')
        title(figTitles{qt})
    end
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.95]);
     % Save turb plot
    if saveFlag == 1
        saveas(gcf,fullfile(SaveFolder,sprintf('TurbInt_%s.emf',variant)),'emf');
        saveas(gcf,fullfile(SaveFolder,sprintf('TurbInt_%s.fig',variant)),'fig');
    end
end
end