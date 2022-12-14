%% Test for LAC.vsc.populateSegmentData
% NIWJO 2021
clear

expected = load('w:\ToolsDevelopment\VSC\SupportFiles\SegmentDataTest.mat','SegmentData');

SegmentData = {
    'DE' ,{'w:\ToolsDevelopment\VSC\SupportFiles\LoadsDE.txt'};
    'SE',{'w:\ToolsDevelopment\VSC\SupportFiles\LoadsSE.txt'};
    };
result.SegmentData = LAC.vsc.populateSegmentData(SegmentData);

% Test 1: 
assert(isequaln(result.SegmentData,expected.SegmentData),'Failed assertation of %s','SegmentData')