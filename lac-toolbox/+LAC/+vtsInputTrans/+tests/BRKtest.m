InputFile = 'w:\ToolsDevelopment\vtsInputTrans\BRK\BRK_InputConfig.txt';
ExpectedOutputFile = 'w:\ToolsDevelopment\vtsInputTrans\BRK\BRK_Vidar_expected.100';
OutputFile = LAC.vtsInputTrans.BRK(InputFile);

ExpectedObj = LAC.vts.convert(ExpectedOutputFile,'BRK');
ActualObj   = LAC.vts.convert(OutputFile,'BRK');

FieldObjs = fieldnames(ExpectedObj);

for i = 1:length(FieldObjs)
    assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s',FieldObjs{i}) 
end
delete(OutputFile)