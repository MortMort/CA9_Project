function [LS] = fMinMeanMaxAoA(LS,Outputs,Setup)
        obj      = LAC.vts.stapost(LS.Path);
        stafiles = LAC.dir(sprintf('%s\\sta\\%s*.sta',LS.Path,LS.LC));
        LS.dataSTA      = obj.readfiles(stafiles);
        
        
        
        %% Minimum, Mean and Maximum AoA at a given wind speed and given section
        
        for i_task = 1:size(Outputs.MinMeanMaxAoA,1)
            % Thickness ratio at given section
            tc = interp1(LS.mas.bld.Radius,LS.mas.bld.Thickness,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2);
            
            % Get profiles
            Polar.aoa = LS.pro_dat.alpha;
            Polar.cl = interp1(LS.pro_dat.Thickness,LS.pro_dat.cL',tc );
            Polar.cd = interp1(LS.pro_dat.Thickness,LS.pro_dat.cD',tc );
            Polar.cm = interp1(LS.pro_dat.Thickness,LS.pro_dat.cM',tc );
            
            % Read STA files
            if isfield(LS.dataSTA,'mean')
                WS = round(LS.dataSTA.mean(LS.idxVhub,:)/Setup.WSPrecision)*Setup.WSPrecision;
                idxSTA = WS == Outputs.MinMeanMaxAoA(i_task,1); % index of STA files which have the required WS
                
                if isempty(find(idxSTA, 1))
                    disp(['ERROR: no STA files in ',LS.Path,' with a wind speed of ',num2str(WS),'m/s']);
                    return;
                end
                
                data.MeanAllRadius = LS.dataSTA.mean(LS.idxAoA,idxSTA); 
                data.MeanAllRadiusAvg = mean(data.MeanAllRadius,2);
                data.MinAllRadius = LS.dataSTA.min(LS.idxAoA,idxSTA);
                data.MinAllRadiusAvg = mean(data.MinAllRadius,2);
                data.MaxAllRadius = LS.dataSTA.max(LS.idxAoA,idxSTA);
                data.MaxAllRadiusAvg = mean(data.MaxAllRadius,2);
                
                AoA.Mean    = interp1(LS.Radius',data.MeanAllRadiusAvg,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2); % Mean AoA at wished wind speed and radius
                AoA.Min     = interp1(LS.Radius,data.MinAllRadiusAvg,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2); % Mean AoA at wished wind speed and radius
                AoA.Max     = interp1(LS.Radius,data.MaxAllRadiusAvg,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2); % Mean AoA at wished wind speed and radius
                
                CL.Mean = interp1(Polar.aoa,Polar.cl,AoA.Mean);
                CL.Min = interp1(Polar.aoa,Polar.cl,AoA.Min);
                CL.Max = interp1(Polar.aoa,Polar.cl,AoA.Max);
                
                CD.Mean = interp1(Polar.aoa,Polar.cd,AoA.Mean);
                CD.Min = interp1(Polar.aoa,Polar.cd,AoA.Min);
                CD.Max = interp1(Polar.aoa,Polar.cd,AoA.Max);
                
                CM.Mean = interp1(Polar.aoa,Polar.cm,AoA.Mean);
                CM.Min = interp1(Polar.aoa,Polar.cm,AoA.Min);
                CM.Max = interp1(Polar.aoa,Polar.cm,AoA.Max);
                
                % Nve stall AoA
                AoANveStall = interp1(LS.mas.bld.Radius,LS.nveStall.AoA,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2);
                CLNveStall = interp1(LS.mas.bld.Radius,LS.nveStall.cl,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2);
                CDNveStall = interp1(LS.mas.bld.Radius,LS.nveStall.cd,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2);
                CMNveStall = interp1(LS.mas.bld.Radius,LS.nveStall.cm,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2);
                
                % Pve stall AoA
                AoAPveStall = interp1(LS.mas.bld.Radius,LS.pveStall.AoA,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2);
                CLPveStall = interp1(LS.mas.bld.Radius,LS.pveStall.cl,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2);
                CDPveStall = interp1(LS.mas.bld.Radius,LS.pveStall.cd,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2);
                CMPveStall = interp1(LS.mas.bld.Radius,LS.pveStall.cm,Outputs.MinMeanMaxAoA(i_task,2)*LS.Diameter/2);
                
                if Setup.Plot
                    figure('name',['DLC',LS.LC,', WS = ',num2str(Outputs.MinMeanMaxAoA(i_task,1)),'m/s, CL, Section = ',num2str(Outputs.MinMeanMaxAoA(i_task,2)*100),'% radius']);
                    hold on; grid on;
                    plot(Polar.aoa,Polar.cl,'k')
                    plot(AoA.Mean,CL.Mean,'or')
                    plot(AoA.Min,CL.Min,'<r')
                    plot(AoA.Max,CL.Max,'>r')
                    plot(AoANveStall,CLNveStall,'ob')
                    plot(AoAPveStall,CLPveStall,'ob')
                    ylabel(LS.Name)
                    legend('C_L','Mean AoA','Min AoA','Max AoA','Nve Stall AoA','Pve Stall AoA','location','best')
					path = [LS.OutPutFolder,'CL_WS_',num2str(Outputs.MinMeanMaxAoA(i_task,1)),'_Section=',num2str(Outputs.MinMeanMaxAoA(i_task,2)*100),'_DLC_',LS.LC];
% 					saveas(gcf,[path '.fig'])
					saveas(gcf,[path '.png'])
                    
                    figure('name',['DLC',LS.LC,', WS = ',num2str(Outputs.MinMeanMaxAoA(i_task,1)),'m/s, CD, Section = ',num2str(Outputs.MinMeanMaxAoA(i_task,2)*100),'% radius']);
                    hold on; grid on;
                    plot(Polar.aoa,Polar.cd,'k')
                    plot(AoA.Mean,CD.Mean,'or')
                    plot(AoA.Min,CD.Min,'<r')
                    plot(AoA.Max,CD.Max,'>r')
                    plot(AoANveStall,CDNveStall,'ob')
                    plot(AoAPveStall,CDPveStall,'ob')
                    legend('C_D','Mean AoA','Min AoA','Max AoA','Nve Stall AoA','Pve Stall AoA','location','best')
                    ylabel(LS.Name)
					path = [LS.OutPutFolder,'CD_WS_',num2str(Outputs.MinMeanMaxAoA(i_task,1)),'_Section=',num2str(Outputs.MinMeanMaxAoA(i_task,2)*100),'_DLC_',LS.LC];
% 					saveas(gcf,[path '.fig'])
					saveas(gcf,[path '.png'])
                    
                    figure('name',['DLC',LS.LC,', WS = ',num2str(Outputs.MinMeanMaxAoA(i_task,1)),'m/s, CM, Section = ',num2str(Outputs.MinMeanMaxAoA(i_task,2)*100),'% radius']);
                    hold on; grid on;
                    plot(Polar.aoa,Polar.cm,'k')
                    plot(AoA.Mean,CM.Mean,'or')
                    plot(AoA.Min,CM.Min,'<r')
                    plot(AoA.Max,CM.Max,'>r')
                    plot(AoANveStall,CMNveStall,'ob')
                    plot(AoAPveStall,CMPveStall,'ob')
                    legend('C_M','Mean AoA','Min AoA','Max AoA','Nve Stall AoA','Pve Stall AoA','location','best')
                    ylabel(LS.Name)
					path = [LS.OutPutFolder,'CM_WS_',num2str(Outputs.MinMeanMaxAoA(i_task,1)),'_Section=',num2str(Outputs.MinMeanMaxAoA(i_task,2)*100),'_DLC_',LS.LC];
% 					saveas(gcf,[path '.fig'])
					saveas(gcf,[path '.png'])
           
                if (Outputs.StallPoint)  
                    figure()
                    plot(LS.Radius./(LS.Diameter/2),LS.pveStall.AoA,'.-','linewidth',1.1); hold on;
                    plot(LS.Radius./(LS.Diameter/2),LS.nveStall.AoA,'.--','linewidth',1.1);
                    plot(LS.Radius./(LS.Diameter/2),data.MeanAllRadiusAvg,'.:')
                    plot(LS.Radius./(LS.Diameter/2),data.MinAllRadiusAvg,'.-.')
                    plot(LS.Radius./(LS.Diameter/2),data.MaxAllRadiusAvg,'.-.')
                    legend('Positive Stall','Negative Stall',['Mean AoA WS=' num2str(Outputs.MinMeanMaxAoA(i_task,1))]...
                         ,['Min AoA WS=' num2str(Outputs.MinMeanMaxAoA(i_task,1))],['Max AoA WS=' num2str(Outputs.MinMeanMaxAoA(i_task,1))]...
                         ,'location','southwest');
                    xlabel('r/R [-]');
                    ylabel('AoA [deg]');
                    xlim([0 1]);
                    ylim([-20 20])
                    grid on;

                    SaveFileNameFig=[LS.OutPutFolder,'\StallAoA_along_r_WS=',num2str(Outputs.MinMeanMaxAoA(i_task,1)),'.png'];
                    saveas(gcf,SaveFileNameFig)
                    close all;
                end
                clear WS idxSTA data AoA CL CD CM
                
            else
                disp(['ERROR: No STA files starting with ',LS.LC,' in ',LS.Path,'STA\']);
            end
           
        end
end