%% Test for VCSclimate2VTS
% NIWJO 2021
clear 
outputfolder = 'w:\ToolsDevelopment\VSC\SupportFiles\';
VSCsetupfile = 'w:\ToolsDevelopment\VSC\SupportFiles\VSC_SetupInfo.txt';
climateFile = 'w:\ToolsDevelopment\VSC\SupportFiles\DataDE.txt';

Expected.WndObj = LAC.vts.convert('w:\ToolsDevelopment\VSC\SupportFiles\WND_Expected_DataDE_m=3.3_index=10.001','WND');
m = 3.3; index = 10;
climateFileName = 'DataDE';

% Test 1: 
outputname = LAC.vsc.VCSclimate2VTS(VSCsetupfile,climateFile,index,m,'OutputName',fullfile(outputfolder,['WND_' climateFileName '_m=' num2str(m) '_index=' num2str(index) '.001']));
actual.WndObj = LAC.vts.convert(outputname,'WND');
fieldNames = fields(Expected.WndObj);
for i = 1:length(fieldNames)
    assert(isequaln(actual.WndObj.(fieldNames{i}),Expected.WndObj.(fieldNames{i})),'Failed assertation of %s',fieldNames{i})
end
delete(outputname);