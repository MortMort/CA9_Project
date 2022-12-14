function VTSTempRun(rootfol,txtfile)
%% This function reads the required HAWC sensor from input sensor text file
% Inputs: 
% - rootfolder 
% - Vts text file
mkdir('_VTS')
copyfile(txtfile, '_VTS')
if exist('_CtrlParamChanges.txt', 'file')==2
    copyfile('_CtrlParamChanges.txt', '_VTS')
end

sysCommandLine = ['FAT1_ms_beta -c -R 0100 -loads -p ', fullfile([rootfol '_VTS'],txtfile)];

[prepStatus prepResults] = system(sysCommandLine);
pause(5);

% fix for FAT1 
prompt={'Input: Yes/No and press OK'};title='VTS prep completed and Fat1 closed?'; definput={'No'};
userinput=inputdlg(prompt,title,[1 70],definput);

    if length(strfind(userinput,'No')) %contains(char(userinput),'No')
        pause(30);
    else
        %do nothing just continue
    end
end