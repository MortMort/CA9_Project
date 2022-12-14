function stabilityMap(config,outfolder,turbname)
% Plots stability maps (based on VTS Root Edgewise Bending Loads).

suffix={'Locked','Idle'};
idleFlag = config.idleflag;

%% Stability maps for rotor locked or idling service modes
if config.service_type == 1 || config.service_type == 3
    load([outfolder '/' turbname '_' config.case '_' 'ZFac.mat']);
    
    if length(yawerr)>1
        yaw_step = yawerr(2)-yawerr(1);
    else
        yaw_step = 30;
    end
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

    % N: azim, M: wdir, 
    for k=1:length(wsps)
        clims=[0 max(max(max(Loads)))];
        figure
        hold off
        H = imagesc(Loads(:,:,1,k),clims);
        set(gca,'Xtick',[1:yaw_binsize:yawN],'YTick',[1:azim_binsize:azimN])
        set(gca,'XtickLabel',yawerr(1:yaw_binsize:yawN),'YtickLabel',azimarray(1:azim_binsize:azimN))
        axis square
        xlabel('\bfYaw error [\circ]','FontSize',12)
        ylabel('\bfBlade azimuth [\circ]','FontSize',12)
        title(sprintf('%s Stability Map - Rotor %s - Vhub = %im/s',turbname,suffix{idleFlag+1},wsps(k)),'FontSize',12,'FontWeight','Bold','Interpreter','none')
        c1=colorbar;
        ylabel(c1,'\bf Blade Root Bending Load [kNm]','FontSize',12)
        print([outfolder '/' turbname '_StabMap_' suffix{idleFlag+1} num2str(wsps(k)) 'mps.png'],'-dpng','-r200')
    end
else
    return
end
end
    
