function stabilityMapFinal(turbine,turbname,outfolder,p2pMoment,f_risk,ref_loads)
% Creating stability maps at allowable wind speeds.

config = turbine.config;
suffix={'Locked','Idle'};
    
len = length(config);
for c=1:len        
    if config(c).service_type == 2 % only idling or rotor locked modes.
        continue % next iteration
    else
    idleFlag = config(c).idleflag;
        
    load([outfolder '/' f_risk '/' turbname '_' config(c).case '_' 'ZFac.mat']);
    load([outfolder '/' ref_loads '/' turbname '_LoadEnvelope_' config(c).case])

    yaw_step = yawerr(2)-yawerr(1);
    yaw_binsize = 30/yaw_step;
    yawN = length(yawerr);

    if length(azim)>1
        azim_step = azim(2)-azim(1);
        azim_binsize = 30/azim_step;
        azimN = length(azim)*3;
        azimarray = azim(1):azim_step:azim(end)*3+2*azim_step;
    else
        azim_step = 120;
        azim_binsize = 120/azim_step;
        azimN = length(azim)*3;
        azimarray = azim(1):azim_step:azim(end)*3+2*azim_step;
    end

    figure
    H=imagesc(WLoads);
    set(gca,'Xtick',[1:yaw_binsize:yawN],'YTick',[1:azim_binsize:azimN])
    set(gca,'XtickLabel',yawerr(1:yaw_binsize:yawN),'YtickLabel',azimarray(1:azim_binsize:azimN))
    axis square
    xlabel('\bfYaw error [\circ]','FontSize',12)
    ylabel('\bfBlade azimuth [\circ]','FontSize',12)
    title({sprintf('%s Stability Map - Rotor %s - Vhub = %2.1f m/s',turbname,suffix{idleFlag+1},wsp);
        sprintf('Characteristic wind speed: %s', tag)},'FontSize',12,'FontWeight','Bold','Interpreter','none')
    c1=colorbar;
    ylabel(c1,'\bf Blade Root Bending Load [kNm]','FontSize',12)
    print([outfolder '/' f_risk '/' turbname '_StabMap_' suffix{idleFlag+1} '_FINAL.png'],'-dpng','-r200')
    
%     title({ string; 
%         sprintf('%.2f %% of all cycles plotted, (accumulated from sorted list of cycle count)',cutoff*100);
%         sprintf('Envelope (Mean +- range/2): %.2f to %.2f',min(eff(:,2)),max(eff(:,1)));
%         sprintf('Envelope (100%% of cases) (Mean +- range/2): %.2f to %.2f',min(effraw(:,2)),max(effraw(:,1)));        
%         }, 'Interpreter', 'none')

    figure
    StabLoads=WLoads;
    StabLoads(StabLoads<p2pMoment)=0;
    StabLoads(StabLoads>=p2pMoment)=1;
    cmap=[0 0 1;1 0 0];
    colormap(cmap)
    imagesc(StabLoads,[-0.5 1.5])
    set(gca,'Xtick',[1:yaw_binsize:yawN],'YTick',[1:azim_binsize:azimN])
    set(gca,'XtickLabel',yawerr(1:yaw_binsize:yawN),'YtickLabel',azimarray(1:azim_binsize:azimN))
    axis square
    xlabel('\bfYaw error [\circ]','FontSize',12)
    ylabel('\bfBlade azimuth [\circ]','FontSize',12)
    title({sprintf('%s Stability Map - Rotor %s - Vhub = %2.1f m/s',turbname,suffix{idleFlag+1},wsp);
        sprintf('Characteristic wind speed: %s', tag)},'FontSize',12,'FontWeight','Bold','Interpreter','none')
    c1=colorbar;
    ylabel(c1,'\bf Stable                      Unstable','FontSize',12)
    set(c1,'YTick',[],'YTickLabel',' ')

    % yaw upwind limits
    [val_neg,idx_neg] = min(abs(yawerr-15));
    [val_pos,idx_pos] = min(abs(yawerr+15));

    hold on
    plot([idx_neg idx_neg],[azimarray(1) azimarray(end)],'k--')
    hold on
    plot([idx_pos idx_pos],[azimarray(1) azimarray(end)],'k--')
    legend('Yaw Upwind Limits','Location','NorthWest')

    print([outfolder '/' f_risk '/' turbname '_StabMap_' suffix{idleFlag+1} '_ZFAC.png'],'-dpng','-r200')
    end
end

