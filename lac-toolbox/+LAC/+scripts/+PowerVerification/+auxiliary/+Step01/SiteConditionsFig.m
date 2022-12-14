function SiteConditionsFig(data,sens,TI,MeanWindSpeed,turbine_TI_class, AirDensity, YawError, WindShear)
% Function to create a figure of the site conditions used for the VTS
% comparative simulations. 
% Modified by RUSJE 13/2-2018

        if max(data.dat1.mean(:,sens.WSP))< 20
            max_wind = 20;
        elseif max(data.dat1.mean(:,sens.WSP))< 22
            max_wind = 22;
        else
            max_wind = 25;
        end;                     % this above loop is just to fix the x-axis scale

figure(1);
set(figure(1),'Position',[0 0 1080 600]);
    subplot(2,2,1);
        plot(MeanWindSpeed,TI,'ob','MarkerSize',5);
        
        hold on;
%         plot(MeanWindSpeed,TI2,'xr','MarkerSize',5');
        WS = 2:1:max_wind;
        if turbine_TI_class == 1
            Iref = 0.16;
            WS_turb = Iref*(0.75*WS+5.6)./WS*100;   %--- as per IEC61400-1 NTM. model
            plot(WS,WS_turb,'-k','LineWidth',3);
            plot(WS,WS_turb*(2/3),'--r','LineWidth',2);
%             
%             plot([0 8],100*[data.dat1.turb_lim_low_wsp data.dat1.turb_lim_low_wsp],'--c','LineWidth',2)
             legend('Measurement','Design (A-turbulence)','A-turbulence/1.5','Location','NorthEast');
        elseif turbine_TI_class == 2
            Iref = 0.14;
            WS_turb = Iref*(0.75*WS+5.6)./WS*100;   %--- as per IEC61400-1 NTM model
            plot(WS,WS_turb,'-k','LineWidth',3);
            legend('Measurement','IEC-B','Location','NorthEast');
        elseif turbine_TI_class == 3
            Iref = 0.12;
            WS_turb = Iref*(0.75*WS+5.6)./WS*100;   %--- as per IEC61400-1 NTM model
            plot(WS,WS_turb,'-k','LineWidth',3);
            legend('Measurement','IEC-C','Location','NorthEast');
        end;
        grid on;
        xlabel('Wind speed [m/s]','FontSize',16);
        ylabel('Turbulence intensity [%]','FontSize',16);
        title('Site wind turbulence','FontSize',20);
        hold off;
        set(gca,'XTick',2:2:max_wind,'FontSize',12);
                clear WS WS_turb Iref turbine_TI_class;
                
    subplot(2,2,2);
        plot(MeanWindSpeed,AirDensity,'ob','MarkerSize',5);
        hold on;
        plot([0;max_wind],[1.225;1.225],'-k','LineWidth',3);
        legend('Measurement','Design standard','Location','NorthEast');
        grid on;
        xlabel('Wind speed [m/s]','FontSize',16);
        ylabel('Air density [kg/m^3]','FontSize',16);
        title('Site air density','FontSize',20);
        set(gca,'XTick',2:2:max_wind,'FontSize',12);
        hold off;
    subplot(2,2,3);
        plot(MeanWindSpeed,YawError,'ob','MarkerSize',5);
        hold on;
        plot([0;max_wind],[6;6],'-k','LineWidth',3);
        legend('Measurement','Design standard','Location','NorthEast');
        plot([0;max_wind],[-6;-6],'-k','LineWidth',3);
        grid on;
        xlabel('Wind speed [m/s]','FontSize',16);
        ylabel('Yaw error [deg]','FontSize',16);
        title('Site yaw error','FontSize',20);
        set(gca,'XTick',2:2:max_wind,'FontSize',12);
        axis([2 max_wind -15 15]);
        hold off;
    subplot(2,2,4);
        plot(MeanWindSpeed,WindShear,'ob','MarkerSize',5);
        hold on;
        plot([0;max_wind],[0.14; 0.14],'-k','LineWidth',3);
        legend('Measurement','Design standard','Location','NorthEast');
        grid on;
        xlabel('Wind speed [m/s]','FontSize',16);
        ylabel('Wind shear exponent [-]','FontSize',16);
        title('Site wind shear','FontSize',20);
        set(gca,'XTick',2:2:max_wind,'FontSize',12);
        hold off;
        
saveas(figure(1),[pwd '\Output_Figures\Fig_Step01_SiteConditions.fig']);
close;  