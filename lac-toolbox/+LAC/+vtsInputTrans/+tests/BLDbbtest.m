InputFile = 'w:\ToolsDevelopment\vtsInputTrans\BLDbb\BLDbb_InputConfig.txt';
ExpectedOutputFile = {'w:\ToolsDevelopment\vtsInputTrans\BLDbb\BLD_Vidar_V162_STD_STE.108'
    'w:\ToolsDevelopment\vtsInputTrans\BLDbb\BLD_Vidar_V162_STD_STE_extended_output.108'
    };
OutputFile = LAC.vtsInputTrans.BLDbb(InputFile);

% Test of Blade bearing update of bb
for k = 1:length(OutputFile)-1
    ExpectedObj = LAC.vts.convert(ExpectedOutputFile{k},'BLD');
    ActualObj   = LAC.vts.convert(OutputFile{k},'BLD');
    
    FieldObjs = fieldnames(ExpectedObj);
    
    for i = 1:length(FieldObjs)
        assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s.',FieldObjs{i})
    end
    delete(OutputFile{k})
end

% Test if Blade Fix file can be written
delete(OutputFile{end})
copyfile('w:\ToolsDevelopment\vtsInputTrans\BLDbb\mk0a_EV162_org.tpl','w:\ToolsDevelopment\vtsInputTrans\BLDbb\mk0a_EV162.tpl');