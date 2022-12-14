%% Test for LAC.vsc.VSCclimateSplit
% NIWJO 2021

% Make splitted files
SegmentData = 'w:\ToolsDevelopment\VSC\SupportFiles\DataDE.txt';
pathout = LAC.vsc.VSCclimateSplit(SegmentData,2);

% Test splitted files
ExpectedOutput = 'W:\ToolsDevelopment\VSC\SupportFiles\DataDE_1_Expected.txt';

Expected = LAC.vsc.import_VSC_Climate_file(ExpectedOutput);
actual  = LAC.vsc.import_VSC_Climate_file(pathout{1});
fieldNames = fields(Expected);
for i = 1:length(fieldNames)
    assert(isequaln(actual.(fieldNames{i}),Expected.(fieldNames{i})),'Failed assertation of %s',fieldNames{i})
end

for i = 1:length(pathout)
    delete(pathout{i})
end