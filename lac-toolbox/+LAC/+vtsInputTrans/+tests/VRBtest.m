InputFile = 'w:\ToolsDevelopment\vtsInputTrans\VRB\VRB_InputConfig.txt';
ExpectedOutputFile = 'w:\ToolsDevelopment\vtsInputTrans\VRB\VRB_Vidar_V162_6000kW_expected.102';
OutputFile = LAC.vtsInputTrans.VRB(InputFile);

ExpectedVRBdata = textscan(fileread(ExpectedOutputFile),'%s','delimiter','\n');
ActualVRBdata = textscan(fileread(OutputFile{1}),'%s','delimiter','\n');

for i = 1:length(ExpectedVRBdata{1})
    assert(isequaln(ExpectedVRBdata{1}{i},ActualVRBdata{1}{i}),'Failed assertation of VRB file') 
end
delete(OutputFile{1})