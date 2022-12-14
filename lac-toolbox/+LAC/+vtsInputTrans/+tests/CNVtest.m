InputFile = 'w:\ToolsDevelopment\vtsInputTrans\CNV\CNV_InputConfig.txt';
ExpectedOutputFile = 'w:\ToolsDevelopment\vtsInputTrans\CNV\CNV_Vidar_V162_HTq_6000kW_expected.100';
OutputFile = LAC.vtsInputTrans.CNV(InputFile);

ExpectedObj = LAC.vts.convert(ExpectedOutputFile,'CNV');
ActualObj   = LAC.vts.convert(OutputFile{1},'CNV');

FieldObjs = fieldnames(ExpectedObj);

for i = 1:length(FieldObjs)
    assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s',FieldObjs{i}) 
end
delete(OutputFile{1})