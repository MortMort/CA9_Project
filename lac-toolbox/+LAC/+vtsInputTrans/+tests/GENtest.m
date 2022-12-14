InputFile           = 'w:\ToolsDevelopment\vtsInputTrans\GEN\GEN_InputConfig.txt';
ExpectedOutputFile  = 'w:\ToolsDevelopment\vtsInputTrans\GEN\GEN_Vidar_V162_HTq_6000kW_expected.104';
OutputFile          = LAC.vtsInputTrans.GEN(InputFile);

ExpectedObj = LAC.vts.convert(ExpectedOutputFile,'GEN');
ActualObj   = LAC.vts.convert(OutputFile,'GEN');

FieldObjs = fieldnames(ExpectedObj);

for i = 1:length(FieldObjs)
    assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s',FieldObjs{i}) 
end
delete(OutputFile)