InputFile = 'w:\ToolsDevelopment\vtsInputTrans\NAC\NAC_InputConfig.txt';
ExpectedOutputFile = 'w:\ToolsDevelopment\vtsInputTrans\NAC\NAC_Vidar_V162_HTq_expected.102';
OutputFile = LAC.vtsInputTrans.NAC(InputFile);

ExpectedObj = LAC.vts.convert(ExpectedOutputFile,'NAC');
ActualObj   = LAC.vts.convert(OutputFile,'NAC');

FieldObjs = fieldnames(ExpectedObj);

for i = 1:length(FieldObjs)
    assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s',FieldObjs{i}) 
end
delete(OutputFile)