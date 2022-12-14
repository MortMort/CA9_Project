function baselineCampbell(turbname,outpath,YawMode,TiltMode,ColMode,manualModeSelection)
% This script reads the VStab Baseline Freqency Analysis and plots the
% first N eigenmodes.

% Default settings
imgSz = [680,420];
MS=12; % MarkerSize
LW=2; % LineWidth
suffix={'locked','idle'};
modes=[1:10]; % Which modes to plot out

for idleflag=[0,1]
    runname=[turbname '_FreqAnalysis_' suffix{idleflag+1}];
    load([outpath '/' runname '.mat'])
    
    if ~manualModeSelection && idleflag == 0  % Automated mode selector
        [~,prev_idx_damp] = sort(Res.dampratio{1,1}(modes(3:10)),'ascend'); % filter tower modes and 2nd order, select those with lowest damping (tilt, yaw, coll).
        prev_idx_damp = prev_idx_damp+2; % adjust for filtered tower modes
        
         [~,idx_freq] = sort(imag(Res.eigvals{1,1}(prev_idx_damp(1:3))),'ascend');        
        
         % locating locked modes and shifting -1 for idling
        ColMode = [prev_idx_damp(idx_freq(3)) prev_idx_damp(idx_freq(3))-1]; % highest freq
        TiltMode = [prev_idx_damp(idx_freq(2)) prev_idx_damp(idx_freq(2))-1]; % 2nd lowest freq
        YawMode = [prev_idx_damp(idx_freq(1)) prev_idx_damp(idx_freq(1))-1]; % lowest freq
    end
    
    figure(idleflag+1)
    hold off
    N=length(modes);
    omega(1:N,1) = imag(Res.eigvals{1,1}(modes)); % Extract frequency value from Vstab results
    freq(:,idleflag+1) = omega/(2*pi); % Convert to units of Hertz
    for n=1:N % For the first N number of modes
    plot([0,1],[freq(n,idleflag+1),freq(n,idleflag+1)],'--','color',[0.5,0.5,0.5],'LineWidth',LW)
    hold on
    end
    P(1)=plot([0,1],[freq(YawMode(idleflag+1),idleflag+1),freq(YawMode(idleflag+1),idleflag+1)],'--','color','r','LineWidth',LW);
    P(2)=plot([0,1],[freq(TiltMode(idleflag+1),idleflag+1),freq(TiltMode(idleflag+1),idleflag+1)],'--','color','g','LineWidth',LW);
    P(3)=plot([0,1],[freq(ColMode(idleflag+1),idleflag+1),freq(ColMode(idleflag+1),idleflag+1)],'--','color','b','LineWidth',LW);
    
    set(gca,'xtick',[0,1],'xticklabel',{' ',' '})
    xlim([0 1])
    title(['Eigenmodes at Standstill - Rotor ',suffix{idleflag+1}],'FontSize',14,'FontWeight','Bold')
    ylabel('\bfEigenfrequency [Hz]','FontSize',12)
    YawString=[num2str(YawMode(idleflag+1)),'. Yaw Mode',char(10),num2str(freq(YawMode(idleflag+1),idleflag+1)),'Hz'];
    TiltString=[num2str(TiltMode(idleflag+1)),'. Tilt Mode',char(10),num2str(freq(TiltMode(idleflag+1),idleflag+1)),'Hz'];
    ColString=[num2str(ColMode(idleflag+1)),'. Col Mode',char(10),num2str(freq(ColMode(idleflag+1),idleflag+1)),'Hz'];

    leg1=legend(P,{YawString,TiltString,ColString},'Location','SouthOutside','Orientation','Horizontal');

    set(gcf,'color','none','Position',[100,100,imgSz])
    print(gcf,[outpath '\Baseline_EModes_',suffix{idleflag+1}],'-dpng')
end