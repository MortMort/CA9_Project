function [LS] = fTimeInStall(LS,Outputs,Setup)
% Read in frequency file
[frq] = LAC.vts.convert([LS.Path,'INPUTS\',LS.frqfile],'FRQ');

for i_task = 1:length(Outputs.TimeInStall)
    FilesNamesStart = cellfun(@(x) x(1:length(LS.LC)),frq.LC,'UniformOutput',0);
    idx_INT = find(frq.V == round(Outputs.TimeInStall(i_task)/Setup.WSPrecision)*Setup.WSPrecision & strcmpi(FilesNamesStart,LS.LC));
    if isempty(idx_INT)
        disp(['WARNING: there are no simulations at WS=',num2str(round(Outputs.TimeInStall(i_task)/Setup.WSPrecision)*Setup.WSPrecision),'m/s, starting with ', LS.LC, ' in folder ',LS.Path,'. Plots can''t be generated']);
    else
        for i_INT = 1:length(idx_INT)
            [~,t,dat,~] = LAC.timetrace.int.readint([LS.Path, 'INT\', frq.LC{idx_INT(i_INT)}],1,[],[],[]);
            TS.aoa(i_INT,:,:) = dat(:,LS.idxAoA);
            for i_Section = 1:length(LS.Radius)
                TS.RatioNveStall(i_INT,i_Section) = sum(TS.aoa(i_INT,:,i_Section)<LS.nveStall.AoA(i_Section))/length(TS.aoa(i_INT,:,i_Section));
                TS.RatioPveStall(i_INT,i_Section) = sum(TS.aoa(i_INT,:,i_Section)>LS.pveStall.AoA(i_Section))/length(TS.aoa(i_INT,:,i_Section));
            end
            clear t dat
        end
        LS.RatioNveStallAvg(i_task,:) = mean(TS.RatioNveStall,1);
        LS.RatioPveStallAvg(i_task,:) = mean(TS.RatioPveStall,1);
        
                
        % Writes outputs
        if ~isempty(LS.OutPutFolder)
            DataSave = [LS.Radius'/LS.Diameter*2 (LS.RatioPveStallAvg(i_task,:))' (LS.RatioNveStallAvg(i_task,:))'];
            SaveFileName = [LS.OutPutFolder,'\TimeInStall_WS_',num2str(round(Outputs.TimeInStall(i_task)/Setup.WSPrecision)*Setup.WSPrecision),'_DLC_',LS.LC,'.txt'];
%             saveflag = 0;
%             if exist(SaveFileName,'file')
%                 choice = questdlg([SaveFileName,' already exists. Do you want to overwrite it?'],'File already exists','yes','no','yes');
%                 switch choice
%                     case 'yes'
%                         saveflag = 1;
%                     case 'no'
%                         saveflag = 0;
%                 end
%             else
%                 saveflag = 1;
%             end
%             if saveflag
                save(SaveFileName,'DataSave', '-ascii');
%             end
            clear DataSave SaveFileName
        end
    end
    clear TS RatioNveStallAvg RatioPveStallAvg
end

if Setup.Plot
    
    figure('name',['DLC',LS.LC,' - Negative Stall'])
    hold on;
    plot(LS.StallLim_r,LS.NegStallLim,'--');
    ylim([0 0.5]);
    xlabel('Normalised radius [-]')
    ylabel('Ratio of time in negative stall [-]')
    legendInfoNeg{1}='Limit';
    n=2;
    for i=1:length(Outputs.TimeInStall)
%             if (round(Outputs.TimeInStall(i)/Setup.WSPrecision)*Setup.WSPrecision > 13)
                plot(LS.Radius/LS.Diameter*2,LS.RatioNveStallAvg(i,:));
                legendInfoNeg{n} = [num2str(Outputs.TimeInStall(i)) 'm/s']; 
                n=n+1;
%             end
    end
    legend(legendInfoNeg)
            
    SaveFileNameFigNegStall = [LS.OutPutFolder,'\TimeInStall_DLC_',LS.LC,'_NegStall.jpg'];
    SaveFileNameFigNegStall_fig = [LS.OutPutFolder,'\TimeInStall_DLC_',LS.LC,'_NegStall.fig'];
    saveas(gcf,SaveFileNameFigNegStall)
    saveas(gcf,SaveFileNameFigNegStall_fig)
            
    figure('name',['DLC',LS.LC,' - Positive Stall'])
    hold on
    plot(LS.StallLim_r,LS.PosStallLim,'--');
    ylim([0 0.5])
    xlabel('Normalised radius [-]')
    ylabel('Ratio of time in positive stall [-]')
    legendInfoPos{1}='Limit';
    n=2;
    for i=1:length(Outputs.TimeInStall)
%             if (round(Outputs.TimeInStall(i)/Setup.WSPrecision)*Setup.WSPrecision < 13)
                plot(LS.Radius/LS.Diameter*2,LS.RatioPveStallAvg(i,:));
                legendInfoPos{n} = [num2str(Outputs.TimeInStall(i)) 'm/s'];
                n=n+1;
%             end
    end
    legend(legendInfoPos)
    
    SaveFileNameFigPosStall = [LS.OutPutFolder,'\TimeInStall_DLC_',LS.LC,'_PosStall.png'];
    SaveFileNameFigPosStall_fig = [LS.OutPutFolder,'\TimeInStall_DLC_',LS.LC,'_PosStall.fig'];
    saveas(gcf,SaveFileNameFigPosStall)
    saveas(gcf,SaveFileNameFigPosStall_fig)
end
    
end
