InputFile           = 'w:\ToolsDevelopment\vtsInputTrans\YAW\YAW_InputConfig.txt';
ExpectedOutputFile  = 'w:\ToolsDevelopment\vtsInputTrans\YAW\YAW_Vidar_V162_expected.101';
OutputFile          = LAC.vtsInputTrans.YAW(InputFile);

ExpectedObj = LAC.vts.convert(ExpectedOutputFile,'YAW');
ActualObj   = LAC.vts.convert(OutputFile,'YAW');

FieldObjs = fieldnames(ExpectedObj);

for i = 1:length(FieldObjs)
    assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s',FieldObjs{i}) 
end
delete(OutputFile)