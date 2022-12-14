function [q] = plotRiskCurves(turbine,outfolder,turbname)
% Plot risk curves (Zfac) and return periods as function of wind speed.

% Default inputs
MS = 8; % MarkerSize
LW = 1.2; % LineWidth

gustDuration = 3; % [s] 
order = 2; % order of fitted curve (intersect)
risk_curves = LAC.scripts.StandstillStability.misc.allowableRiskLimits; % load allowable risk limits

% Intialize figure and storage
figure('Name', turbname)
q = struct('case', {}, 'zfac', {}, 'wsp', {}, 'wsp_gust', {});


%% Zfac plots
len = length(turbine.config);
for i=1:len
    pcount = 1;
    
    config = turbine.config(i);
    clear P % clear previous plots
    hold off
    
    % Load Zfac data
    load([outfolder '/' turbname '_' config.case '_ReturnPeriod.mat'])
    config =  turbine.config(i); % configurations
    
    subplot(len,1,i)    
    % Zfac   
    ZfacTab = sortrows([wsps',Zfac]);   
    P(pcount) = plot(ZfacTab(:,1),ZfacTab(:,2),'-o','LineWidth',LW,'DisplayName','ZFac');
    hold on
    
    if config.service_type ~= 2
        pcount = pcount+1;
        P(pcount) = plot(VTarget.ZFAC,ZfacTarget,'c+','LineWidth',LW,'MarkerSize',MS,'DisplayName','ZFac (TR=50yr)');
    end
    
    % Reference risk curves (simple mapper)
    if config.UYC
        risk_limits = risk_curves.uyc;
    else
        risk_limits = risk_curves.generic;
    end
    
    if config.service_type == 1
        lim = risk_limits(1);  
    elseif config.service_type == 2
        lim = risk_limits(2);
    elseif config.service_type == 3
        lim = risk_limits(3);
    else
        continue
    end
    
    pcount = pcount+1;
    P(pcount) = plot(lim.wsp,lim.zfac,'--k','DisplayName','Allowable Zfac');
    
    % Finding intersection (if any)
    line_function = polyfit(ZfacTab(:,1),ZfacTab(:,2),order); % Fit 1st order polinomial to Zfac curve
    zfac_at_ref_wsp = polyval(line_function, lim.wsp); % Evaluate zfac curve at refence wsps    
  
    difference = (zfac_at_ref_wsp-lim.zfac); % difference    
    small_add = linspace(0,1e-5,length(difference)); % add small contribution to avoid uniqueness
    if any(diff(sign(difference(difference~=0)))) % intercepting requirement
        pcount = pcount+1;
        x_int = interp1(difference+small_add, lim.wsp, 0); % wsp@intercept
        y_int = polyval(line_function,x_int); % Zfac@intercept   
        
        P(pcount) = plot(x_int,y_int,'r+','LineWidth',LW,'MarkerSize',MS,'DisplayName','Intersect');
    elseif all(sign(difference)<0) % below requirement
        x_int = [];y_int = [];
    else % outside of requirement
        x_int = 0;y_int = 0;        
    end
    legend(P,'Location','NorthWest')
    
    % Plot settings
    xlabel('\bfWind Speed [m/s]','FontSize',9)
    ylabel('\bfZ-Factor [%]','FontSize',9)
    title(['Risk Curve (Zfac) - ' config.case],'FontSize',10.5,'Interpreter','none')
    grid('minor')
        
    % Store allowable wind speeds
    q(i).case = config.case; 
    q(i).service_type = config.service_type;
    q(i).zfac = y_int; 
    q(i).wsp = floor(x_int); 
    
    % Gust wind speed (3s)
    q(i).wsp_gust = LAC.scripts.StandstillStability.misc.calcGustWsp(...
        gustDuration, x_int, config.TI);
end
print(gcf,[outfolder '/' turbname '_ZFAC_Plot.png'],'-dpng')
        
%% Writing outputs
fidZ = fopen([outfolder '/' turbname '_ALLOWABLE_SERVICE_WSPS.txt'], 'W');
fprintf(fidZ,'Scenario\tZFac\tWind Speed [m/s]\t Gust Wind Speed [m/s]\n');
for i=1:length(q)
    fprintf(fidZ,'%s\t%.2f\t%.1f\t%.1f\n', q(i).case, q(i).zfac, q(i).wsp, q(i).wsp_gust);
end
fclose(fidZ);

%% WFAC
% figure
% idleFlag=0;
% load(['.\ZFAC\',turbName,'_ReturnPeriod_',suffix{idleFlag+1},'.mat'])
% hold off
% WfacTab=sortrows([wsps',Wfac;VTarget.WFAC,WfacTarget]);
% P(1)=plot(WfacTab(:,1),WfacTab(:,2).*100,'b','LineWidth',LW);
% hold on
% plot(wsps,Wfac*100,'bx','LineWidth',LW,'MarkerSize',MS)
% P(2)=plot(VTarget.WFAC,WfacTarget*100,'c+','LineWidth',LW+1,'MarkerSize',MS+2);
% 
% idleFlag=1;
% load(['.\ZFAC\',turbName,'_ReturnPeriod_',suffix{idleFlag+1},'.mat'])
% WfacTab=sortrows([wsps',Wfac;VTarget.WFAC,WfacTarget]);
% P(3)=plot(WfacTab(:,1),WfacTab(:,2).*100,'r','LineWidth',LW);
% plot(wsps,Wfac*100,'rx','LineWidth',LW,'MarkerSize',MS)
% P(4)=plot(VTarget.WFAC,WfacTarget*100,'+','color',[1,0.5,0],'LineWidth',LW+1,'MarkerSize',MS+2);
% 
% legend(P,{'WFac Locked','WFac Locked (TR=50yr)','WFac Idle','WFac Idle (TR=50yr)'},'Location','NorthWest')
% 
% xlabel('\bfWind Speed [m/s]','FontSize',12)
% ylabel('\bfW-Factor [%]','FontSize',12)
% title(['W-Factor Calculation - ',turbName],'FontSize',14)
% print(gcf,['.\ZFAC\',turbName,'_WFAC_Plot.png'],'-dpng')

