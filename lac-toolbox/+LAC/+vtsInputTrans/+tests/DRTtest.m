InputFile = 'w:\ToolsDevelopment\vtsInputTrans\DRT\DRT_InputConfig.txt';
ExpectedOutputFile = 'w:\ToolsDevelopment\vtsInputTrans\DRT\DRT_Vidar_V162_HTq_expected.103';
OutputFile = LAC.vtsInputTrans.DRT(InputFile);

ExpectedObj = LAC.vts.convert(ExpectedOutputFile,'DRT');
ActualObj   = LAC.vts.convert(OutputFile,'DRT');

FieldObjs = fieldnames(ExpectedObj);

for i = 1:length(FieldObjs)
    assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s',FieldObjs{i}) 
end
delete(OutputFile)