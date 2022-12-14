function HWCsensinHTC(simulationpath,txtfile,HTCsen_endtxt,sensforHAWC2)
%% This function inserts the required sensors in HTC file
        initialsensno=regexp(HTCsen_endtxt,'\d*','Match');
        htcFn = fullfile(simulationpath,'MASTER',strrep(txtfile,'.txt','.htc'));
        htc   = LAC.codec.CodecTXT(htcFn);
               
        %insert sensors
        [lines1, lineno1] = htc.search(HTCsen_endtxt);        
        for ii=1:length(sensforHAWC2{1})
            htc.jump(lineno1+ii);sensno=str2double(initialsensno)+ii;
            if ii<6
                htc.replaceLine(lineno1+ii,[' 	dll type2_dll SysWrap inpvec  ',num2str(sensno),'  # ',sensforHAWC2{1,2}{ii}(5:end),'  [-]  ;']);
            else
                htc.insertLine(strcat({' 	dll type2_dll SysWrap inpvec  '},{num2str(sensno)},{'  # '},sensforHAWC2{1,2}{ii}(5:end),'  [-]  ;'));
            end
        end
        htc.save(htcFn);
end