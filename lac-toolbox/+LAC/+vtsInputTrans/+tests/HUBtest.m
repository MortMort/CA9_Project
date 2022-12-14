InputFile = 'w:\ToolsDevelopment\vtsInputTrans\HUB\HUB_InputConfig.txt';
ExpectedOutputFile = 'w:\ToolsDevelopment\vtsInputTrans\HUB\HUB_Vidar_V162_expected.101';
OutputFile = LAC.vtsInputTrans.HUB(InputFile);

ExpectedObj = LAC.vts.convert(ExpectedOutputFile,'HUB');
ActualObj   = LAC.vts.convert(OutputFile,'HUB');

FieldObjs = fieldnames(ExpectedObj);

for i = 1:length(FieldObjs)
    assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s',FieldObjs{i}) 
end
delete(OutputFile)