InputFile           = 'w:\ToolsDevelopment\vtsInputTrans\PIT\PIT_InputConfig.txt';
ExpectedOutputFile  = 'w:\ToolsDevelopment\vtsInputTrans\PIT\PIT_Vidar_V162.101';

OutputFiles          = LAC.vtsInputTrans.PIT(InputFile);

% Test PIT file
ExpectedObj = LAC.vts.convert(ExpectedOutputFile,'PIT');
ActualObj   = LAC.vts.convert(OutputFiles{1},'PIT');

FieldObjs = fieldnames(ExpectedObj);

for i = 1:length(FieldObjs)
    assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s',FieldObjs{i}) 
end
delete(OutputFiles{1});

% Test PL file
PLfileExpected      = {'w:\ToolsDevelopment\vtsInputTrans\PIT\_PL_Vidar_V162_IEC_LTq_pdot_GC_expected.101',...
    'w:\ToolsDevelopment\vtsInputTrans\PIT\_PL_Vidar_V162_IEC_HTq_pdot_GC_expected.101'};
for k = 1:length(OutputFiles{2})
ExpectedObj = LAC.vts.convert(PLfileExpected{k},'PL');
ActualObj   = LAC.vts.convert(OutputFiles{2}{k},'PL');

FieldObjs   = fieldnames(ExpectedObj);

for i = 1:length(FieldObjs)
    assert(isequaln(ExpectedObj.(FieldObjs{i}),ActualObj.(FieldObjs{i})),'Failed assertation of %s',FieldObjs{i}) 
end
delete(OutputFiles{2}{k});
end
copyfile('w:\ToolsDevelopment\vtsInputTrans\PIT\_PL_Vidar_V162_IEC_LTq_pdot_GC_org.101','w:\ToolsDevelopment\vtsInputTrans\PIT\_PL_Vidar_V162_IEC_LTq_pdot_GC.101')
copyfile('w:\ToolsDevelopment\vtsInputTrans\PIT\_PL_Vidar_V162_IEC_HTq_pdot_GC_org.101','w:\ToolsDevelopment\vtsInputTrans\PIT\_PL_Vidar_V162_IEC_HTq_pdot_GC.101')

% Delete
delete(OutputFiles{3})